-- Hongik GeeJ — teacher job application files (one-time)
-- Run in: Supabase Dashboard → SQL Editor → New query → Run
-- Requires: schema.sql already applied (portal_stores + RLS).
-- Safe to re-run.
-- jobApps metadata already allowed in portal_stores_store_name_check.

-- 1) Public Storage bucket for application PDFs / docs / images
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'teacher-job-apps',
  'teacher-job-apps',
  true,
  10485760, -- 10 MB
  array[
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'image/jpeg',
    'image/png',
    'image/webp'
  ]
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- 2) RLS on storage.objects — same trust model as teacher-photos (anon R/W)
drop policy if exists teacher_job_apps_anon_select on storage.objects;
create policy teacher_job_apps_anon_select on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'teacher-job-apps');

drop policy if exists teacher_job_apps_anon_insert on storage.objects;
create policy teacher_job_apps_anon_insert on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'teacher-job-apps');

drop policy if exists teacher_job_apps_anon_update on storage.objects;
create policy teacher_job_apps_anon_update on storage.objects
  for update to anon, authenticated
  using (bucket_id = 'teacher-job-apps')
  with check (bucket_id = 'teacher-job-apps');

drop policy if exists teacher_job_apps_anon_delete on storage.objects;
create policy teacher_job_apps_anon_delete on storage.objects
  for delete to anon, authenticated
  using (bucket_id = 'teacher-job-apps');
