#!/usr/bin/env python3
"""
ONE-SHOT DEPLOY: Draught / Draft Beer page  ->  nigelthomas.live

Run from the repo root:
    cd C:\\Users\\admin\\Desktop\\nigelthomas-portfolio
    python deploy_draught_beers.py

Put these 3 files in the SAME folder as this script (the repo root is fine):
    draught-beers.html      (self-contained page, poster embedded)
    draught-beers.png       (poster, also used for og:image)
    deploy_draught_beers.py

What it does (nothing is pushed until you type y):
  1. Copies the page to the repo root and the poster to assets/
  2. Finds the other bar pages (vodka, cocktails, wine, ...) and links them under the download button
  3. Adds a link to this page under the download button of each bar page
  4. Adds the URL to sitemap.xml and a card to blog.html
  5. git pull --rebase --autostash, commit ONLY these files, push, then checks the live URLs
Files are read/written as UTF-8 with no BOM and original line endings are kept.
"""
import html as htmllib
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.request

# ------------------------------------------------------------------ CONFIG
SLUG = 'draught-beers'
DOMAIN = 'https://www.nigelthomas.live'
PAGE_TITLE = 'Draught / Draft Beer: The Complete Guide for Bar Professionals'
LINK_TITLE = 'Draught / Draft Beer: The Complete Guide for Bar Professionals'
CARD_META = 'September 20, 2026 &middot; 12 min read &middot; Bar &amp; Beverage'
CARD_EXCERPT = ('Draught vs draft, keg vs cask, how a draught system works, CO2 carbonation, pressure by temperature, '
                'line balancing, foam fixes, line cleaning and pouring technique, with a free downloadable poster.')
CARD_ALT = 'Draught / Draft Beer complete guide poster for bar professionals'
LASTMOD = '2026-09-20'
LIVE_CHECK_TEXT = 'Draught / Draft Beer'
COMMIT_MSG = 'Add Draught / Draft Beer guide page, poster, sitemap and blog card; cross-link bar pages'
# --------------------------------------------------------------------------

HTML_NAME = SLUG + '.html'
PNG_NAME = SLUG + '.png'
URL = '%s/%s' % (DOMAIN, HTML_NAME)
POSTER_URL = '%s/assets/%s' % (DOMAIN, PNG_NAME)

BAR_TOKENS = {'cocktail', 'cocktails', 'vodka', 'tequila', 'tequilas', 'beer', 'beers', 'draught', 'draft', 'wine',
              'wines', 'whisky', 'whiskey', 'gin', 'rum', 'brandy', 'cognac', 'spirits', 'liquor', 'liqueur',
              'mixology', 'bartending', 'bartender', 'bar', 'champagne', 'sake', 'mezcal', 'sparkling'}
SKIP_FILES = {'blog.html', 'index.html', '404.html', 'image-usage.html', HTML_NAME}
END_INFO = '<!-- END NT INFOMATICS -->'
REL_OPEN = '<!-- NT-BAR-RELATED -->'
REL_CLOSE = '<!-- /NT-BAR-RELATED -->'

changed = []      # files modified/created (relative paths) to be committed
warnings = []


def say(msg):
    print(msg)


def warn(msg):
    warnings.append(msg)
    print('WARN: ' + msg)


def read(path):
    with open(path, 'r', encoding='utf-8', newline='') as f:
        return f.read()


def write(path, text):
    with open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(text)


def nl_of(text):
    return '\r\n' if '\r\n' in text else '\n'


def run(cmd, check=True):
    r = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', errors='replace')
    if check and r.returncode != 0:
        raise RuntimeError('%s failed:\n%s\n%s' % (' '.join(cmd), r.stdout, r.stderr))
    return r


def esc(s):
    return htmllib.escape(s, quote=False)


def page_title(path):
    try:
        t = read(path)
    except Exception:
        return None
    m = re.search(r'<title>(.*?)</title>', t, re.S | re.I)
    if not m:
        return None
    s = htmllib.unescape(m.group(1)).strip()
    s = re.sub(r'\s*[|\u2013\u2014-]\s*Nigel.*$', '', s)
    return s or None


def discover_bar_pages():
    found = []
    for fn in sorted(os.listdir('.')):
        if not fn.lower().endswith('.html') or fn in SKIP_FILES:
            continue
        tokens = set(re.split(r'[^a-z0-9]+', fn[:-5].lower()))
        if tokens & BAR_TOKENS:
            found.append(fn)
    return found


# ------------------------------------------------------------------ related-links block
def li_html(href, title):
    return '<li><a href="%s" style="color:#f0d060;">%s</a></li>' % (href, esc(title))


