#!/usr/bin/env python3
"""Validate the requested profile, compilation provenance and generated images."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[2]

def config(path):
    return dict(line.split('=', 1) for line in path.read_text().splitlines()
                if line.startswith('CONFIG_') and '=' in line)

original = config(root / 'tmp/config.original')
actual = config(root / '.config')
for key in ('CONFIG_TARGET_BOARD', 'CONFIG_TARGET_SUBTARGET', 'CONFIG_TARGET_PROFILE',
            'CONFIG_TARGET_ROOTFS_PARTSIZE', 'CONFIG_TARGET_OPTIMIZATION'):
    assert actual.get(key) == original.get(key), f'Configuration changed: {key}'
missing = [key for key, value in original.items() if key.startswith('CONFIG_PACKAGE_')
           and value in ('y', 'm') and actual.get(key) != value]
assert not missing, f'Selected packages changed: {missing}'
assert actual.get('CONFIG_USE_LLVM_TOOLCHAIN') == 'y'

kernels = list(root.glob('build_dir/target-*/linux-mediatek_filogic/linux-*/.config'))
assert len(kernels) == 1, f'Expected one kernel configuration: {kernels}'
kernel = config(kernels[0])
identity = kernel.get('CONFIG_CC_VERSION_TEXT', '')
assert 'clang version 23.1.2' in identity, identity
assert kernel.get('CONFIG_CC_IS_CLANG') == 'y'
assert kernel.get('CONFIG_LD_IS_LLD') == 'y'

llvm_bin = Path(os.environ.get('LLVM_BINDIR', '/usr/lib/llvm-23/bin'))
rootfs = list(root.glob('build_dir/target-*/root-mediatek'))
assert len(rootfs) == 1
elf_count = 0
needed = set()
for path in rootfs[0].rglob('*'):
    if path.is_symlink() or not path.is_file():
        continue
    with path.open('rb') as stream:
        magic = stream.read(4)
    if magic != b'\x7fELF':
        continue
    elf_count += 1
    dynamic = subprocess.check_output([str(llvm_bin / 'llvm-readelf'), '-d', str(path)], text=True)
    libs = re.findall(r'\(NEEDED\).*?\[(.*?)\]', dynamic)
    assert not any(lib.startswith(('libgcc', 'libstdc++')) for lib in libs), str(path)
    needed.update(libs)
assert elf_count > 0
available = {path.name for path in rootfs[0].rglob("*") if path.is_file() or path.is_symlink()}
assert not needed - available, f"Missing rootfs libraries: {sorted(needed - available)}"

executions = root / 'logs/llvm-execve.log'
assert executions.is_file(), 'Missing execve audit'
executables = set(re.findall(r'execve\("([^"\n]+)"', executions.read_text(errors='replace')))
for executable in executables:
    assert not re.search(r'/(?:gcc-[0-9]+|g\+\+-[0-9]+|cc1|cc1plus|collect2)$', executable), executable
    name = Path(executable).name
    assert not (Path(executable).parent in (Path('/usr/bin'), Path('/bin')) and
                (name in ('cc', 'c++') or re.search(r'(^|-)(gcc|g\+\+)(-\d+)?$', name))), executable
log_lines = (root / 'logs/llvm-commands.log').read_text().splitlines()
# Some TF-A flags contain literal newlines. Only prefixed lines begin records;
# their blank/flag continuation lines are arguments, not compiler invocations.
assert all(line.startswith(('host\t', 'target\t', '-')) or not line.strip()
           for line in log_lines), 'Unexpected compiler log record'
commands = [line for line in log_lines if line.startswith(('host\t', 'target\t'))]
assert commands and all('/llvm-23/bin/clang' in line for line in commands)
assert any(line.startswith('target\t') for line in commands)

images = root / 'bin/targets/mediatek/filogic'
assert (images / 'profiles.json').is_file()
metadata = json.loads((images / 'profiles.json').read_text())
profile = actual['CONFIG_TARGET_PROFILE'].strip('"').removeprefix('DEVICE_')
assert set(metadata['profiles']) == {profile}, 'Unexpected image profiles'
image_records = metadata['profiles'][profile]['images']
assert any(record['type'] == 'sysupgrade' for record in image_records)
assert any(record['filesystem'] == 'initramfs' for record in image_records)
for record in image_records:
    path = images / record['name']
    assert path.stat().st_size == record['size'], path.name
    assert hashlib.sha256(path.read_bytes()).hexdigest() == record['sha256'], path.name
subprocess.run(['sha256sum', '-c', 'sha256sums'], cwd=images, check=True)
report = {'profile': profile, 'llvm': '23.1.2',
          'kernel_compiler': identity.strip('"'),
          'images': image_records,
          'prebuilt_vendor_components_retained': True,
          'compilation_scope': 'Sources compiled during this build; excludes upstream vendor blobs', 'preserved_package_selection_symbols': sum(key.startswith('CONFIG_PACKAGE_')
          and value in ('y', 'm') for key, value in original.items()),
          'rootfs_elf_count': elf_count, 'needed_libraries': sorted(needed),
          'compiler_invocations': len(commands), 'gcc_execution_detected': False,
          'hardware_boot_tested': False}
(root / 'logs/llvm-validation.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
