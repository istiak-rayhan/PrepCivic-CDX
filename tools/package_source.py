"""Create a portable source ZIP, excluding machine-specific build artifacts."""
import argparse
import hashlib
import zipfile
from pathlib import Path
root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--original', type=Path, help='Optional original ZIP for a change manifest')
parser.add_argument('--output', type=Path, default=root.parent / f'{root.name}-source.zip')
args = parser.parse_args()
original = args.original
target = args.output.resolve()
excluded_parts = {'.dart_tool', '.git', '.gradle', 'build', 'ephemeral', '.plugin_symlinks', '.idea', 'Pods', '__pycache__'}
excluded_names = {'local.properties', 'Generated.xcconfig', 'flutter_export_environment.sh', '.flutter-plugins-dependencies', 'ASSET_AUDIT_OUTPUT.txt', 'DEPENDENCY_RESULTS.txt'}
files = [p for p in root.rglob('*') if p.is_file()
         and not excluded_parts.intersection(p.relative_to(root).parts)
         and p.name not in excluded_names
         and p.resolve() != target
         and p.suffix not in {'.jks', '.keystore', '.p8', '.p12', '.mobileprovision'}
         and p.name not in {'key.properties', 'firebase_key.json'}
         and not p.name.startswith('.env')]
original_files = {}
if original is not None:
    with zipfile.ZipFile(original) as archive:
        for info in archive.infolist():
            if info.is_dir():
                continue
            parts = info.filename.split('/')
            if parts[0] in {root.name, 'PrepCivic_app-main'}:
                relative = '/'.join(parts[1:])
            else:
                relative = info.filename
            original_files[relative] = hashlib.sha256(archive.read(info)).hexdigest()
    changes = []
    for file in files:
        relative = file.relative_to(root).as_posix()
        digest = hashlib.sha256(file.read_bytes()).hexdigest()
        if relative not in original_files:
            changes.append(('Added', relative))
        elif original_files[relative] != digest:
            changes.append(('Changed', relative))
    manifest = root / 'SOURCE_CHANGES.md'
    manifest.write_text('# Source changes from supplied ZIP\n\n' +
                       '\n'.join(f'- {kind}: `{path}`' for kind, path in sorted(changes)) + '\n', encoding='utf-8', newline='\n')
    if manifest not in files:
        files.append(manifest)
with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as archive:
    for file in sorted(files):
        archive.write(file, f'{root.name}/{file.relative_to(root).as_posix()}')
with zipfile.ZipFile(target) as archive:
    assert archive.testzip() is None
    assert any(p.endswith('/test/regression_test.dart') for p in archive.namelist())
    assert any(p.endswith('/AUDIT.md') for p in archive.namelist())
print(f'Created {target} ({target.stat().st_size:,} bytes; {len(files)} files)')