def add_related_link(path, href, title):
    """add <li> link to the NT-BAR-RELATED block of `path` (create the block after the infomatics section if needed)"""
    text = read(path)
    nl = nl_of(text)
    if REL_OPEN in text:
        i = text.index(REL_OPEN)
        j = text.find('</ul>', i)
        k = text.find(REL_CLOSE, i)
        if j == -1 or (k != -1 and j > k):
            warn('%s: related block has no </ul>, skipped' % path)
            return False
        if href in text[i:j]:
            return False
        new_li = '    <li><a href="%s">%s</a></li>' % (href, esc(title)) if path == HTML_NAME else '    ' + li_html(href, title)
        ls = text.rfind('\n', 0, j) + 1
        at = ls if text[ls:j].strip() == '' else j
        text = text[:at] + new_li + nl + text[at:]
        write(path, text)
        return True
    if END_INFO in text:
        block = nl.join([
            '',
            REL_OPEN,
            '<div class="nt-bar-related" style="margin:28px auto 10px;max-width:760px;text-align:left;background:#141311;'
            'border:1px solid #d4af37;border-radius:10px;padding:16px 22px;">',
            '<h3 style="margin:0 0 8px;color:#d4af37;">More Bar Guides</h3>',
            '<ul style="margin:0;padding-left:1.2em;line-height:1.9;color:#e9e4d4;">',
            '    ' + li_html(href, title),
            '</ul>',
            '</div>',
            REL_CLOSE,
            ''])
        i = text.index(END_INFO) + len(END_INFO)
        text = text[:i] + block + text[i:]
        write(path, text)
        return True
    return None   # no infographic section to hang the links under


# ------------------------------------------------------------------ sitemap
def patch_sitemap():
    if not os.path.exists('sitemap.xml'):
        warn('sitemap.xml not found')
        return
    text = read('sitemap.xml')
    if URL in text:
        say('  sitemap.xml already lists the page')
        return
    nl = nl_of(text)
    m = list(re.finditer(r'^([ \t]*)<url>', text, re.M))
    ind = m[-1].group(1) if m else '  '
    entry = nl.join([
        ind + '<url>',
        ind + '  <loc>%s</loc>' % URL,
        ind + '  <lastmod>%s</lastmod>' % LASTMOD,
        ind + '  <changefreq>monthly</changefreq>',
        ind + '  <priority>0.8</priority>',
        ind + '</url>']) + nl
    i = text.rfind('</urlset>')
    if i == -1:
        warn('sitemap.xml has no </urlset>')
        return
    # insert at the start of the closing tag's line
    ls = text.rfind('\n', 0, i) + 1
    prefix = text[ls:i]
    if prefix.strip() == '':
        text = text[:ls] + entry + text[ls:]
    else:
        text = text[:i] + nl + entry + text[i:]
    write('sitemap.xml', text)
    changed.append('sitemap.xml')
    say('  sitemap.xml: entry added')


# ------------------------------------------------------------------ blog card
CARD_CLASS = r'(?<![\w-])article-card(?![\w-])'


def balanced_end(text, start, tag):
    depth = 0
    for mt in re.finditer(r'<(/?)%s\b[^>]*>' % tag, text[start:], re.I):
        depth += -1 if mt.group(1) else 1
        if depth == 0:
            return start + mt.end()
    return -1


def find_card_block(text, anchor_pos):
    """block (start, end) of the article-card element that contains/precedes anchor_pos"""
    best = None
    for m in re.finditer(r'<(div|article|li|a)\b[^>]*class="[^"]*%s[^"]*"[^>]*>' % CARD_CLASS, text, re.I):
        if m.start() > anchor_pos:
            break
        end = balanced_end(text, m.start(), m.group(1))
        if end != -1 and end >= anchor_pos:
            best = (m.start(), end)
    return best


def card_before(text, pos):
    """the last complete article-card element that ends before pos"""
    best = None
    for m in re.finditer(r'<(div|article|li|a)\b[^>]*class="[^"]*%s[^"]*"[^>]*>' % CARD_CLASS, text, re.I):
        if m.start() >= pos:
            break
        end = balanced_end(text, m.start(), m.group(1))
        if end != -1 and end <= pos + 8:
            best = (m.start(), end)
    return best


def set_inner(block, cls, new_text):
    pat = re.compile(r'(<(\w+)\b[^>]*class="[^"]*(?<![\w-])%s(?![\w-])[^"]*"[^>]*>)(.*?)(</\2>)' % cls, re.S)
    m = pat.search(block)
    if not m:
        return block, False
    inner = m.group(3)
    a = re.search(r'(<a\b[^>]*>)(.*?)(</a>)', inner, re.S)
    if a:
        inner_new = inner[:a.start(2)] + new_text + inner[a.end(2):]
    else:
        inner_new = new_text
    return block[:m.start(3)] + inner_new + block[m.end(3):], True


