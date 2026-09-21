# Central sync (Google Apps Script) — 2-minute setup

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

Until step 5–6, every PC still works **local-only** (no crash). Multi-PC realtime needs that URL.
