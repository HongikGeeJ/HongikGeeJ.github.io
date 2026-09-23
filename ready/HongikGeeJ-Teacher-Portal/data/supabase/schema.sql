-- Hongik GeeJ Teacher Portal — Supabase schema
-- Run once in: Supabase Dashboard → SQL Editor → New query → Run
-- Safe to re-run (IF NOT EXISTS / OR REPLACE).

-- ═══════════════════════════════════════════════════════════
-- 1) Mirror of Apps Script portal stores (JSON blobs, LWW)
--    Used by the browser for push / pull / Realtime sync.
-- ═══════════════════════════════════════════════════════════

create table if not exists public.portal_stores (
  store_name text primary key
    check (store_name in (
      'daySchedules', 'schedChanges', 'roomTt', 'classCancels',
      'headOrders', 'orderAcks', 'sharedNotes', 'sharedNoteStudents',
      'leaveRequests', 'directorTodos', 'schoolFinance', 'dormStudents',
      'studyPauses', 'waitlist', 'textbooks', 'jobApps', 'attendance',
      'studentEdits', 'helpChats', 'partTime', 'otReports', 'photos',
      'accountData', 'systemBackup'
    )),
  data jsonb,
  updated_at timestamptz not null default now()
);

-- If portal_stores already existed without 'photos', widen the check (safe to re-run):
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

comment on table public.portal_stores is
  'LWW JSON blobs mirroring Apps Script STORE_KEYS — primary realtime sync surface.';

create or replace function public.upsert_portal_store(
  p_name text,
  p_data jsonb,
  p_updated_at timestamptz default now()
) returns public.portal_stores
language plpgsql
security definer
set search_path = public
as $$
declare
  row public.portal_stores;
  incoming timestamptz := coalesce(p_updated_at, now());
begin
  insert into public.portal_stores as s (store_name, data, updated_at)
  values (p_name, p_data, incoming)
  on conflict (store_name) do update
    set data = excluded.data,
        updated_at = excluded.updated_at
    where s.updated_at is null
       or excluded.updated_at >= s.updated_at
  returning * into row;

  if row.store_name is null then
    select * into row from public.portal_stores where store_name = p_name;
  end if;
  return row;
end;
$$;

-- ═══════════════════════════════════════════════════════════
-- 2) Student learning records (normalized — reports / queries)
-- ═══════════════════════════════════════════════════════════

create table if not exists public.students (
  id text primary key,
  name text not null,
  nickname text,
  subjects text[] default '{}',
  courses text[] default '{}',
  start_date date,
  end_date date,
  comment text,
  meta jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

comment on table public.students is
  'Student roster / profile edits from the portal (studentEdits + sheet-backed ids).';

create table if not exists public.student_learning_records (
  id text primary key,
  student_id text references public.students (id) on delete set null,
  student_name text not null,
  subject text,
  lang text check (lang is null or lang in ('ko', 'en', 'th', 'other')),
  lesson_date date,
  teacher_id text,
  teacher_name text,
  progress_note text,
  homework text,
  attendance_status text,
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists student_learning_records_student_name_idx
  on public.student_learning_records (student_name);
create index if not exists student_learning_records_lesson_date_idx
  on public.student_learning_records (lesson_date desc);
create index if not exists student_learning_records_teacher_id_idx
  on public.student_learning_records (teacher_id);

comment on table public.student_learning_records is
  'Per-lesson learning progress / daily study notes (normalized companion to sharedNotes).';

-- Teaching notes shared across teachers (same payload shape as portal sharedNotes rows)
create table if not exists public.learning_notes (
  id text primary key,
  student_name text,
  lang text,
  body text,
  teacher_id text,
  teacher_name text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz,
  updated_at timestamptz not null default now()
);

create index if not exists learning_notes_updated_at_idx
  on public.learning_notes (updated_at desc);

-- ═══════════════════════════════════════════════════════════
-- 3) Schedules / room booking / attendance (practical mirrors)
-- ═══════════════════════════════════════════════════════════

create table if not exists public.day_schedules (
  id text primary key,              -- teacherId|YYYY-MM-DD
  user_id text not null,
  date_key text not null,           -- YYYY-MM-DD
  items jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

create index if not exists day_schedules_user_date_idx
  on public.day_schedules (user_id, date_key);

create table if not exists public.room_bookings (
  id text primary key,
  room text,
  day_key text,
  start_time text,
  end_time text,
  block jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create index if not exists room_bookings_day_idx
  on public.room_bookings (day_key);

create table if not exists public.attendance_marks (
  id text primary key,              -- subjectKey|YYYY-MM-DD (or portal key)
  subject_key text not null,
  date_key text not null,
  status text,
  marks jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create index if not exists attendance_marks_date_idx
  on public.attendance_marks (date_key);

-- Daily / operational reports (OT, leave, cancel, schedule-change alerts, orders…)
create table if not exists public.daily_reports (
  id text primary key,
  report_type text not null
    check (report_type in (
      'ot', 'leave', 'class_cancel', 'sched_change',
      'head_order', 'job_app', 'other'
    )),
  user_id text,
  status text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz,
  updated_at timestamptz not null default now()
);

create index if not exists daily_reports_type_updated_idx
  on public.daily_reports (report_type, updated_at desc);

-- ═══════════════════════════════════════════════════════════
-- 4) Realtime + open RLS (same trust model as Apps Script "Anyone")
--    Tighten later with auth if needed. Do NOT paste service_role in the browser.
-- ═══════════════════════════════════════════════════════════

alter table public.portal_stores enable row level security;
alter table public.students enable row level security;
alter table public.student_learning_records enable row level security;
alter table public.learning_notes enable row level security;
alter table public.day_schedules enable row level security;
alter table public.room_bookings enable row level security;
alter table public.attendance_marks enable row level security;
alter table public.daily_reports enable row level security;

drop policy if exists portal_stores_anon_all on public.portal_stores;
create policy portal_stores_anon_all on public.portal_stores
  for all to anon, authenticated using (true) with check (true);

drop policy if exists students_anon_all on public.students;
create policy students_anon_all on public.students
  for all to anon, authenticated using (true) with check (true);

drop policy if exists student_learning_records_anon_all on public.student_learning_records;
create policy student_learning_records_anon_all on public.student_learning_records
  for all to anon, authenticated using (true) with check (true);

drop policy if exists learning_notes_anon_all on public.learning_notes;
create policy learning_notes_anon_all on public.learning_notes
  for all to anon, authenticated using (true) with check (true);

drop policy if exists day_schedules_anon_all on public.day_schedules;
create policy day_schedules_anon_all on public.day_schedules
  for all to anon, authenticated using (true) with check (true);

drop policy if exists room_bookings_anon_all on public.room_bookings;
create policy room_bookings_anon_all on public.room_bookings
  for all to anon, authenticated using (true) with check (true);

drop policy if exists attendance_marks_anon_all on public.attendance_marks;
create policy attendance_marks_anon_all on public.attendance_marks
  for all to anon, authenticated using (true) with check (true);

drop policy if exists daily_reports_anon_all on public.daily_reports;
create policy daily_reports_anon_all on public.daily_reports
  for all to anon, authenticated using (true) with check (true);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to anon, authenticated;
grant execute on function public.upsert_portal_store(text, jsonb, timestamptz) to anon, authenticated;

-- Enable Realtime for the blob sync table (Dashboard → Database → Replication also OK)
do $$
begin
  begin
    alter publication supabase_realtime add table public.portal_stores;
  exception
    when duplicate_object then null;
    when undefined_object then null;
  end;
end $$;
