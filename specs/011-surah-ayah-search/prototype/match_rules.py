#!/usr/bin/env python3
"""Throw-away reference for feature 011's matching rules (research D2). NOT shipped: the Dart code in lib/search/
is written test-first against the real assets and must agree with this file on every number it prints.

Run from the repository root:   python3 -I specs/011-surah-ayah-search/prototype/match_rules.py [--full]

It reads assets/ayah/text/NNN.json and assets/mushaf/meta.json and prints:
  1. the rows of the spec's table (34 typed forms) and the four «exactly» phrases,
  2. 12,472 self-match queries (every ayah pasted as the Mushaf prints it, and typed the careless way),
  3. the narrowing of the optional seat letter (OLD rule of the first prototype against the NEW rule below),
  4. the surah names: 570 queries,
  5. with --full: the result count of every distinct stored word typed carelessly, OLD against NEW, and a timing.
Nothing here writes a file.
"""
import bisect, glob, json, re, sys, time
from collections import Counter

# ---------------------------------------------------------------- data
AYAT = []                                   # (surah, ayah, [stored words]) in Mushaf order
for f in sorted(glob.glob('assets/ayah/text/*.json')):
    d = json.load(open(f, encoding='utf-8'))
    for i, words in enumerate(d['ayahs']):
        AYAT.append((d['surah'], i + 1, words))
META = json.load(open('assets/mushaf/meta.json', encoding='utf-8'))
NAMES = [s['name'] for s in META['surahs']]

# ---------------------------------------------------------------- the rules (the Dart code ports these 1:1)
DAGGER = 'ٰ'            # small alef: SOFT in the stored text (may be skipped; may stand for a typed alef)
HAMZA = 'ء'             # hamza on the line / on a tatweel: SOFT in the stored text (may be skipped)
SOFT = DAGGER + HAMZA
FOLD = {                      # one letter to another, in the stored text and in the query alike
    'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا',     # أ إ آ ٱ  -> ا
    'ؤ': 'و', 'ئ': 'ي',                                   # ؤ -> و, ئ -> ي (stored only; see SEAT in the query)
    'ى': 'ي', 'ی': 'ي', 'ة': 'ه', 'ک': 'ك',     # ى ی -> ي, ة -> ه, ک -> ك
    'ۧ': 'ي', 'ۨ': 'ن',                                   # small high yeh / noon are real letters
    'ٔ': HAMZA, 'ٕ': HAMZA,                               # a hamza sign on a tatweel is a seatless hamza
}
LETTERS = set('ابتثجحخدذرزسشصضطظعغفقكلمنهوي')
def is_letter(c): return c in LETTERS

def norm_word(word):
    """STORED word -> normalised word. Marks, tatweel, signs and the spaces inside a word vanish."""
    out = []
    for c in word:
        c = FOLD.get(c, c)
        if c in LETTERS or c in SOFT:
            out.append(c)
    return ''.join(out)

def norm_ayah(words):
    return ' '.join(norm_word(w) for w in words)

SEAT = {'ؤ': '\x01', 'ئ': '\x02'}   # a typed ؤ / ئ: kept apart from و / ي until the pattern is built
def norm_query(text):
    """QUERY -> a string of letters, single spaces and the two seat markers. Anything else is a word break or vanishes."""
    out, space = [], False
    for c in text:
        if c in SEAT:
            out.append(SEAT[c]); space = False; continue
        c2 = FOLD.get(c, c)
        if c2 in LETTERS:
            out.append(c2); space = False
        elif c2 in SOFT or c2 == 'ـ' or 0x64B <= ord(c) <= 0x65F or 0x6D6 <= ord(c) <= 0x6ED or ord(c) in (0x200B,0x200C,0x200D,0x200E,0x200F,0xFEFF):
            continue                                    # a mark, tatweel, a typed hamza or dagger, an invisible control: gone
        elif not space and out:
            out.append(' '); space = True               # whitespace and any other sign (digits, Latin, ﴿ ﴾ ۝): a word break
    q = ''.join(out).strip(' ')
    return q

