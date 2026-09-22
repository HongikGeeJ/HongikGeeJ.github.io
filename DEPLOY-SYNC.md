# Deploy + central sync

## Production hosting (GitHub Pages — stable URL)

**Do not use aired.sh for production.** One-off publishes get new IDs / 403 on update. Production is **Git + GitHub Actions → GitHub Pages** at a fixed URL.

### Stable LIVE URL

**LIVE (stable forever):**

https://chattarins.github.io/Hongik-GeeJ-Login/

(`index.html` redirects to `HongikGeeJ Teacher Login.html`.)

### How CI/CD works

1. Push (or merge) to **`main`**
2. Workflow [`.github/workflows/deploy-pages.yml`](.github/workflows/deploy-pages.yml) runs
3. GitHub Pages publishes the **repo root** (portal HTML + `assets/` + `data/` including Supabase config)
4. Same URL forever — refresh after deploy finishes (~1–2 min)

Manual re-run: GitHub → **Actions** → **Deploy to GitHub Pages** → **Run workflow**

### One-time setup (repo owner)

1. Push this repo to GitHub (`main`)
2. **Settings → Pages → Build and deployment → Source: GitHub Actions**
3. First push (or workflow_dispatch) deploys; wait for the green check

---

## A) Supabase realtime (recommended)

We cannot create the account for you. After you sign up:

1. Run `data/supabase/schema.sql` in Supabase SQL Editor  
2. Send **Project URL** + **anon public** key (never `service_role`)  
3. We paste into `data/supabase/supabase-config.json` (or you run `hongikSetSupabaseConfig` in console)

Full Thai/EN steps: `data/supabase/README.md`

Until keys arrive, the live Pages site still works **local-only** (browser storage).

## B) Apps Script (optional fallback)

`clasp` / gcloud are not available in this environment, so the Web App URL must be created once in your Google account.

1. Open https://script.google.com → **New project**
2. Paste everything from `apps-script/Code.gs`
3. **Deploy → New deployment → Web app**
   - Execute as: **Me**
   - Who has access: **Anyone**
4. Copy the URL ending in `/exec`
5. Put it in `data/photos/sync-config.json`:

```json
{ "version": 1, "syncUrl": "https://script.google.com/macros/s/XXXX/exec" }
```

6. Commit + push (or paste in browser console):

```js
hongikSetPortalSyncUrl('https://script.google.com/macros/s/XXXX/exec')
hongikSyncPortalNow()
hongikPortalSyncStatus()
```

Until step 5–6 (and with empty Supabase config), every PC still works **local-only** (no crash). Multi-PC realtime needs Supabase keys or that Apps Script URL.

Priority: **Supabase** → Apps Script → localStorage.
