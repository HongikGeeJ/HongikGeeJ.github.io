# Hongik data store

พื้นที่เก็บข้อมูลในเครื่องสำหรับพอร์ทัลครู

| โฟลเดอร์ | ใช้ทำอะไร |
|----------|-----------|
| `archives/` | สำรองตารางห้องเรียนรายเดือน (JSON) |
| `drive/` | `manifest.json` ชี้ไฟล์จาก Google Drive |
| `images/` | รูปสแกนตาราง / ไฟล์ภาพอื่น ๆ |
| `photos/` | รูปโปรไฟล์ครู + **Apps Script central sync** (รูป + ข้อมูลร่วมทั้งพอร์ทัล) |

Drive โฟลเดอร์หลัก: https://drive.google.com/drive/folders/1PyqEMeBcTtEujY5qbJTBrg4FzMsMdVDA

ในแท็บ **ตารางห้องเรียน** กด **ซิงก์ Drive** เพื่อดึงจาก `drive/manifest.json` (และ Drive API ถ้าใส่ API key)

## ซิงก์ข้ามเครื่อง (central portal sync)

GitHub Pages เขียนไฟล์ใน repo ไม่ได้ — ต้องมี Apps Script Web App URL กลาง  
ถ้า `syncUrl` ว่าง พอร์ทัลทำงานแบบ local-only ตามปกติ (ไม่พัง)

1. เปิด [script.google.com](https://script.google.com) → New project  
2. วางโค้ดจาก `apps-script/Code.gs` (หรือ `photos/apps-script/Code.gs` — ไฟล์เดียวกัน)  
3. **Deploy → New deployment → Web app** · Execute as: **Me** · Who has access: **Anyone**  
4. คัดลอก URL แบบ `https://script.google.com/macros/s/XXXX/exec`  
5. ใส่ใน `photos/sync-config.json`:

```json
{
  "version": 1,
  "syncUrl": "https://script.google.com/macros/s/XXXX/exec"
}
```

6. **git commit + push** → ทุกเครื่องที่เปิด Pages จะดึง URL นี้เอง  
7. รีเฟรชพอร์ทัล · ครูเพิ่ม/แก้ข้อมูล → เครื่องอื่นเห็นภายใน ~15 วินาที

ทางลัดทดสอบเครื่องเดียว (Console):

```js
hongikSetPortalSyncUrl('https://script.google.com/macros/s/XXXX/exec')
hongikPortalSyncStatus()
hongikSyncPortalNow()
hongikPushPortalNow()
```

### ซิงก์อะไรบ้าง (ผ่าน URL เดียวกัน)

| store | ใช้ทำอะไร |
|-------|-----------|
| `photos` | รูปโปรไฟล์ครู (API แยกใน payload เดียวกัน) |
| `daySchedules` | ตารางสอน/งานวันนี้ของครู |
| `schedChanges` | กล่องแจ้งหัวหน้าเมื่อเพิ่ม/แก้/ลบคลาส |
| `roomTt` | ตารางห้องเรียน |
| `classCancels` | แจ้งยกเลิกคลาส |
| `headOrders` | คำสั่งหัวหน้า + acks ในแถว |
| `orderAcks` | กระจก ack ข้ามบัญชี |
| `sharedNotes` / `sharedNoteStudents` | บันทึกร่วมครู |
| `leaveRequests` | ลา |
| `directorTodos` | แผนหัวหน้า |
| `schoolFinance` | การเงินโรงเรียน |
| `dormStudents` | หอพัก |
| `studyPauses` | พักเรียน |
| `waitlist` | รอสนใจ |
| `textbooks` | สต็อกหนังสือ |
| `jobApps` | สมัครงานครู |
| `attendance` | เช็คชื่อ (local marks) |
| `studentEdits` | แก้ชื่อ/โน้ตนักเรียนในพอร์ทัล |
| `helpChats` | แชทช่วยเหลือหัวหน้า |
| `partTime` | พาร์ทไทม์ |

### ไม่ซิงก์ (ตั้งใจ)

รหัสผ่าน, API keys (Drive/Gemini), session/ภาษา, student/sales DB จาก Sheet (มีช่องทางอ่าน Sheet อยู่แล้ว)

รายละเอียดเพิ่ม: ดู `photos/README.md`
