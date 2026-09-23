# Gemini proxy — สิ่งที่ต้องทำเองใน Google Apps Script

ถ้าแชท AI ขึ้น「เชื่อมต่อ Gemini ไม่ได้」+「คำตอบสำรองจากคู่มือในเครื่อง」  
**สาเหตุที่พบบ่อย:** Web App ยังไม่เปิด **Anyone** (เปิด URL แล้วไปหน้า Login / POST ได้ 401)

คีย์ API **ห้ามใส่ใน repo** — วางเฉพาะใน Script Properties

---

## Checklist (ทำตามลำดับ)

1. เปิด [Google AI Studio](https://aistudio.google.com/apikey) → **Create API key** → คัดลอกคีย์ของคุณ
2. เปิด [script.google.com](https://script.google.com) → โปรเจกต์ **gemini-proxy** (หรือ New project แล้ววางโค้ดจาก `apps-script/gemini-proxy/Code.gs`)
3. **Project Settings** (ไอคอนเฟือง) → **Script properties** → **Add script property**
   - Property: `GEMINI_API_KEY`
   - Value: วางคีย์จากขั้นตอน 1 (คีย์ของคุณเองเท่านั้น)
   - (ไม่บังคับ) `GEMINI_MODEL` = `gemini-2.0-flash`
4. **Deploy → Manage deployments → ✎ Edit**
   - Version: **New version**
   - Execute as: **Me**
   - Who has access: **Anyone** ← สำคัญมาก (อย่าเลือก Only myself)
5. กด **Deploy** แล้วคัดลอก Web App URL แบบ  
   `https://script.google.com/macros/s/XXXX/exec`
6. ตรวจว่า URL ตรงกับในพอร์ทัล (`data/gemini/gemini-config.json` → `proxyUrl`)  
   ถ้า URL เปลี่ยนหลัง redeploy ให้อัปเดตไฟล์แล้ว push / หรือใน Console:  
   `hongikSetGeminiProxyUrl('https://script.google.com/macros/s/XXXX/exec')`
7. เปิด URL จากข้อ 5 ในแท็บใหม่ (ไม่ได้ล็อกอินก็ได้)  
   ต้องเห็น JSON ประมาณ `{ "ok": true, "service": "hongik-gemini-proxy", "hasKey": true }`  
   ถ้าขึ้นหน้า Login ของ Google = ยังไม่ใช่ **Anyone** → กลับไปข้อ 4
8. Hard refresh พอร์ทัล (**Cmd+Shift+R** / **Ctrl+Shift+R**) → เปิด Help → AI → พิมพ์「สวัสดี」อีกครั้ง  
   หรือใน Console: `await hongikGeminiPing()` ควรได้ `ok: true` และ `hasKey: true`

---

รายละเอียดเต็ม: [`apps-script/gemini-proxy/README.md`](../../apps-script/gemini-proxy/README.md)
