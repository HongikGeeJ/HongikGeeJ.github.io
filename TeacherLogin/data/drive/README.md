# Hongik Drive sync

โฟลเดอร์ Drive ที่เชื่อมกับพอร์ทัล:

https://drive.google.com/drive/folders/1PyqEMeBcTtEujY5qbJTBrg4FzMsMdVDA

## วิธีใช้

1. อัปโหลดไฟล์ JSON / รูป / เอกสารไปที่โฟลเดอร์ Drive ด้านบน (แชร์เป็น Anyone with the link ถ้าต้องการดึงอัตโนมัติ)
2. อัปเดต `manifest.json` ให้ชี้ `id` ของไฟล์ Drive หรือ `localPath` ในโปรเจกต์นี้
3. ในเว็บ → แท็บตารางห้องเรียน → กด **Sync Drive**

## Google API key (ทางเลือก)

ถ้าต้องการให้เว็บดึงรายการไฟล์จากโฟลเดอร์อัตโนมัติ:

1. สร้าง API key ที่เปิด Google Drive API
2. ในเว็บ เปิด Console แล้วรัน: `localStorage.setItem('hongik-drive-api-key', 'YOUR_KEY')`
3. กด Sync Drive อีกครั้ง

## โฟลเดอร์ในโปรเจกต์

- `data/archives/` — สำรองตารางรายเดือน (JSON)
- `data/images/` — รูป/สแกนตาราง
- `data/drive/manifest.json` — รายการไฟล์ที่ซิงก์เข้าเว็บ
