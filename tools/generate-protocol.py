#!/usr/bin/env python3
"""Generate both language boundaries from the schema; --check leaves source untouched."""
import argparse
import os
import sys
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
platform = {'win32': 'windows_x64', 'linux': 'linux_x64'}.get(sys.platform)
if platform is None:
    raise SystemExit('Protocol generation supports native Windows x64 and Linux x64.')
suffix = '.exe' if os.name == 'nt' else ''
versions = ET.parse(root / 'Directory.Packages.props')
version = next(p.attrib['Version'] for p in versions.iter('PackageVersion') if p.attrib['Include'] == 'Grpc.Tools')
cache = Path(os.environ.get('NUGET_PACKAGES', Path.home() / '.nuget/packages'))
binaries = cache / 'grpc.tools' / version / 'tools' / platform
protoc = binaries / ('protoc' + suffix)
config = root / 'ui/.dart_tool/package_config.json'
dart = root / '.tools/flutter/bin/cache/dart-sdk/bin' / ('dart' + suffix)
cs_target = root / 'src/ModConductor.Protocol/Generated'
dart_target = root / 'ui/packages/mc_client/lib/src/generated'
scratch = root / '.agent-workspace'
scratch.mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix='protocol-', dir=scratch) as temporary:
    temporary = Path(temporary)
    plugin = temporary / ('protoc-gen-dart' + suffix)
    entry = temporary / 'generator.dart'
    entry.write_text("import 'dart:io';\nimport 'package:protoc_plugin/protoc.dart';\nvoid main() => CodeGenerator(stdin, stdout).generate();\n")
    subprocess.run([str(dart), 'compile', 'exe', '--packages=' + str(config), str(entry), '-o', str(plugin)], check=True, cwd=root)
    cs = temporary / 'csharp'
    dart_out = temporary / 'dart'
    cs.mkdir()
    dart_out.mkdir()
    schemas = sorted(str(path.relative_to(root / 'contracts')) for path in (root / 'contracts').rglob('*.proto'))
    subprocess.run([str(protoc), '--version'], check=True)
    subprocess.run([str(protoc), '-I', str(root / 'contracts'), '--csharp_out=' + str(cs), '--grpc_out=' + str(cs), '--plugin=protoc-gen-grpc=' + str(binaries / ('grpc_csharp_plugin' + suffix)), *schemas], check=True, cwd=root)
    subprocess.run([str(protoc), '-I', str(root / 'contracts'), '--dart_out=grpc:' + str(dart_out), '--plugin=protoc-gen-dart=' + str(plugin), *schemas], check=True, cwd=root)
    for generated, target in [(cs, cs_target), (dart_out, dart_target)]:
        expected = {p.relative_to(generated): p.read_bytes() for p in generated.rglob('*') if p.is_file()}
        actual = {p.relative_to(target): p.read_bytes() for p in target.rglob('*') if p.is_file()}
        if args.check:
            if expected != actual:
                raise SystemExit(f'Generated contracts differ: {target.relative_to(root)}')
        else:
            for stale in actual.keys() - expected.keys():
                (target / stale).unlink()
            for name, content in expected.items():
                (target / name).parent.mkdir(parents=True, exist_ok=True)
                (target / name).write_bytes(content)
print('Generated contracts match.' if args.check else 'Generated both protocol boundaries.')
