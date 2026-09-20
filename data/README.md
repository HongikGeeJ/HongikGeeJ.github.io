# Hongik data store

พื้นที่เก็บข้อมูลในเครื่องสำหรับพอร์ทัลครู

| โฟลเดอร์ | ใช้ทำอะไร |
|----------|-----------|
| `archives/` | สำรองตารางห้องเรียนรายเดือน (JSON) |
| `drive/` | `manifest.json` ชี้ไฟล์จาก Google Drive |
| `images/` | รูปสแกนตาราง / ไฟล์ภาพอื่น ๆ |

Drive โฟลเดอร์หลัก: https://drive.google.com/drive/folders/1PyqEMeBcTtEujY5qbJTBrg4FzMsMdVDA

ในแท็บ **ตารางห้องเรียน** กด **ซิงก์ Drive** เพื่อดึงจาก `drive/manifest.json` (และ Drive API ถ้าใส่ API key)
