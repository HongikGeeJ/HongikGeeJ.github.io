# Gemini help-chat proxy

พอร์ทัล (`#help-fab` → แท็บ **AI ช่วยเหลือ**) ถาม–ตอบผ่าน **Google Gemini**  
คีย์ API **ไม่ใส่ใน HTML** — เก็บใน Apps Script Script Properties แล้วให้เว็บเรียก proxy

## ตั้งค่าครั้งเดียว

1. เปิด [Google AI Studio](https://aistudio.google.com/apikey) → สร้าง API key  
2. เปิด [script.google.com](https://script.google.com) → **New project**  
3. วางโค้ดจาก `Code.gs` ในโฟลเดอร์นี้  
4. **Project Settings → Script properties**  
   | Property | Value |
   |----------|--------|
   | `GEMINI_API_KEY` | คีย์จาก AI Studio |
   | `GEMINI_MODEL` | (ไม่บังคับ) ค่าเริ่มต้น `gemini-2.0-flash` — เปลี่ยนเป็น `gemini-1.5-flash` ได้ถ้าต้องการ |
5. **Deploy → New deployment → Web app**  
   - Execute as: **Me**  
   - Who has access: **Anyone**  
6. คัดลอก URL แบบ `https://script.google.com/macros/s/XXXX/exec`  
7. ใส่ใน `data/gemini/gemini-config.json`:

```json
{
  "version": 1,
  "proxyUrl": "https://script.google.com/macros/s/XXXX/exec",
  "model": "gemini-2.0-flash"
}
```

8. commit + push (GitHub Pages) แล้วรีเฟรชพอร์ทัล

### ทดสอบเครื่องเดียว (ไม่ต้อง push)

ใน Console ของพอร์ทัล:

```js
hongikSetGeminiProxyUrl('https://script.google.com/macros/s/XXXX/exec')
hongikGeminiStatus()
```

## ความปลอดภัย

- **อย่า** commit คีย์ API ใน repo / HTML  
- ทางเลือกชั่วคราวสำหรับทดสอบเท่านั้น:  
  `localStorage.setItem('hongik-gemini-api-key', 'YOUR_KEY')`  
  (เรียก Gemini จากเบราว์เซอร์ตรง ๆ — คีย์โผล่ในเครื่องนั้น อย่าใช้บนเครื่องสาธารณะ)

## แยกจากซิงก์อื่น

โปรเจกต์นี้เป็น Web App **แยก** จาก `data/photos/apps-script` และ `apps-script/Code.gs` (schedule/อื่นๆ)  
ไม่แก้ endpoint รูปหรือตาราง — deploy คนละ deployment ได้
