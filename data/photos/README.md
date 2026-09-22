# ซิงก์พอร์ทัลกลาง (central sync)

พอร์ทัลเก็บข้อมูลใน `localStorage` บนเครื่องนั้น ๆ  
**GitHub Pages เป็น static — เบราว์เซอร์เขียนไฟล์ใน repo ไม่ได้** จึงต้องมี backend เขียนได้

**แนะนำ: Supabase** (ตั้งค่าแล้วใน `data/supabase/supabase-config.json`) — รูปโปรไฟล์ขึ้น Storage + `portal_stores.photos`  
ดูขั้นตอน SQL ครั้งเดียว: `data/supabase/storage-photos.sql` และ `data/supabase/README.md`

ทางเลือกสำรอง: Apps Script Web App (`syncUrl`) ด้านล่าง

ถ้ายังไม่มี **Supabase หรือ sync URL** → บันทึกบนเครื่องนั้นเท่านั้น (graceful degrade) · ไม่ error

## ชั้นการทำงาน

| ชั้น | ทำงานอย่างไร |
|------|----------------|
| เครื่องเดียวกัน / แท็บอื่น | ทันที ผ่าน `localStorage` + `:tick` + storage event |
| ข้ามคอมพิวเตอร์ (แนะนำ) | **Supabase** — Storage รูป + Realtime `portal_stores` |
| ข้ามคอมพิวเตอร์ (สำรอง) | Apps Script Web App — POST ตอนบันทึก · GET + poll |
| `photos.json` ใน repo | อ่านอย่างเดียว (seed รูปหลัง deploy) |

## ตั้งค่าซิงก์ข้ามเครื่อง (ทำครั้งเดียว)

1. เปิด [script.google.com](https://script.google.com) → New project  
2. วางโค้ดจาก `apps-script/Code.gs` (รากโปรเจกต์) หรือ `data/photos/apps-script/Code.gs` — ไฟล์เดียวกัน  
3. **Deploy → New deployment → Web app**  
   - Execute as: **Me**  
   - Who has access: **Anyone**  
4. คัดลอก URL แบบ `https://script.google.com/macros/s/XXXX/exec`  
5. ใส่ URL ใน `sync-config.json`:

```json
{
  "version": 1,
  "syncUrl": "https://script.google.com/macros/s/XXXX/exec"
}
```

6. **git commit + push** ไป GitHub Pages  
7. รีเฟรชพอร์ทัล → ครูเพิ่ม/แก้ → เครื่องอื่นเห็นภายใน ~15 วินาที

### ทางลัดทดสอบบนเครื่องเดียว

```js
hongikSetPortalSyncUrl('https://script.google.com/macros/s/XXXX/exec')
// alias เดิม: hongikSetPhotosSyncUrl('...')
hongikPortalSyncStatus()
hongikSyncPortalNow()   // pull + merge
hongikPushPortalNow()   // push ทุก store จากเครื่องนี้
```

หรือ:

```js
localStorage.setItem('hongik-photos-sync-url', 'https://script.google.com/macros/s/XXXX/exec')
```

### ตรวจสถานะ

```js
hongikPhotosSyncStatus()
hongikPortalSyncStatus()
```

`hongikPortalSyncStatus()` แสดง `url`, `status` (`ok` / `local-only` / `error`), `stores`, `pending`, `pollMs`

## ข้อมูลที่ซิงก์

รูป (`photos`) + stores: ตารางงาน, แจ้งหัวหน้า, ตารางห้อง, ยกเลิกคลาส, คำสั่ง/ack, บันทึกร่วม, ลา, todos, การเงิน, หอ, พักเรียน, waitlist, หนังสือ, สมัครงาน, attendance, student edits, help chat, part-time  

ดูตารางเต็มใน `data/README.md`

**ไม่ใส่ secrets ใน repo** — รหัสผ่าน / API key อยู่แค่ localStorage ของเครื่อง

## ทางเลือก: seed รูปผ่าน `photos.json` (ไม่มี Apps Script)

1. บนเครื่องที่มีรูป รันใน Console: `hongikDownloadPhotosJson()`  
2. แทนที่ `data/photos/photos.json` ด้วยไฟล์ที่ดาวน์โหลด  
3. **commit + push** → หลัง Pages deploy เครื่องอื่นจะดึงรูปตอนโหลด  
4. ข้อจำกัด: ข้อมูลอื่น **ไม่** ซิงก์ด้วยวิธีนี้ — ต้องมี Apps Script

## Toast ในแอป (รูป)

| สถานการณ์ | ข้อความ |
|-----------|---------|
| มี sync URL + POST สำเร็จ | ซิงก์ขึ้นคลาวด์แล้ว |
| ไม่มี sync URL | บันทึกบนเครื่องนี้เท่านั้น |
| มี URL แต่ POST ล้มเหลว | บันทึกในเครื่องแล้ว แต่ซิงก์คลาวด์ล้มเหลว |

## ไฟล์ในโฟลเดอร์นี้

| ไฟล์ | หน้าที่ |
|------|---------|
| `photos.json` | seed รูปอ่านอย่างเดียวบน Pages |
| `sync-config.json` | URL กลางที่ทุกเครื่องดึงหลัง deploy (`syncUrl` ว่าง = local-only) |
| `apps-script/Code.gs` | Web App เขียน/อ่านรูป + stores บน Drive |
