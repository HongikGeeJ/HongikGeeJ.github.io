-- ═══════════════════════════════════════════════════════════
-- COPY-PASTE into Supabase SQL Editor → Run (once)
-- Allows portal store_name = 'systemBackup' (rotating auto
-- backups every 20 minutes; no passwords; photo URL refs).
-- Safe to re-run.
-- ═══════════════════════════════════════════════════════════

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
