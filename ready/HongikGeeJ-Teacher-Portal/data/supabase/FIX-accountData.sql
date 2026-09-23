-- ═══════════════════════════════════════════════════════════
-- COPY-PASTE into Supabase SQL Editor → Run (once)
-- Allows portal store_name = 'accountData' (emergency / personal
-- overrides: hongik-account-data-v2 ↔ portal accountData).
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
