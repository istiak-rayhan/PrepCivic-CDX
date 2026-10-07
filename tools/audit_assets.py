import csv
import json
import re
from collections import Counter
from pathlib import Path

root = Path(__file__).resolve().parents[1]
report = {'categories': {}, 'missing_ui_keys': {}, 'duplicate_json_keys': {}}
keys = set()
for source in (root / 'lib').rglob('*.dart'):
    keys.update(re.findall(r"'([a-z_0-9]+)'\s*\.tr\(", source.read_text(encoding='utf-8')))
for file in (root / 'assets/translations').glob('*.json'):
    pairs = json.loads(file.read_text(encoding='utf-8-sig'), object_pairs_hook=list)
    names = [k for k, v in pairs]
    report['duplicate_json_keys'][file.stem] = [k for k, n in Counter(names).items() if n > 1]
    report['missing_ui_keys'][file.stem] = sorted(keys - set(names))
for file in (root / 'assets/fr').glob('*.csv'):
    def rows(path):
        with path.open(encoding='utf-8-sig', newline='') as handle:
            return [r for r in csv.reader(handle) if r and any(c.strip() for c in r)]
    french = rows(file)
    questions = [r[1].strip() for r in french if r[0].strip().lower() == 'question']
    category = {'questions': len(questions), 'duplicate_questions': {k: n for k, n in Counter(questions).items() if n > 1}, 'alignment': {}, 'invalid_blocks': []}
    block = None
    for index, row in enumerate(french[1:], 2):
        if row[0].strip().lower() == 'question':
            if block and (block['answers'] < 2 or block['correct'] != 1):
                category['invalid_blocks'].append(block)
            block = {'row': index, 'answers': 0, 'correct': 0}
        elif row[0].strip().lower() == 'answer' and block:
            block['answers'] += 1
            block['correct'] += int(len(row) > 3 and row[3].strip().lower() in ['1', '1.0', 'true'])
    if block and (block['answers'] < 2 or block['correct'] != 1):
        category['invalid_blocks'].append(block)
    for lang in ['bn', 'ar', 'ur', 'ps', 'en']:
        translated = rows(root / 'assets' / lang / file.name)
        category['alignment'][lang] = {'rows': len(translated), 'french_rows': len(french), 'type_mismatches': sum(a[0].strip().lower() != b[0].strip().lower() for a, b in zip(french, translated))}
    report['categories'][file.name] = category
output = root / 'ASSET_AUDIT.json'
output.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(report, ensure_ascii=True, indent=2))
