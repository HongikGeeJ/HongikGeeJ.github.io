# Supabase realtime sync — Hongik GeeJ Teacher Portal

Thai / English setup for multi-PC realtime saves (schedules, room booking, attendance, student learning notes, orders, …).

**We cannot create the Supabase account for you** (needs your email). After you sign up, send back only the two public values below — we will paste them into config and finish wiring on the live site.

---

## สิ่งที่ต้องส่งกลับมา / What to send back

After creating the project and running SQL, reply with:

1. **Project URL** — e.g. `https://xxxxxxxx.supabase.co`  
   (Settings → API → Project URL)
2. **anon public key** — long `eyJ...` string  
   (Settings → API → `anon` `public`)

**Do NOT send `service_role`.** That key bypasses security and must never go in the browser.

Where we will paste them (you can also do this yourself later):

- File: `data/supabase/supabase-config.json` → `"url"` and `"anonKey"`
- Or browser console on the live site:

```js
hongikSetSupabaseConfig({
  url: 'https://YOUR_PROJECT.supabase.co',
  anonKey: 'eyJ...anon-public-only...'
})
hongikSupabaseStatus()
hongikSyncPortalNow()
```

Until those are filled, the portal keeps working with **localStorage** (and optional Apps Script if configured).

---

## ขั้นตอน / Step-by-step

### 1) Sign up & create project

1. Open https://supabase.com → **Start your project** / sign up  
2. **New project** → pick org, name (e.g. `hongik-geej`), set a DB password (save it), choose a region  
3. Wait until the project is **Ready**

### 2) Run the SQL schema

1. In the project: **SQL** → **New query**  
2. Open this file from the repo and paste **all** of it:

   **`data/supabase/schema.sql`**

3. Click **Run** (should succeed with no errors)

4. **Also run once** (profile photos / Storage / emergency `accountData`) — **required if photo upload or emergency sync shows `portal_stores_store_name_check`**:

   **`data/supabase/FIX-RUN-IN-SQL-EDITOR.sql`** (photos + `accountData`) · or only emergency: **`data/supabase/FIX-accountData.sql`**

   This adds `photos` + `accountData` to `portal_stores` and creates public bucket `teacher-photos` with anon read/write (same trust model as the rest of the portal).

This creates:

| Table | Purpose |
|-------|---------|
| `portal_stores` | Main realtime sync (schedules, roomTt, attendance, sharedNotes, **photos**, **accountData**/emergency, …) |
| `students` | Student profiles |
| `student_learning_records` | Per-lesson learning / daily study records |
| `learning_notes` | Shared teaching notes |
| `day_schedules` | Teacher day schedules (normalized) |
| `room_bookings` | Room timetable blocks |
| `attendance_marks` | Attendance marks |
| `daily_reports` | OT / leave / cancel / orders-style reports |
| Storage `teacher-photos` | High-quality profile JPEGs (public URLs) |

### 3) Copy Project URL + anon key

1. **Project Settings** (gear) → **API**  
2. Copy **Project URL**  
3. Copy **`anon` `public`** key only  
4. Send those two to us (or fill `supabase-config.json` / console as above)

### 4) (Optional) Confirm Realtime

**Database → Publications / Replication** → ensure `portal_stores` is in `supabase_realtime`  
(The SQL script tries to add it automatically.)

---

## How the portal uses Supabase

Priority when saving / syncing portal stores:

1. **Supabase** if `url` + `anonKey` are set → upsert `portal_stores` + Realtime subscribe  
2. Else **Apps Script** if `data/photos/sync-config.json` `syncUrl` is set  
3. Else **localStorage only** (no crash)

**Profile photos:** upload JPEG → Supabase Storage bucket `teacher-photos` (public URL) + `portal_stores.photos` index (per-account merge, never wipe other teachers). Quality stays high (~720px JPEG q≈0.92). **Emergency contacts:** teachers save via emergency tab → `localStorage hongik-account-data-v2` + portal `accountData` (same blob). **Login passwords:** custom PINs live in `localStorage hongik-passwords-v1` and are mirrored into `accountData.__loginPasswords__` (merge + flush with the same portal store); login pulls remote before validate so mobile picks up a PC password change. **One-time SQL:** paste `data/supabase/FIX-RUN-IN-SQL-EDITOR.sql` (or `FIX-accountData.sql`) in Supabase SQL Editor if cloud save fails (`store_name_check` or Storage bucket missing). Until then, photos/emergency/password sync stay on that PC only.

Live site:

**https://hongikgeej.github.io/TeacherLogin/**

---

## Console helpers

```js
hongikSupabaseStatus()
hongikSetSupabaseConfig({ url: '...', anonKey: '...' })
hongikClearSupabaseConfig()
hongikSyncPortalNow()
hongikPushPortalNow()
hongikPortalSyncStatus()
```

---

## Security note

Current RLS allows `anon` read/write (same idea as Apps Script “Anyone” Web App). Fine for a trusted teacher portal. Later you can add Supabase Auth and tighter policies. Never commit or paste **service_role** into the HTML or config JSON.
