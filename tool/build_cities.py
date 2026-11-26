#!/usr/bin/env python3
"""Builds assets/prayer/cities.json (feature 014, research D4) from GeoNames cities15000.txt.

GeoNames data is CC BY 4.0 (https://www.geonames.org). The script never downloads: pass the path of an unzipped
cities15000.txt (https://download.geonames.org/export/dump/cities15000.zip).

Kept: the Arab League and OIC member countries; population >= 100,000, or the capital (feature code PPLC).
Arabic name: the first Arabic-script alternate name written with Arabic letters only (Persian or Urdu forms skipped),
else the ASCII name. Output sorted by population, largest first.

usage: python3 -I tool/build_cities.py <cities15000.txt> <out.json>
"""
import json
import sys

ARAB_LEAGUE = 'DZ BH KM DJ EG IQ JO KW LB LY MR MA OM PS QA SA SO SD SY TN AE YE'.split()
OIC_OTHERS = ('AF AL AZ BD BJ BN BF CM TD CI GA GM GN GW GY ID IR KZ KG MV ML MZ NE NG PK SN SL SR TJ TG TR TM UG '
              'UZ').split()
COUNTRIES = set(ARAB_LEAGUE + OIC_OTHERS)

# Arabic letters, hamza forms, taa marbuta, alef maqsura, tatweel, diacritics, space and hyphen.
ARABIC_OK = set(chr(c) for c in range(0x0621, 0x063B)) | set(chr(c) for c in range(0x0640, 0x0653)) | set(' -')


# Hand fixes for names GeoNames gives badly or not at all in Arabic (Egypt first, where most readers are), keyed by
# (country, ASCII name). Each value is the usual Arabic name of the city.
OVERRIDES = {
    ('EG', 'Al Fayyum'): 'الفيوم',
    ('EG', 'Qina'): 'قنا',
    ('EG', 'Bush'): 'ناصر',
    ('EG', 'Madinat an Nasr'): 'مدينة نصر',
    ('EG', '6th of October City'): 'السادس من أكتوبر',
    ('EG', 'Kom Ombo'): 'كوم أمبو',
    ('EG', 'Al Hawamidiyah'): 'الحوامدية',
    ('EG', 'Sinnuris'): 'سنورس',
    ('EG', 'Al Khusus'): 'الخصوص',
    ('PK', 'Gujranwala'): 'غوجرانوالا',
}


def _score(name):
    """Prefers the standard Arabic spelling: taa marbuta, the article, hamza on alef, final yaa over alef maqsura,
    then the longer name (مكة المكرمة over مكة)."""
    s = 3 * ('ة' in name) + 2 * name.startswith('ال') + sum(ch in 'أإآ' for ch in name)
    s -= 2 * name.endswith('ى')
    return (s, len(name))


def arabic_name(alternates):
    names = [n.strip() for n in alternates.split(',')]
    names = [n for n in names
             if n and any('ء' <= ch <= 'ي' for ch in n) and all(ch in ARABIC_OK for ch in n)
             and not any('ً' <= ch <= 'ْ' for ch in n)]
    return max(names, key=_score) if names else None


def main(src, out):
    rows = []
    with open(src, encoding='utf-8') as f:
        for line in f:
            p = line.rstrip('\n').split('\t')
            cc, feature, population = p[8], p[7], int(p[14] or 0)
            if cc not in COUNTRIES or not (population >= 100000 or feature == 'PPLC'):
                continue
            en = p[2]
            rows.append({
                'ar': OVERRIDES.get((cc, en)) or arabic_name(p[3]) or en,
                'en': en,
                'cc': cc,
                'lat': round(float(p[4]), 3),
                'lon': round(float(p[5]), 3),
                'tz': p[17],
                '_pop': population,
            })
    rows.sort(key=lambda r: -r['_pop'])
    for r in rows:
        del r['_pop']
    with open(out, 'w', encoding='utf-8') as f:
        json.dump(rows, f, ensure_ascii=False, separators=(',', ':'))
    print(len(rows), 'cities;', sum(1 for r in rows if r['ar'] != r['en']), 'with an Arabic name')


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