def clone_card(block):
    def fix_href(m):
        orig = m.group(2)
        if '.html' not in orig:
            return m.group(0)
        if orig.startswith('http'):
            new = URL
        elif orig.startswith('/'):
            new = '/' + HTML_NAME
        else:
            new = HTML_NAME
        return m.group(1) + new + m.group(3)
    b = re.sub(r'(href=")([^"]*)(")', fix_href, block)

    def fix_src(m):
        orig = m.group(2)
        new = ('/' if orig.startswith('/') else '') + 'assets/' + PNG_NAME
        if orig.startswith('http'):
            new = POSTER_URL
        return m.group(1) + new + m.group(3)
    b = re.sub(r'(<img\b[^>]*?\bsrc=")([^"]*)(")', fix_src, b, flags=re.S)
    b = re.sub(r'(<img\b[^>]*?\balt=")([^"]*)(")', lambda m: m.group(1) + CARD_ALT + m.group(3), b, flags=re.S)
    ok = True
    for cls, val in (('article-title', esc(LINK_TITLE)), ('article-meta', CARD_META), ('article-excerpt', esc(CARD_EXCERPT))):
        b, hit = set_inner(b, cls, val)
        if cls == 'article-title':
            ok = ok and hit
    # anchor titles / aria labels that still carry the old title would be confusing: report only
    return b, ok


def patch_blog(bar_pages):
    if not os.path.exists('blog.html'):
        warn('blog.html not found')
        return
    text = read('blog.html')
    if HTML_NAME in text:
        say('  blog.html already has a card for this page')
        return
    nl = nl_of(text)
    marker_nums = [int(n) for n in re.findall(r'END NEW CARD\s+(\d+)', text)]
    next_num = (max(marker_nums) + 1) if marker_nums else None

    ref = None
    ref_kind = None
    # 1) prefer a card of another bar page so the new card lands in the right section
    for fn in sorted(bar_pages, key=lambda f: (0 if 'cocktail' in f else 1, f)):
        pos = text.find(fn)
        if pos != -1:
            blk = find_card_block(text, pos)
            if blk:
                ref, ref_kind = blk, 'bar card (%s)' % fn
                break
    # 2) otherwise the card just before the last END NEW CARD marker
    if not ref:
        marks = [m.start() for m in re.finditer(r'END NEW CARD', text)]
        if marks:
            blk = card_before(text, marks[-1])
            if blk:
                ref, ref_kind = blk, 'last card before END NEW CARD marker'
    if not ref:
        write_card_fallback('could not find an article-card block to copy')
        return
    s, e = ref
    block = text[s:e]
    new_block, ok = clone_card(block)
    if not ok or HTML_NAME not in new_block:
        write_card_fallback('card structure not recognised')
        return
    ls = text.rfind('\n', 0, s) + 1
    indent = re.match(r'[ \t]*', text[ls:s]).group(0) if text[ls:s].strip() == '' else ''
    # insertion point: after the block, plus an immediately-following END NEW CARD marker comment
    ins = e
    tail = re.match(r'\s*(<!--\s*END NEW CARD[^>]*-->)', text[e:])
    if tail:
        ins = e + tail.end()
    marker = ''
    if next_num is not None:
        marker = ' <!-- END NEW CARD %d -->' % next_num
    addition = nl + nl + indent + new_block + marker
    text = text[:ins] + addition + text[ins:]
    write('blog.html', text)
    changed.append('blog.html')
    say('  blog.html: card added after %s' % ref_kind)
    say('           (check it in the diff below: it was cloned from an existing card)')


def write_card_fallback(reason):
    snippet = '''<div class="article-card">
  <img src="assets/%s" alt="%s" loading="lazy">
  <h3 class="article-title"><a href="%s">%s</a></h3>
  <p class="article-meta">%s</p>
  <p class="article-excerpt">%s</p>
  <a href="%s" class="read-more-btn">Read More</a>
</div>
''' % (PNG_NAME, CARD_ALT, HTML_NAME, esc(LINK_TITLE), CARD_META, esc(CARD_EXCERPT), HTML_NAME)
    write('blog-card-%s.txt' % SLUG, snippet)
    warn('blog.html NOT changed (%s). Card saved to blog-card-%s.txt - paste it above an END NEW CARD marker.' % (reason, SLUG))


