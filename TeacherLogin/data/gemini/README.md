# Gemini AI (help FAB)

แท็บ **AI ช่วยเหลือ** ใน `#help-fab` เรียก Gemini ผ่าน Apps Script proxy เท่านั้น

**สิ่งที่ผู้ใช้ต้องทำใน Apps Script (คัดลอกได้):**  
→ [`README-proxy.md`](./README-proxy.md)

รายละเอียดเทคนิค: [`apps-script/gemini-proxy/README.md`](../../apps-script/gemini-proxy/README.md)

ใส่ `proxyUrl` ได้ที่:
- `gemini-config.json` → `"proxyUrl"` หลัง deploy
- หรือ HTML: `DEFAULT_GEMINI_PROXY_URL` ที่หัวสคริปต์

ไม่ใส่ API key ในไฟล์เหล่านี้ — ใส่เฉพาะ Script property `GEMINI_API_KEY`