def letter_count(q): return sum(1 for c in q if c != ' ')

def pattern_new(q):
    """NEW rule. A seat letter typed by the reader must find a seat letter or a seatless hamza in the text."""
    parts = []
    for c in q:
        if c == ' ':
            parts.append('[' + SOFT + ' ]*'); continue
        if c == 'ا':   parts.append('(?:ا|و' + DAGGER + '|' + DAGGER + ')')   # a typed alef: ا, the و of «الصلوٰة», or the small alef
        elif c == '\x01': parts.append('[و' + HAMZA + ']')
        elif c == '\x02': parts.append('[ي' + HAMZA + ']')
        else: parts.append(c)
        parts.append('[' + SOFT + ']*')
    return re.compile(''.join(parts))

def pattern_old(q):
    """OLD rule (the first prototype): a typed seat letter is OPTIONAL; the hamza is deleted from the text."""
    parts = []
    for c in q:
        if c == ' ': parts.append(r'\s*'); continue
        if c == 'ا':   parts.append('(?:[ا' + DAGGER + ']|و' + DAGGER + ')')
        elif c == '\x01': parts.append('و?')
        elif c == '\x02': parts.append('ي?')
        else: parts.append(c)
        parts.append(DAGGER + '*')
    return re.compile(''.join(parts))

# the whole text as ONE string, a '\n' between ayat (no pattern can match across it): one scan answers a query
def build(norm):
    starts, buf, pos = [], [], 0
    for s, a, w in AYAT:
        t = norm(w); starts.append(pos); buf.append(t); pos += len(t) + 1
    return '\n'.join(buf), starts
TEXT_NEW, START_NEW = build(norm_ayah)
TEXT_OLD, START_OLD = build(lambda w: re.sub(HAMZA, '', norm_ayah(w)))

def scan(pattern, text, starts):
    """The ayat (indexes) that contain the pattern, once each, in Mushaf order."""
    hits, i = [], 0
    while True:
        m = pattern.search(text, i)
        if not m: return hits
        k = bisect.bisect_right(starts, m.start()) - 1
        hits.append(k)
        i = starts[k + 1] if k + 1 < len(starts) else len(text) + 1

def search(query, rule='new'):
    q = norm_query(query)
    if letter_count(q) < 2: return []
    if rule == 'new': return [(AYAT[k][0], AYAT[k][1]) for k in scan(pattern_new(q), TEXT_NEW, START_NEW)]
    return [(AYAT[k][0], AYAT[k][1]) for k in scan(pattern_old(q), TEXT_OLD, START_OLD)]

def fingerprint():
    """The Dart test computes the same number over AyahIndex.chunks: one hash ties the Dart folding to this file."""
    h = 0x811C9DC5
    for t in TEXT_NEW.split('\n'):
        for ch in t + '\n':
            h = ((h ^ ord(ch)) * 0x01000193) & 0xFFFFFFFF
    return h

# ---------------------------------------------------------------- 1. the spec's table
TABLE = [
    (['احمد', 'أحمد'], [(61, 6)], None),
    (['ابراهيم', 'إبراهيم', 'ابراهيـم'], [(14, 35), (2, 124)], None),
    (['الرحمن', 'الرحمٰن'], [(1, 1), (55, 1)], None),
    (['مؤمن', 'مومن'], [(4, 92)], None),
    (['رحمة', 'رحمه'], [(2, 157)], None),
    (['موسى', 'موسي'], [(2, 51)], None),
    (['الكتاب'], [(2, 2)], None),
    (['الصلاة', 'الصلاه'], [(2, 3)], None),
    (['الزكاة'], [(2, 43)], None),
    (['السماوات', 'السموات'], [(2, 33)], None),
    (['شيئا', 'شيأ'], [(2, 48)], None),
    (['يستهزئون', 'يستهزؤون', 'يستهزءون'], [(6, 5)], None),
    (['النبيين'], [(2, 61)], None),
    (['اسماعيل', 'إسماعيل'], [(2, 125)], None),
    (['يا ايها الذين امنوا', 'يأيها الذين آمنوا', 'ياأيها الذين امنوا'], [(2, 104), (2, 153)], None),
    (['بسم الله الرحمن الرحيم'], [(1, 1), (27, 30)], 'exactly'),
    (['ذلك الكتاب لا ريب فيه'], [(2, 2)], 'exactly'),
    (['قل هو الله احد'], [(112, 1)], 'exactly'),
    (['الله لا اله الا هو الحي القيوم'], [(2, 255), (3, 2)], 'exactly'),
]
def check_table(rule):
    forms = fail = 0
    for typed, must, mode in TABLE:
        for t in typed:
            forms += 1
            r = search(t, rule)
            ok = all(m in r for m in must) and (mode != 'exactly' or sorted(r) == sorted(must))
            if t in ('احمد', 'أحمد'): ok = ok and (1, 2) not in r
            if not ok: fail += 1; print('   TABLE FAIL', rule, repr(t), len(r), r[:5])
    return forms, fail

