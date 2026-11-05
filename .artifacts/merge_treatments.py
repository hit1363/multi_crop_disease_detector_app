import json, glob, sys, os

root = r'F:\multi_crop_disease_detector_app'
parts = sorted(glob.glob(os.path.join(root, '.artifacts', 'treatment_part_*.json')))
entries = []
seen = {}

for part in parts:
    with open(part, encoding='utf-8') as handle:
        items = json.load(handle)
    for item in items:
        key = item['id']
        if key in seen:
            print('DUPLICATE %s in %s (already in %s)' % (key, os.path.basename(part), seen[key]))
            continue
        seen[key] = os.path.basename(part)
        entries.append(item)

with open(os.path.join(root, 'assets', 'data', 'disease_info.json'), encoding='utf-8') as handle:
    diseases = json.load(handle)

disease_ids = [d['id'] for d in diseases if d['id'] != 'invalid']
treatment_ids = [e['id'] for e in entries]

print('parts: %d' % len(parts))
print('entries: %d' % len(entries))
missing = [i for i in disease_ids if i not in treatment_ids]
extra = [i for i in treatment_ids if i not in disease_ids]
print('missing: %s' % (missing or 'none'))
print('extra: %s' % (extra or 'none'))

required = ['id']
for section in ['cultural_control', 'chemical_control', 'biological_control', 'prevention_tips']:
    for lang in ['en', 'bn', 'ur']:
        required.append('%s_%s' % (section, lang))

problems = []
for entry in entries:
    if set(entry.keys()) != set(required):
        problems.append('%s keys: %s' % (entry['id'], sorted(set(required) ^ set(entry.keys()))))
        continue
    for key in required[1:]:
        value = entry[key]
        if not isinstance(value, list):
            problems.append('%s.%s not a list' % (entry['id'], key))
            continue
        if any(not isinstance(x, str) or not x.strip() for x in value):
            problems.append('%s.%s bad item' % (entry['id'], key))
        if len(value) > 4:
            problems.append('%s.%s too many items (%d)' % (entry['id'], key, len(value)))

if problems:
    print('PROBLEMS:')
    for problem in problems:
        print('  ' + problem)
    sys.exit(1)

if missing:
    sys.exit(1)

out = os.path.join(root, 'assets', 'data', 'treatment_info.json')
with open(out, 'w', encoding='utf-8', newline='\n') as handle:
    json.dump(entries, handle, ensure_ascii=False, indent=2)
    handle.write('\n')

print('wrote %s (%d bytes)' % (out, os.path.getsize(out)))
