# Gemini help-chat proxy

พอร์ทัล (`#help-fab` → แท็บ **AI ช่วยเหลือ**) ถาม–ตอบผ่าน **Google Gemini**  
คีย์ API **ไม่ใส่ใน HTML** — เก็บใน Apps Script Script Properties แล้วให้เว็บเรียก proxy เท่านั้น

Checklist สั้นสำหรับผู้ใช้ (ภาษาไทย): [`data/gemini/README-proxy.md`](../../data/gemini/README-proxy.md)

## ตั้งค่าครั้งเดียว

1. เปิด [Google AI Studio](https://aistudio.google.com/apikey) → สร้าง API key **ของคุณเอง** (อย่า commit คีย์ลง git)  
2. เปิด [script.google.com](https://script.google.com) → **New project** (หรือโปรเจกต์ gemini-proxy เดิม)  
3. วางโค้ดจาก `Code.gs` ในโฟลเดอร์นี้  
4. **Project Settings → Script properties**  
   | Property | Value |
   |----------|--------|
   | `GEMINI_API_KEY` | คีย์จาก AI Studio (วางที่นี่เท่านั้น) |
   | `GEMINI_MODEL` | (ไม่บังคับ) ค่าเริ่มต้น `gemini-2.0-flash` — เปลี่ยนเป็น `gemini-1.5-flash` ได้ถ้าต้องการ |
5. **Deploy → New deployment → Web app** (หรือ Manage deployments → Edit → **New version**)  
   - Execute as: **Me**  
   - Who has access: **Anyone** ← ถ้าไม่ใช่ Anyone แชทจะล้มทุกครั้ง  
6. คัดลอก URL แบบ `https://script.google.com/macros/s/XXXX/exec`  
7. ใส่ URL อย่างใดอย่างหนึ่ง:
   - `data/gemini/gemini-config.json` → `"proxyUrl"`
   - หรือใน HTML ด้านบนสคริปต์: `const DEFAULT_GEMINI_PROXY_URL = '...'`

```json
{
  "version": 1,
  "proxyUrl": "https://script.google.com/macros/s/XXXX/exec",
  "model": "gemini-2.0-flash"
}
```

8. เปิด URL จากข้อ 6 ในเบราว์เซอร์ — ต้องได้ JSON `{ "ok": true, "service": "hongik-gemini-proxy", "hasKey": true }`  
   ถ้าไปหน้า Login = ยังไม่ใช่ Anyone → กลับข้อ 5  
9. commit + push (GitHub Pages) แล้ว **hard refresh** พอร์ทัล (Cmd/Ctrl+Shift+R)

### ทดสอบเครื่องเดียว (ไม่ต้อง push)

ใน Console ของพอร์ทัล:

```js
hongikSetGeminiProxyUrl('https://script.google.com/macros/s/XXXX/exec')
hongikGeminiStatus()
```

## ความปลอดภัย

- **อย่า** commit คีย์ API ใน repo / HTML  
- ไคลเอนต์เรียก **เฉพาะ proxy** (POST `action: 'geminiChat'`) — ไม่มี API key ในเบราว์เซอร์

## แยกจากซิงก์อื่น

โปรเจกต์นี้เป็น Web App **แยก** จาก `data/photos/apps-script` และ `apps-script/Code.gs` (schedule/อื่นๆ)  
ไม่แก้ endpoint รูปหรือตาราง — deploy คนละ deployment ได้

## แก้เมื่อขึ้น「เชื่อมต่อ Gemini ไม่ได้」

สาเหตุที่พบบ่อย: **Web App ยังไม่เปิด Anyone** (ทดสอบแล้ว GET ไปหน้า login / POST ได้ 401 「ไม่พบเพจ」)

1. เปิดโปรเจกต์ Apps Script ของ gemini-proxy
2. **Project Settings → Script properties** → มี `GEMINI_API_KEY`
3. **Deploy → Manage deployments → ✎ Edit**
   - Version: **New version**
   - Execute as: **Me**
   - Who has access: **Anyone** (ไม่ใช่ Only myself)
4. Deploy แล้วคัดลอก URL `/exec` ใหม่ (ถ้าเปลี่ยน) ใส่ใน `data/gemini/gemini-config.json` และ `DEFAULT_GEMINI_PROXY_URL`
5. Hard-refresh พอร์ทัล (Ctrl/Cmd+Shift+R)
6. ใน Console: `await hongikGeminiPing()` ควรได้ `{ ok: true, data: { service: "hongik-gemini-proxy", hasKey: true } }`

ไคลเอนต์ส่ง `Content-Type: text/plain` + JSON body — **ห้าม**ใช้ `application/json` (CORS preflight จะพัง)