def self_match(rule):
    """SC-003: every ayah, pasted as printed and typed carelessly, returns itself."""
    MARKS_B = re.compile('[ً-ٖٓ-ٟۖ-ۤ۩-ۭـ]')   # tashkeel, Quranic marks, tatweel; the small letters stay
    bad_a = bad_b = 0
    for k, (s, a, w) in enumerate(AYAT):
        full = ' '.join(w)
        careless = MARKS_B.sub('', full).translate(str.maketrans({'ٱ': 'ا', 'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ة': 'ه', 'ى': 'ي'}))
        for form, which in ((full, 'a'), (careless, 'b')):
            q = norm_query(form)
            pat = pattern_new(q) if rule == 'new' else pattern_old(q)
            t = TEXT_NEW if rule == 'new' else TEXT_OLD
            st = START_NEW if rule == 'new' else START_OLD
            end = st[k + 1] - 1 if k + 1 < len(st) else len(t)
            if not pat.search(t, st[k], end):
                if which == 'a': bad_a += 1
                else: bad_b += 1
                if bad_a + bad_b <= 3: print('   SELF FAIL', rule, which, s, a)
    return bad_a, bad_b

# ---------------------------------------------------------------- 3. the narrowing of the seat letter
OVER = ['لؤلؤ', 'اللؤلؤ', 'مؤمن', 'مئة', 'مائة', 'شيئا', 'شئ', 'سيئة', 'يستهزئون', 'النبيئين', 'رؤيا', 'رءيا', 'هؤلاء', 'سئل', 'سؤال', 'مسئول', 'ملئكة', 'الملائكة', 'جزاء', 'جزؤا', 'ءامنوا', 'امنوا']

# ---------------------------------------------------------------- 4. the surah names
def name_key(n):
    s = norm_word(n).replace(HAMZA, '')                      # a name has no seatless hamza of its own: typed ء vanishes
    return s.replace(DAGGER, '')
def strip_al(s): return s[2:] if s.startswith('ال') and len(s) > 2 else s
def surah_search(query):
    q = norm_query(query).replace('\x01', 'و').replace('\x02', 'ي')
    if q.startswith('سوره '): q = q[5:]
    if not q or letter_count(q) < 1: return []
    q1, q2 = q.replace(' ', ''), strip_al(q.replace(' ', ''))
    rows = []
    for i, n in enumerate(NAMES):
        n1 = name_key(n); n2 = strip_al(n1)
        best = None
        for qq in (q1, q2):
            for nn in (n1, n2):
                if qq == nn: r = 0
                elif nn.startswith(qq): r = 1
                elif qq in nn: r = 2
                else: continue
                best = r if best is None else min(best, r)
        if best is not None: rows.append((best, i + 1))
    return [n for _, n in sorted(rows)]

def five_ways(name):
    bare = name.translate(str.maketrans({'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ؤ': 'و', 'ئ': 'ي', 'ء': ''}))
    soft = name.translate(str.maketrans({'ة': 'ه', 'ى': 'ي'}))
    noal = name[2:] if name.startswith('ال') and len(name) > 2 else name
    return [name, bare, soft, 'سورة ' + name, noal]

