import io, sys; sys.stdout=io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
lines = open('C:/Users/admin/Projects/legado_flutter/lib/pages/reader/reader_page.dart', encoding='utf-8').readlines()
for i in range(1098, min(1120, len(lines))):
    print(repr(f'{i+1}: {lines[i].rstrip()}'))
