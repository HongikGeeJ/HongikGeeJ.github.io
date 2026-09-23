-- ═══════════════════════════════════════════════════════════
-- COPY-PASTE THIS ENTIRE FILE into Supabase SQL Editor → Run
-- Project: qoxdpqlzbbsluxzqchuq
-- Fixes: portal_stores_store_name_check blocking store_name = 'photos' / 'accountData' / 'systemBackup'
-- Also creates Storage bucket teacher-photos + anon policies
-- Safe to re-run.
-- ═══════════════════════════════════════════════════════════

-- 1) Widen CHECK to match PORTAL_STORE_IDS (+ systemBackup archive)
alter table public.portal_stores drop constraint if exists portal_stores_store_name_check;
alter table public.portal_stores add constraint portal_stores_store_name_check
  check (store_name in (
    'daySchedules', 'schedChanges', 'roomTt', 'classCancels',
    'headOrders', 'orderAcks', 'sharedNotes', 'sharedNoteStudents',
    'leaveRequests', 'directorTodos', 'schoolFinance', 'dormStudents',
    'studyPauses', 'waitlist', 'textbooks', 'jobApps', 'attendance',
    'studentEdits', 'helpChats', 'partTime', 'otReports', 'photos',
    'accountData', 'systemBackup'
  ));

-- 2) Public Storage bucket for profile JPEGs
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'teacher-photos',
  'teacher-photos',
  true,
  5242880, -- 5 MB
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- 3) Storage RLS — same trust model as portal_stores (anon R/W)
drop policy if exists teacher_photos_anon_select on storage.objects;
create policy teacher_photos_anon_select on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'teacher-photos');

drop policy if exists teacher_photos_anon_insert on storage.objects;
create policy teacher_photos_anon_insert on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'teacher-photos');

drop policy if exists teacher_photos_anon_update on storage.objects;
create policy teacher_photos_anon_update on storage.objects
  for update to anon, authenticated
  using (bucket_id = 'teacher-photos')
  with check (bucket_id = 'teacher-photos');

drop policy if exists teacher_photos_anon_delete on storage.objects;
create policy teacher_photos_anon_delete on storage.objects
  for delete to anon, authenticated
  using (bucket_id = 'teacher-photos');

-- 4) Realtime publication (no-op if already added)
do $$
begin
  begin
    alter publication supabase_realtime add table public.portal_stores;
  exception
    when duplicate_object then null;
    when undefined_object then null;
  end;
end $$;
