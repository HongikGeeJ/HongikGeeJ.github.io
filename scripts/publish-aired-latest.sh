#!/bin/zsh
# Publish the latest HongikGeeJ Teacher Login.html to the existing aired.sh URL.
# Run this in Terminal.app (outside Cursor sandbox) if agent network is blocked.
set -euo pipefail
cd "$(dirname "$0")/.."

python3 - <<'PY'
from pathlib import Path
from urllib.parse import quote
import base64, json, urllib.request

root = Path('.')
text = (root / 'HongikGeeJ Teacher Login.html').read_text(encoding='utf-8')
assets = {
    'assets/dancheong/corner-flower.svg?v=cluster7': root / 'assets/dancheong/corner-flower.svg',
    'assets/dancheong/corner-bloom.svg?v=bloom6': root / 'assets/dancheong/corner-bloom.svg',
    'assets/dancheong/edge-sparkles.svg?v=flower1': root / 'assets/dancheong/edge-sparkles.svg',
    'assets/dancheong/edge-sparkles-static.svg?v=flower1': root / 'assets/dancheong/edge-sparkles-static.svg',
    # logo.png is only a JS fallback string; school logo is already SCHOOL_LOGO_B64_PARTS
}
out = text
for ref, path in assets.items():
    if not path.exists():
        continue
    data = path.read_bytes()
    if path.suffix == '.svg':
        uri = 'data:image/svg+xml,' + quote(data.decode('utf-8'))
    else:
        uri = 'data:image/png;base64,' + base64.b64encode(data).decode()
    out = out.replace(ref, uri)
# Embed Supabase config so single-file aired hosts work without fetching JSON
cfg_path = root / 'data' / 'supabase' / 'supabase-config.json'
if cfg_path.exists():
    cfg = json.loads(cfg_path.read_text(encoding='utf-8'))
    emb = {
        'url': str(cfg.get('url') or '').strip().rstrip('/'),
        'anonKey': str(cfg.get('anonKey') or cfg.get('anon_key') or '').strip(),
    }
    if emb['url'] and emb['anonKey']:
        import re
        marker = '/*hongik-sb-embed*/window.__HONGIK_SUPABASE_CONFIG__='
        inject = '<script>' + marker + json.dumps(emb, separators=(',', ':')) + ';</script>'
        if '/*hongik-sb-embed*/' not in out:
            out = out.replace('<head>', '<head>\n' + inject, 1)
            print('embedded supabase config for', emb['url'])
        else:
            out2, n = re.subn(
                r'<script>/\*hongik-sb-embed\*/window\.__HONGIK_SUPABASE_CONFIG__=\{.*?\};</script>',
                inject,
                out,
                count=1,
            )
            out = out2 if n else out
            print('updated embedded supabase config for', emb['url'] if n else '(no prior block)')
    else:
        print('supabase-config.json empty — skipped embed')
else:
    print('no supabase-config.json — skipped embed')
marker = '<!-- hongik-build:2026-09-22-mobile-ipad-perf -->'
if 'hongik-build:2026-09-22-mobile-ipad-perf' not in out[:600]:
    out = out.replace('<!DOCTYPE html>', '<!DOCTYPE html>\n' + marker, 1)
aired_path = root / 'ready' / 'HongikGeeJ-Teacher-Login.aired.html'
aired_path.write_text(out, encoding='utf-8')
print('built', aired_path, 'bytes', len(out.encode()))

env = dict(
    line.split('=', 1)
    for line in (root / '.deploy' / 'aired.env').read_text().splitlines()
    if '=' in line
)
def call(url, method, payload_dict):
    data = json.dumps(payload_dict).encode()
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            'Content-Type': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Origin': 'https://aired.sh',
            'Referer': 'https://aired.sh/',
        },
        method=method,
    )
    with urllib.request.urlopen(req, timeout=180) as resp:
        body = resp.read().decode('utf-8', errors='replace')
        print(method, url, resp.status, body[:500])
        return body

base = {
    'html': out,
    'title': 'Hongik GeeJ Teacher Login — latest',
    'permanent': True,
}

try:
    call(
        f"https://aired.sh/api/pages/{env['id']}",
        'PUT',
        {**base, 'id': env['id'], 'update_token': env['update_token']},
    )
except Exception as err:
    print('PUT failed:', err)
    # Fresh publish must omit old id/token — sending them returns stale 404 pages
    body = call('https://aired.sh/api/publish', 'POST', base)
    try:
        j = json.loads(body)
        if j.get('id') and j.get('update_token'):
            live = j.get('url') or f"https://aired.sh/p/{j['id']}"
            (root / '.deploy' / 'aired.env').write_text(
                f"url={live}\nid={j['id']}\nupdate_token={j['update_token']}\nhost=aired.sh\n"
            )
            env['url'] = live
            print('updated .deploy/aired.env →', live)
    except Exception as e2:
        print('could not refresh aired.env:', e2)

print('Live URL:', env.get('url'))
# Trailing slash 404s on aired.sh — use bare /p/<id>
print('Open (no trailing slash):', env.get('url', '').rstrip('/'))
PY
