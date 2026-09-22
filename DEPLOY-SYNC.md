# Deploy + central sync

## Production hosting (GitHub Pages — stable URL)

**Do not use aired.sh for production.** One-off publishes get new IDs / 403 on update. Production is **Git + GitHub Actions → GitHub Pages** at a fixed URL.

### Stable LIVE URL (share this)

**LIVE (primary):**

https://hongikgeej.github.io/TeacherLogin/

Root `https://hongikgeej.github.io/` redirects to `/TeacherLogin/`.

Org: [HongikGeeJ](https://github.com/HongikGeeJ) · Repo: [HongikGeeJ.github.io](https://github.com/HongikGeeJ/HongikGeeJ.github.io)  
Git remote `github` → that repo. Old personal site (archive): https://chattarins.github.io/HongikGeeJLogin/ (`github-chattarins` remote).

(`index.html` at site root → `/TeacherLogin/`; portal HTML + `assets/` + `data/` live under `TeacherLogin/`.)

### How CI/CD works

1. Push (or merge) to **`main`**
2. Workflow [`.github/workflows/deploy-pages.yml`](.github/workflows/deploy-pages.yml) runs
3. Workflow stages `TeacherLogin/` from `HongikGeeJ Teacher Login.html` + `assets/` + `data/`, then GitHub Pages publishes the **repo root**
4. Same URL forever — refresh after deploy finishes (~1–2 min)

Manual re-run: GitHub → **Actions** → **Deploy to GitHub Pages** → **Run workflow**

### One-time setup (already done for HongikGeeJ)

1. Org `HongikGeeJ` + repo `HongikGeeJ.github.io`
2. **Settings → Pages → Build and deployment → Source: GitHub Actions**
3. Push to `main` (or `./scripts/migrate-to-hongikgeej-pages.sh` if recreating)

Custom domain (e.g. `hongikgeej.com`) is optional and only if you already own a domain.

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
