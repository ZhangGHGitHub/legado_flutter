import sqlite3, os
home = os.path.expanduser('~')
db_path = os.path.join(home, 'Projects', 'legado_flutter', '.dart_tool',
                       'sqflite_common_ffi', 'databases', 'legado.db')
if not os.path.exists(db_path):
    print(f'DB not found at: {db_path}')
    exit(1)
conn = sqlite3.connect(db_path)
cur = conn.execute('SELECT id, name, coverUrl FROM books LIMIT 10')
rows = cur.fetchall()
for r in rows:
    print(f'book: {r[1]} | coverUrl len={len(r[2])} | val=[{r[2]}]')
conn.close()
