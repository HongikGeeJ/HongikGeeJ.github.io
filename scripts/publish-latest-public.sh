#!/bin/zsh
# One-shot: publish LATEST HongikGeeJ Teacher Login to a public URL (aired.sh)
# Run in Terminal.app / iTerm (outside Cursor sandbox).
set -euo pipefail
cd "$(dirname "$0")/.."
echo "==> Building inlined latest HTML…"
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
marker = '<!-- hongik-build:2026-09-22-bloom-sparkles -->'
if 'hongik-build:2026-09-22-bloom-sparkles' not in out[:600]:
    out = out.replace('<!DOCTYPE html>', '<!DOCTYPE html>\n' + marker, 1)
path = root / 'ready' / 'HongikGeeJ-Teacher-Login.aired.html'
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(out, encoding='utf-8')
print('built', path, 'bytes', len(out.encode()))
assert len(out.encode()) < 2 * 1024 * 1024, 'over 2MB aired limit'

env_path = root / '.deploy' / 'aired.env'
env = {}
if env_path.exists():
    env = dict(l.split('=', 1) for l in env_path.read_text().splitlines() if '=' in l)

html = out
payload = {
    'html': html,
    'title': 'Hongik GeeJ Teacher Login — latest',
    'permanent': True,
}
if env.get('id') and env.get('update_token'):
    payload['id'] = env['id']
    payload['update_token'] = env['update_token']
    url = f"https://aired.sh/api/pages/{env['id']}"
    method = 'PUT'
else:
    url = 'https://aired.sh/api/publish'
    method = 'POST'

data = json.dumps(payload).encode()
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
try:
    with urllib.request.urlopen(req, timeout=180) as resp:
        body = resp.read().decode()
        print(method, resp.status, body[:500])
        j = json.loads(body)
except Exception as e:
    print(method, 'failed', e)
    req2 = urllib.request.Request(
        'https://aired.sh/api/publish',
        data=json.dumps({
            'html': html,
            'title': 'Hongik GeeJ Teacher Login — latest',
            'permanent': True,
        }).encode(),
        headers={
            'Content-Type': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Origin': 'https://aired.sh',
            'Referer': 'https://aired.sh/',
        },
        method='POST',
    )
    with urllib.request.urlopen(req2, timeout=180) as resp:
        body = resp.read().decode()
        print('FRESH', resp.status, body[:500])
        j = json.loads(body)

live = j.get('url') or (f"https://aired.sh/p/{j['id']}" if j.get('id') else '')
if j.get('id') and j.get('update_token'):
    env_path.parent.mkdir(parents=True, exist_ok=True)
    env_path.write_text(
        f"url={live}\nid={j['id']}\nupdate_token={j['update_token']}\nhost=aired.sh\n"
    )
print('')
print('LIVE_URL=' + live)
print('Verify: open that URL and View Source — should contain hongik-build:2026-09-22-bloom-sparkles')
PY