if __name__ == '__main__':
    t0 = time.time()
    print('ayat', len(AYAT), 'words', sum(len(w) for _, _, w in AYAT), 'normalised text chars', len(TEXT_NEW), 'bytes UTF-8', len(TEXT_NEW.encode()))
    print('fold fingerprint (FNV-1a 32 over the UTF-16 code units of every folded ayah followed by a line break): 0x%08x' % fingerprint())
    empty = sum(1 for _, _, ws in AYAT for w in ws if not norm_word(w))
    print('stored words that normalise to nothing:', empty)
    print('\n== 1. spec table (34 typed forms incl. the 4 exactly phrases)')
    for rule in ('old', 'new'):
        forms, fail = check_table(rule); print(f'   {rule}: {forms} forms, {fail} failures')
    print('\n== 2. self-match (SC-003: 12,472 queries)')
    for rule in ('old', 'new'):
        a, b = self_match(rule); print(f'   {rule}: pasted failures {a}/6236, careless failures {b}/6236')
    print('\n== 3. the optional seat letter: results per typed form, OLD (seat letter optional) -> NEW (seat letter or seatless hamza)')
    for t in OVER:
        print(f'   {t:12s} {len(search(t, "old")):5d} -> {len(search(t, "new")):5d}')
    print('\n== 4. surah names: 5 careless ways x 114 = 570 queries')
    bad = 0; keys = Counter(strip_al(name_key(n)) for n in NAMES)
    for i, n in enumerate(NAMES, 1):
        for q in five_ways(n):
            r = surah_search(q)
            if not r or r[0] != i: bad += 1; print('   NAME FAIL', i, n, repr(q), r[:3])
    print(f'   failures: {bad}/570;  names equal after stripping ال:', [k for k, v in keys.items() if v > 1])
    print('   ق ->', surah_search('ق')[:4], '| الحج ->', surah_search('الحج')[:3], '| سبا ->', surah_search('سبا')[:2], '| ابراهيم ->', surah_search('ابراهيم')[:2], '| سورة الكهف ->', surah_search('سورة الكهف')[:2])
    print('\n== timing of one scan of the whole text (Python re, this machine)')
    for q in ('الرحمن', 'ال', 'رحم', 'بسم الله الرحمن الرحيم', ' '.join(AYAT[285][2])):
        a = time.time(); n = len(search(q)); print(f'   {q[:28]:30s} {n:5d} ayat {1000*(time.time()-a):6.1f} ms')
    if '--full' in sys.argv:
        print('\n== 5. every distinct stored word, typed carelessly (hamza letters kept as the Mushaf has them)')
        MARKS_B = re.compile('[ً-ٖٓ-ٟۖ-ۤ۩-ۭـ]')
        words = sorted({MARKS_B.sub('', w).translate(str.maketrans({'ٱ': 'ا', 'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ة': 'ه', 'ى': 'ي'})) for _, _, ws in AYAT for w in ws})
        words = [w for w in words if letter_count(norm_query(w)) >= 2]
        print('   distinct typed words:', len(words))
        diff = []; tot_old = tot_new = 0; lost = 0; slow = 0.0
        for w in words:
            a = time.time(); n_new = len(search(w, 'new')); slow = max(slow, time.time() - a)
            n_old = len(search(w, 'old')); tot_old += n_old; tot_new += n_new
            if n_new == 0: lost += 1
            diff.append((n_old - n_new, n_old, n_new, w))
        diff.sort(reverse=True)
        print(f'   words that find nothing with NEW: {lost};  total hits OLD {tot_old}  NEW {tot_new}  ({100*(tot_old-tot_new)/tot_old:.1f}% fewer)')
        print('   biggest narrowing (OLD -> NEW):', [(w, o, n) for _, o, n, w in diff[:8]])
        print('   slowest single scan, NEW: %.1f ms' % (slow * 1000))
        gained = [(w, o, n) for d, o, n, w in diff if d < 0][:5]
        print('   words where NEW finds MORE than OLD:', gained)
    print('\ndone in %.1f s' % (time.time() - t0))
