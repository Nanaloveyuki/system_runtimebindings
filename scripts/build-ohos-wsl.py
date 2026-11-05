#!/usr/bin/env python3
"""Build the HiLog demo with published MoonOHOS and a Windows DevEco SDK from WSL."""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


COMPILER_BRIDGE = '''#!{python}
import os, sys
from pathlib import Path
args = sys.argv[1:]
metadata = Path('_build/native/debug/check/all_pkgs.json')
# MoonOHOS 0.6.0 strips this metadata; current MoonBit needs it for implicit imports.
if args and args[0] == 'build-package' and '-all-pkgs' not in args:
    if metadata.is_file():
        args += ['-all-pkgs', str(metadata.resolve())]
os.execv({compiler!r}, [{compiler!r}, *args])
'''

WINDOWS_COMPILER = '''#!{python}
import os, subprocess, sys

def windows_path(value):
    if value.startswith('/') and (os.path.exists(value) or os.path.exists(os.path.dirname(value))):
        return subprocess.check_output(['wslpath', '-w', value], text=True).strip()
    return value

args = []
for arg in sys.argv[1:]:
    if '=' in arg and arg.split('=', 1)[1].startswith('/'):
        key, value = arg.split('=', 1)
        arg = key + '=' + windows_path(value)
    elif arg.startswith(('-I/', '-L/')):
        arg = arg[:2] + windows_path(arg[2:])
    else:
        arg = windows_path(arg)
    args.append(arg)
sys.exit(subprocess.run([{compiler!r}, *args]).returncode)
'''


def run(args, **kwargs):
    print('+', ' '.join(str(arg) for arg in args[:3]), flush=True)
    subprocess.run([str(arg) for arg in args], check=True, **kwargs)


def executable(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    path.chmod(0o755)


def windows_path(path):
    return subprocess.check_output(['wslpath', '-w', str(path)], text=True).strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--deveco', type=Path, required=True, help='Windows DevEco directory mounted in WSL')
    parser.add_argument('--windows-temp', type=Path, required=True, help='Existing Windows-mounted directory for temporary Hvigor builds')
    parser.add_argument('--powershell', type=Path, required=True, help='PowerShell 7 pwsh.exe')
    args = parser.parse_args()
    repo = Path(__file__).resolve().parent.parent
    example = repo / 'examples/ohos'
    deveco = args.deveco.resolve(strict=True)
    native = deveco / 'sdk/default/openharmony/native'
    compiler = shutil.which('moonc')
    if compiler is None:
        parser.error('moonc must be on PATH')
    for relative in ['llvm/bin/clang.exe', 'llvm/bin/clang++.exe', 'build-tools/cmake/bin/cmake.exe', 'build-tools/cmake/bin/ninja.exe']:
        if not (native / relative).is_file():
            parser.error(f'Missing SDK tool: {native / relative}')
    # The SDK overlay is disposable; the installed SDK and upstream CLI stay untouched.
    (example / '_build').mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='host-', dir=example / '_build') as scratch, tempfile.TemporaryDirectory(prefix='runtimebinding-hos-', dir=args.windows_temp) as staging:
        scratch = Path(scratch)
        sdk = scratch / 'native'
        sdk.mkdir()
        for name in ['build', 'sysroot', 'NOTICE.txt', 'oh-uni-package.json']:
            (sdk / name).symlink_to(native / name, target_is_directory=(native / name).is_dir())
        for name in ['include', 'lib']:
            (sdk / 'llvm').mkdir(exist_ok=True)
            (sdk / 'llvm' / name).symlink_to(native / 'llvm' / name, target_is_directory=True)
        for name in ['clang', 'clang++']:
            executable(sdk / 'llvm/bin' / name, WINDOWS_COMPILER.format(python=sys.executable, compiler=str(native / 'llvm/bin' / (name + '.exe'))))
        for name in ['cmake', 'ninja']:
            tool = shutil.which(name)
            if tool is None:
                parser.error(f'Linux {name} must be on PATH')
            destination = sdk / 'build-tools/cmake/bin' / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.symlink_to(tool)
        # readelf consumes ELF bytes without host-path translation, through its Windows binary.
        executable(sdk / 'llvm/bin/llvm-readelf', WINDOWS_COMPILER.format(python=sys.executable, compiler=str(native / 'llvm/bin/llvm-readelf.exe')))
        for name in ['llvm-ar', 'llvm-ranlib']:
            executable(sdk / 'llvm/bin' / name, WINDOWS_COMPILER.format(python=sys.executable, compiler=str(native / 'llvm/bin' / (name + '.exe'))))
        executable(scratch / 'bin/moonc', COMPILER_BRIDGE.format(python=sys.executable, compiler=compiler))
        env = os.environ.copy()
        env['PATH'] = str(scratch / 'bin') + os.pathsep + env['PATH']
        dist = scratch / 'dist'
        # Doctor otherwise inspects unrelated async metadata in the invocation directory.
        run(['moonohos', 'build', '--config', example / 'moonohos.json', '--sdk', sdk, '--abi', 'x86_64', '--out', dist, '--json'], cwd=scratch, env=env)
        run(['moonohos', 'har', '--dist', dist, '--module', example / 'harmony/runtimebinding', '--json'], cwd=scratch)
        harmony = Path(staging) / 'harmony'
        shutil.copytree(example / 'harmony', harmony, ignore=shutil.ignore_patterns('build', 'oh_modules', '.hvigor', 'oh-package-lock.json5'))
        def quote(value):
            return "'" + str(value).replace("'", "''") + "'"
        studio = windows_path(deveco)
        node = studio + '\\tools\\node\\node.exe'
        script = '\n'.join([
            '[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()',
            "$ErrorActionPreference = 'Stop'",
            '$env:DEVECO_SDK_HOME = ' + quote(studio + '\\sdk'),
            '$env:JAVA_HOME = ' + quote(studio + '\\jbr'),
            '$env:Path = ' + quote(studio + '\\tools\\node') + " + ';' + $env:JAVA_HOME + '\\bin;' + $env:Path",
            'Set-Location ' + quote(windows_path(harmony)),
            '& ' + quote(node) + ' ' + quote(studio + '\\tools\\ohpm\\bin\\pm-cli.js') + ' install --all --no-link',
            'if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }',
            '& ' + quote(node) + ' ' + quote(studio + '\\tools\\hvigor\\bin\\hvigorw.js') + ' --no-daemon --mode module -p product=default -p buildMode=release assembleHar',
            'if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }',
            '& ' + quote(node) + ' ' + quote(studio + '\\tools\\hvigor\\bin\\hvigorw.js') + ' --no-daemon --mode module -p product=default -p buildMode=debug assembleHap',
            'exit $LASTEXITCODE',
        ])
        run([args.powershell, '-NoProfile', '-Command', script], cwd=args.windows_temp)
        output = example / '_build/artifacts'
        output.mkdir(parents=True, exist_ok=True)
        for source in [harmony / 'entry/build/default/outputs/default/entry-default-unsigned.hap', harmony / 'runtimebinding/build/default/outputs/default/runtimebinding.har']:
            shutil.copy2(source, output / source.name)
            print('Artifact:', output / source.name)
        run(['moonohos', 'verify', '--out', dist, '--json'], cwd=scratch)


if __name__ == '__main__':
    main()
