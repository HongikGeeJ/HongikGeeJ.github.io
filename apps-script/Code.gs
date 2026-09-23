/**
 * Same portal sync Web App as data/photos/apps-script/Code.gs
 * Keep both copies identical when editing.
 *
 * Hongik GeeJ — Central portal sync via Google Apps Script Web App
 *
 * Deploy (once):
 * 1. script.google.com → New project → paste this file
 * 2. Deploy → New deployment → Web app
 *    - Execute as: Me
 *    - Who has access: Anyone
 * 3. Copy the /macros/s/.../exec URL
 * 4. Put it in data/photos/sync-config.json → "syncUrl", then commit + push Pages
 *    OR Console: hongikSetPortalSyncUrl('URL')
 *
 * API:
 *  GET  → {
 *    version, updatedAt,
 *    photos: { [userId]: { dataUrl, updatedAt } },
 *    stores: { [storeName]: { updatedAt, data } }
 *  }
 *  POST text/plain JSON:
 *    { action: 'set', userId, dataUrl, updatedAt }           // photos (legacy)
 *    { action: 'bulk', photos: { id: { dataUrl, updatedAt } } }
 *    { action: 'putStore', store: '<name>', data, updatedAt }
 *    { action: 'putStores', stores: { name: { data, updatedAt }, ... } }
 *
 * Never store passwords or API keys here.
 */

var FILE_NAME = 'hongik-teacher-photos.json';
var STORE_KEYS = {
  daySchedules: true,
  schedChanges: true,
  roomTt: true,
  classCancels: true,
  headOrders: true,
  orderAcks: true,
  sharedNotes: true,
  sharedNoteStudents: true,
  leaveRequests: true,
  directorTodos: true,
  schoolFinance: true,
  dormStudents: true,
  studyPauses: true,
  waitlist: true,
  textbooks: true,
  jobApps: true,
  attendance: true,
  studentEdits: true,
  helpChats: true,
  partTime: true,
  otReports: true,
  photos: true,
  accountData: true
};

function getStore_() {
  var files = DriveApp.getFilesByName(FILE_NAME);
  var file = files.hasNext()
    ? files.next()
    : DriveApp.createFile(FILE_NAME, '{"version":1,"photos":{},"stores":{}}', MimeType.PLAIN_TEXT);
  var data = {};
  try {
    data = JSON.parse(file.getBlob().getDataAsString() || '{}');
  } catch (e) {
    data = { version: 1, photos: {}, stores: {} };
  }
  if (!data.photos || typeof data.photos !== 'object') data.photos = {};
  if (!data.stores || typeof data.stores !== 'object') data.stores = {};
  if (!data.version) data.version = 1;
  return { file: file, data: data };
}

function saveStore_(file, data) {
  data.version = data.version || 1;
  data.updatedAt = new Date().toISOString();
  if (!data.stores || typeof data.stores !== 'object') data.stores = {};
  file.setContent(JSON.stringify(data));
}

function upsertPhoto_(photos, userId, dataUrl, updatedAt) {
  var incomingAt = String(updatedAt || new Date().toISOString());
  if (!dataUrl) {
    delete photos[userId];
    return true;
  }
  var existing = photos[userId];
  if (existing && existing.updatedAt && String(existing.updatedAt) > incomingAt) {
    return false;
  }
  photos[userId] = {
    dataUrl: String(dataUrl),
    updatedAt: incomingAt
  };
  return true;
}

function putNamedStore_(stores, name, payload, updatedAt) {
  if (!STORE_KEYS[name]) return false;
  var incomingAt = String(updatedAt || new Date().toISOString());
  var existing = stores[name];
  if (existing && existing.updatedAt && String(existing.updatedAt) > incomingAt) {
    return false;
  }
  stores[name] = {
    updatedAt: incomingAt,
    data: payload == null ? null : payload
  };
  return true;
}

function doGet() {
  var s = getStore_();
  return ContentService.createTextOutput(JSON.stringify(s.data))
    .setMimeType(ContentService.MimeType.JSON);
}

function doPost(e) {
  var body = {};
  try {
    body = JSON.parse((e && e.postData && e.postData.contents) || '{}');
  } catch (err) {
    body = {};
  }
  var s = getStore_();
  var changed = false;

  if (body.action === 'set' && body.userId) {
    changed = upsertPhoto_(s.data.photos, String(body.userId), body.dataUrl || '', body.updatedAt) || changed;
  } else if (body.action === 'bulk' && body.photos && typeof body.photos === 'object') {
    Object.keys(body.photos).forEach(function (id) {
      var entry = body.photos[id];
      var dataUrl = entry && typeof entry === 'object' ? entry.dataUrl : entry;
      var at = entry && typeof entry === 'object' ? entry.updatedAt : '';
      if (upsertPhoto_(s.data.photos, String(id), dataUrl || '', at)) changed = true;
    });
  } else if (body.action === 'putStore' && body.store) {
    changed = putNamedStore_(s.data.stores, String(body.store), body.data, body.updatedAt) || changed;
  } else if (body.action === 'putStores' && body.stores && typeof body.stores === 'object') {
    Object.keys(body.stores).forEach(function (name) {
      var entry = body.stores[name];
      var payload = entry && typeof entry === 'object' && 'data' in entry ? entry.data : entry;
      var at = entry && typeof entry === 'object' ? entry.updatedAt : '';
      if (putNamedStore_(s.data.stores, String(name), payload, at)) changed = true;
    });
  }

  if (changed) saveStore_(s.file, s.data);
  return ContentService.createTextOutput(JSON.stringify(s.data))
    .setMimeType(ContentService.MimeType.JSON);
}
