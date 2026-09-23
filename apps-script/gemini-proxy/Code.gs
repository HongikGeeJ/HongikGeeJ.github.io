/**
 * Hongik GeeJ — Gemini help-chat proxy (Google Apps Script Web App)
 *
 * Keeps the Gemini API key server-side (Script Properties). The portal POSTs
 * questions here; this script calls generativelanguage.googleapis.com.
 *
 * Setup:
 * 1. script.google.com → New project → paste this file
 * 2. Project Settings → Script properties:
 *      GEMINI_API_KEY = <your key from Google AI Studio>
 *      GEMINI_MODEL   = gemini-2.0-flash   (optional; default below)
 * 3. Deploy → New deployment → Web app
 *      Execute as: Me
 *      Who has access: Anyone   ← required (anonymous GET/POST from GitHub Pages)
 *      If GET redirects to Google login or POST returns 401 / "ไม่พบเพจ",
 *      access is NOT Anyone — Manage deployments → Edit → New version → Anyone.
 * 4. Put the /macros/s/.../exec URL in data/gemini/gemini-config.json → "proxyUrl"
 *    OR embed DEFAULT_GEMINI_PROXY_URL in TeacherLogin/index.html
 *    OR Console: hongikSetGeminiProxyUrl('URL')
 *
 * API (client must POST Content-Type: text/plain with JSON body — avoids CORS preflight):
 *  GET  → { ok, service, model, hasKey }
 *  POST text/plain JSON:
 *    { action: 'geminiChat', message, history?, lang?, systemHint?, role?, roleGuide? }
 *    → { ok: true, text, model } | { ok: false, error }
 *
 * Do NOT put GEMINI_API_KEY in the HTML repo.
 */

var DEFAULT_MODEL = 'gemini-2.0-flash';

function getProp_(key, fallback) {
  var v = PropertiesService.getScriptProperties().getProperty(key);
  return v && String(v).trim() ? String(v).trim() : (fallback || '');
}

function jsonOut_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

function parseBody_(e) {
  try {
    var raw = (e && e.postData && e.postData.contents) || '';
    if (!raw && e && e.parameter && e.parameter.payload) {
      raw = String(e.parameter.payload);
    }
    return JSON.parse(raw || '{}');
  } catch (err) {
    return {};
  }
}

function buildSystemPrompt_(body) {
  var lang = String(body.lang || 'th');
  var langName = lang === 'en' ? 'English' : lang === 'ko' ? 'Korean' : 'Thai';
  var role = String(body.role || '');
  var roleGuide = String(body.roleGuide || '');
  var extra = String(body.systemHint || '');
  var parts = [
    'You are the Hongik GeeJ teacher portal assistant (Gemini).',
    'Help staff use the school portal: room booking, leave, cancel class, students, OT, passwords, messaging the head/director.',
    'Answer in ' + langName + ' unless the user clearly writes in another language.',
    'Be concise (short bullet steps). Respect account permissions — do not invent privileges.',
    'If unsure, suggest the in-app tabs or messaging the head (ถึงหัวหน้า).',
    'Do not ask for or reveal passwords/API keys. Do not claim you can change live data yourself.'
  ];
  if (role) parts.push('Current user role: ' + role + '.');
  if (roleGuide) parts.push('Role guide for this account:\n' + roleGuide);
  if (extra) parts.push(extra);
  return parts.join('\n');
}

function toGeminiContents_(body) {
  var contents = [];
  var history = Array.isArray(body.history) ? body.history : [];
  history.slice(-8).forEach(function (m) {
    if (!m || !m.text) return;
    var role = m.kind === 'me' || m.role === 'user' ? 'user' : 'model';
    contents.push({
      role: role,
      parts: [{ text: String(m.text).slice(0, 4000) }]
    });
  });
  var message = String(body.message || body.text || '').trim();
  if (message) {
    contents.push({ role: 'user', parts: [{ text: message.slice(0, 4000) }] });
  }
  return contents;
}

function callGemini_(body) {
  var apiKey = getProp_('GEMINI_API_KEY', '');
  if (!apiKey) {
    return { ok: false, error: 'missing_api_key' };
  }
  var model = getProp_('GEMINI_MODEL', DEFAULT_MODEL) || DEFAULT_MODEL;
  var contents = toGeminiContents_(body);
  if (!contents.length) {
    return { ok: false, error: 'empty_message' };
  }
  var url =
    'https://generativelanguage.googleapis.com/v1beta/models/' +
    encodeURIComponent(model) +
    ':generateContent?key=' +
    encodeURIComponent(apiKey);
  var payload = {
    systemInstruction: { parts: [{ text: buildSystemPrompt_(body) }] },
    contents: contents,
    generationConfig: {
      temperature: 0.4,
      maxOutputTokens: 1024
    }
  };
  var res = UrlFetchApp.fetch(url, {
    method: 'post',
    contentType: 'application/json',
    muteHttpExceptions: true,
    payload: JSON.stringify(payload)
  });
  var code = res.getResponseCode();
  var raw = res.getContentText() || '';
  var data = {};
  try {
    data = JSON.parse(raw);
  } catch (err) {
    data = {};
  }
  if (code < 200 || code >= 300) {
    var msg =
      (data.error && data.error.message) ||
      ('HTTP ' + code);
    return { ok: false, error: String(msg).slice(0, 300), model: model };
  }
  var text = '';
  try {
    var cand = data.candidates && data.candidates[0];
    var parts = cand && cand.content && cand.content.parts;
    if (parts && parts.length) {
      text = parts
        .map(function (p) {
          return p && p.text ? String(p.text) : '';
        })
        .join('')
        .trim();
    }
  } catch (err2) {
    text = '';
  }
  if (!text) {
    return { ok: false, error: 'empty_response', model: model };
  }
  return { ok: true, text: text, model: model };
}

function doGet(e) {
  var ping = e && e.parameter && String(e.parameter.action || '') === 'ping';
  return jsonOut_({
    ok: true,
    service: 'hongik-gemini-proxy',
    model: getProp_('GEMINI_MODEL', DEFAULT_MODEL) || DEFAULT_MODEL,
    hasKey: !!getProp_('GEMINI_API_KEY', ''),
    ping: !!ping
  });
}

function doPost(e) {
  var body = parseBody_(e);
  var action = String(body.action || 'geminiChat');
  if (action === 'ping' || action === 'status') {
    return doGet(e);
  }
  if (action === 'geminiChat' || action === 'chat') {
    return jsonOut_(callGemini_(body));
  }
  return jsonOut_({ ok: false, error: 'unknown_action' });
}
