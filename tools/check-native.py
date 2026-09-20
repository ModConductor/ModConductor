#!/usr/bin/env python3
"""Run one existing native fixture scope or its focused NUnit selection."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import time

SCOPES = (
    'all', 'storage', 'selection', 'organization', 'planner', 'game-contexts',
    'steam-discovery', 'proton-contexts', 'file-plans', 'deployment-recovery',
    'generations', 'deployment-backend', 'components', 'skse', 'enb', 'fnis', 'generated-outputs', 'executables', 'game-launch', 'profile-data', 'artifacts', 'downloads', 'archive-inspection', 'archive-installation', 'mod-maintenance', 'fomod', 'bain', 'bundles', 'credentials', 'migration',
)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--scope', choices=SCOPES, required=True)
    parser.add_argument('--output', type=Path, required=True, help='New result directory; never overwritten.')
    parser.add_argument('--fixture', type=Path, help='Existing native binary; defaults to MC_NATIVE_FIXTURE.')
    parser.add_argument('--publish', action='store_true', help='Locked restore and ordinary NativeAOT publish into the result directory.')
    parser.add_argument('--test-filter', help='Run this existing NUnit filter instead of invoking the fixture directly.')
    parser.add_argument('--build-tests', action='store_true', help='Restore/build the managed NUnit runner before --test-filter.')
    args = parser.parse_args()
    if args.build_tests and not args.test_filter:
        parser.error('--build-tests requires --test-filter')
    if args.publish and args.fixture:
        parser.error('Choose --publish or --fixture, not both')
    system = {'linux': 'linux-x64', 'win32': 'win-x64'}.get(sys.platform)
    if system is None or platform.machine().lower() not in ('amd64', 'x86_64'):
        parser.error('Native qualification supports Linux x64 and Windows x64.')
    root = Path(__file__).resolve().parents[1]
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    receipt = {'scope': args.scope, 'platform': system, 'commands': []}
    started = time.monotonic()

    def execute(name, command, env=None):
        before = time.monotonic()
        with (output / f'{name}.stdout.log').open('wb') as stdout, (output / f'{name}.stderr.log').open('wb') as stderr:
            result = subprocess.run(command, cwd=root, env=env, stdout=stdout, stderr=stderr)
        receipt['commands'].append({'command': command, 'cwd': str(root), 'exitCode': result.returncode, 'elapsedSeconds': round(time.monotonic() - before, 3)})
        if result.returncode:
            raise subprocess.CalledProcessError(result.returncode, command)

    code = 1
    try:
        if args.publish:
            project = 'tests/ModConductor.Native.Fixtures'
            execute('restore', ['dotnet', 'restore', project, '--locked-mode'])
            execute('publish', ['dotnet', 'publish', project, '-c', 'Release', '-r', system, '--no-restore', '-o', str(output / 'published')])
            fixture = output / 'published' / ('ModConductor.Native.Fixtures.exe' if os.name == 'nt' else 'ModConductor.Native.Fixtures')
        else:
            selected = args.fixture or os.environ.get('MC_NATIVE_FIXTURE')
            if not selected:
                raise ValueError('Set --fixture or MC_NATIVE_FIXTURE, or use --publish.')
            fixture = Path(selected).resolve()
        with fixture.open('rb') as stream:
            receipt['fixture'] = {'path': str(fixture), 'sha256': hashlib.file_digest(stream, 'sha256').hexdigest()}
        if args.test_filter:
            tests = 'tests/ModConductor.Native.Tests'
            if args.build_tests:
                execute('test-restore', ['dotnet', 'restore', tests, '--locked-mode'])
                execute('test-build', ['dotnet', 'build', tests, '-c', 'Release', '--no-restore'])
            env = dict(os.environ, MC_NATIVE_FIXTURE=str(fixture), MC_NATIVE_SCOPE='' if args.scope == 'all' else args.scope, MC_NATIVE_REPORT=str(output / 'observation.json'))
            execute('test', ['dotnet', 'test', tests, '-c', 'Release', '--no-build', '--no-restore', '--filter', args.test_filter], env)
        else:
            command = [str(fixture), *([] if args.scope == 'all' else ['--' + args.scope]), str(output / 'fixture-data')]
            execute('fixture', command)
            # The fixture owns its assertions. Preserve its report without interpreting arbitrary fields.
            (output / 'observation.json').write_bytes((output / 'fixture.stdout.log').read_bytes())
        code = 0
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        receipt['error'] = str(error)
        print(error, file=sys.stderr)
    finally:
        receipt['exitCode'] = code
        receipt['elapsedSeconds'] = round(time.monotonic() - started, 3)
        (output / 'result.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
    print(output / 'result.json')
    return code


if __name__ == '__main__':
    sys.exit(main())
