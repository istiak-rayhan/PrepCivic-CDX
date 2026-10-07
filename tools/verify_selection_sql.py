"""Run the app's actual SQL against SQLite using the supplied French assets."""
import csv
import re
import sqlite3
from pathlib import Path
root = Path(__file__).resolve().parents[1]
source = (root / 'lib/services/database_helper.dart').read_text(encoding='utf-8')
merge_query = re.search(r"db\.rawUpdate\(\s*'''(UPDATE user_progress SET.*?)'''", source, re.S).group(1)
query = re.search(r"db\.rawQuery\(\s*'''(SELECT q\.\*.*?LIMIT 10)'''", source, re.S).group(1)
db = sqlite3.connect(':memory:')
db.row_factory = sqlite3.Row
db.executescript('CREATE TABLE questions(id INTEGER PRIMARY KEY, hash_id TEXT, category TEXT, text_fr TEXT); CREATE TABLE user_progress(question_hash TEXT, times_seen INTEGER DEFAULT 0, is_mastered INTEGER DEFAULT 0);')
count = 0
for file in (root / 'assets/fr').glob('*.csv'):
    with file.open(encoding='utf-8-sig', newline='') as handle:
        for i, row in enumerate(csv.reader(handle)):
            if row and row[0] == 'question':
                count += 1
                db.execute('INSERT INTO questions VALUES(?,?,?,?)', (count, f'{file.name}_{i}', file.stem, row[1]))
                db.execute('INSERT INTO user_progress(question_hash) VALUES(?)', (f'{file.name}_{i}',))
checks = 0
for file in (root / 'assets/fr').glob('*.csv'):
    category = file.stem
    first = db.execute(query.replace('$clause', ''), [category, category]).fetchall()
    assert len(first) == 10
    assert len({row['text_fr'].strip().lower() for row in first}) == 10
    excluded = [row['hash_id'] for row in first]
    clause = 'AND q.hash_id NOT IN (' + ','.join('?' for _ in excluded) + ')'
    second = db.execute(query.replace('$clause', clause), [category, category, *excluded]).fetchall()
    assert len(second) == 10
    assert not set(excluded).intersection(row['hash_id'] for row in second)
    db.execute('UPDATE user_progress SET times_seen = 1 WHERE question_hash IN (' + ','.join('?' for _ in excluded) + ')', excluded)
    fresh = db.execute(query.replace('$clause', ''), [category, category]).fetchall()
    assert not set(excluded).intersection(row['hash_id'] for row in fresh)
    db.execute('UPDATE user_progress SET is_mastered = 1 WHERE question_hash IN (' + ','.join('?' for _ in excluded) + ')', excluded)
    unmastered = db.execute(query.replace('$clause', ''), [category, category]).fetchall()
    assert not set(excluded).intersection(row['hash_id'] for row in unmastered)
    checks += 4
print(f'{checks} SQLite selection checks passed across six categories ({count} source questions).')

db.execute('ALTER TABLE user_progress ADD COLUMN times_correct INTEGER DEFAULT 0')
# A stale cloud snapshot must not erase locally completed answers or mastery.
hash_id = db.execute('SELECT question_hash FROM user_progress LIMIT 1').fetchone()[0]
db.execute('UPDATE user_progress SET times_seen=8, times_correct=3, is_mastered=1 WHERE question_hash=?', [hash_id])
db.execute(merge_query, [2, 1, 0, hash_id])
row = db.execute('SELECT times_seen, times_correct, is_mastered FROM user_progress WHERE question_hash=?', [hash_id]).fetchone()
assert tuple(row) == (8, 3, 1)
db.execute(merge_query, [10, 5, 1, hash_id])
row = db.execute('SELECT times_seen, times_correct, is_mastered FROM user_progress WHERE question_hash=?', [hash_id]).fetchone()
assert tuple(row) == (10, 5, 1)
print('2 additional SQLite merge checks passed: retain local progress and accept newer cloud progress.')