# ------------------------------------------------------------------ live check
def fetch(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 nt-deploy-check'})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.status, r.read()


def live_check():
    checks = [(URL, LIVE_CHECK_TEXT.encode()), (POSTER_URL, None), (DOMAIN + '/sitemap.xml', URL.encode()),
              (DOMAIN + '/blog.html', HTML_NAME.encode())]
    say('Checking live site (Vercel usually needs 30-90 seconds)...')
    pending = list(checks)
    for attempt in range(12):
        still = []
        for url, needle in pending:
            try:
                st, data = fetch(url)
                good = st == 200 and (needle is None or needle in data)
            except Exception:
                good = False
            if good:
                say('  OK    ' + url)
            else:
                still.append((url, needle))
        pending = still
        if not pending:
            break
        time.sleep(10)
    for url, _ in pending:
        warn('not confirmed live yet: ' + url + ' (re-check in a minute)')


# ------------------------------------------------------------------ main
def main():
    here = os.path.dirname(os.path.abspath(__file__))
    if not (os.path.isdir('.git') and os.path.exists('sitemap.xml')):
        sys.exit('Run this from the repo root (cd C:\\Users\\admin\\Desktop\\nigelthomas-portfolio). No .git/sitemap.xml here.')
    src_html = next((p for p in (os.path.join(here, HTML_NAME), HTML_NAME) if os.path.exists(p)), None)
    src_png = next((p for p in (os.path.join(here, PNG_NAME), PNG_NAME) if os.path.exists(p)), None)
    if not src_html or not src_png:
        sys.exit('Missing %s and/or %s next to this script.' % (HTML_NAME, PNG_NAME))

    say('1. Copying page and poster')
    if os.path.abspath(src_html) != os.path.abspath(HTML_NAME):
        shutil.copyfile(src_html, HTML_NAME)
    os.makedirs('assets', exist_ok=True)
    dst_png = os.path.join('assets', PNG_NAME)
    if os.path.abspath(src_png) != os.path.abspath(dst_png):
        shutil.copyfile(src_png, dst_png)
    changed.extend([HTML_NAME, 'assets/' + PNG_NAME])
    say('  %s  +  assets/%s' % (HTML_NAME, PNG_NAME))
    # the loose root copy of the poster (if you dropped it in the repo root) is not committed
    if os.path.exists(PNG_NAME) and os.path.abspath(PNG_NAME) != os.path.abspath(dst_png):
        try:
            os.remove(PNG_NAME)
            say('  removed loose %s from repo root (kept assets/%s)' % (PNG_NAME, PNG_NAME))
        except OSError:
            pass

    say('2. Bar pages found at the site root')
    bars = discover_bar_pages()
    for fn in bars:
        say('  ' + fn)
    if not bars:
        say('  (none found)')

    say('3. Linking pages under the download buttons')
    for fn in bars:
        title = page_title(fn) or fn
        if add_related_link(HTML_NAME, '/' + fn, title):
            say('  %s  <-  link to %s' % (HTML_NAME, fn))
    for fn in bars:
        r = add_related_link(fn, '/' + HTML_NAME, LINK_TITLE)
        if r:
            changed.append(fn)
            say('  %s  <-  link to %s' % (fn, HTML_NAME))
        elif r is None:
            warn('%s has no "END NT INFOMATICS" section, so no link was added there' % fn)

    say('4. sitemap.xml and blog.html')
    patch_sitemap()
    patch_blog(bars)

    files = []
    for f in changed:
        if f not in files:
            files.append(f)
    say('')
    say('Files to commit:')
    for f in files:
        say('  ' + f)
    r = run(['git', 'diff', '--stat', '--'] + [f for f in files if os.path.exists(f)], check=False)
    say(r.stdout)
    if warnings:
        say('Warnings so far: %d (see WARN lines above)' % len(warnings))
    if '--yes' not in sys.argv:
        ans = input('Commit and push these files now? [y/N] ').strip().lower()
        if ans != 'y':
            say('Stopped before committing. Files are changed locally; review with: git diff')
            return

    say('5. Git')
    run(['git', 'pull', '--rebase', '--autostash'])
    run(['git', 'add', '--'] + files)
    c = run(['git', 'commit', '-m', COMMIT_MSG], check=False)
    say(c.stdout.strip() or c.stderr.strip())
    run(['git', 'push'])
    say('Pushed.')
    if '--no-live' not in sys.argv:
        live_check()
    say('')
    say('PAGE URL   : ' + URL)
    say('POSTER URL : ' + POSTER_URL)
    say('Submit the page URL in Google Search Console > URL Inspection > Request indexing.')


if __name__ == '__main__':
    main()
