# ตัวอย่าง `#ft` — Feature

โหมด feature ตั้งแต่ GATE 2 (need + scenarios + scope) ถึง slice แรกที่ verified — แสดงการ surface real need, contract, และ offer `#cp` ตอนจบ

---

**User:** `#ft` เพิ่มปุ่ม export CSV ให้หน้ารายงานยอดขาย

**Assistant:**

> #ft | GATE 2 FAIL: scenarios + scope ยังไม่ bound | BLOCKED

ก่อนเขียนต้องผ่าน GATE 2. ขอเคลียร์:
- **Real need:** อยาก export เพื่อเอาไปเปิดใน Excel ทำ pivot เอง ใช่ไหม? ถ้าใช่ "CSV" ถูก — แต่ถ้าต้องการกราฟสำเร็จรูป XLSX อาจตรงกว่า
- **Scope:** รายงานช่วงวันที่ที่ filter อยู่ตอนนั้น หรือทั้งหมด?

**User:** เอาไปทำ pivot เอง CSV พอ. export เฉพาะช่วงที่ filter อยู่

**Assistant:**

> #ft | GATE 2 PASS | STEP 2.2 contract

**Acceptance scenarios:**
1. given filter = ม.ค.–มี.ค., when กดปุ่ม, then ดาวน์โหลด `.csv` เฉพาะแถวในช่วงนั้น
2. given ผลลัพธ์ 0 แถว, when กดปุ่ม, then ได้ไฟล์ที่มีแค่ header row (ไม่ error)
3. given ค่ามี `,` หรือ `"` ในชื่อสินค้า, then escape ตาม RFC 4180 ไม่ทำ column เพี้ยน

**Scope IN:** ปุ่ม + endpoint คืน CSV ของ filter ปัจจุบัน · **OUT:** XLSX, scheduled export, ส่งเข้า email (YAGNI)

**Abuse case (trust boundary = endpoint รับ param):** given attacker ใส่ date range กว้างมากดึงทั้ง DB, then ต้อง cap จำนวนแถว + ใช้ param binding ไม่ string-concat SQL → อ่าน `references/sec.md`

> #ft | GATE 2 PASS | STEP 2.4 slice แรก + verify

slice: endpoint `GET /reports/sales.csv?from&to` คืน CSV ก่อน แล้วค่อยต่อปุ่ม UI

```
VERIFIED:
$ npm test -- export
Tests: 6 passed, 6 total (happy + empty + escape)
$ curl 'localhost:3000/reports/sales.csv?from=2026-01-01&to=2026-03-31'
product,qty,total
"Widget, XL",12,3600
```

slice แรก verified — commit ไหม? พิมพ์ `#cp` (UI ปุ่มเป็น slice ถัดไป)

---

**สิ่งที่ตัวอย่างนี้สอน:** surface real need ก่อน (CSV vs XLSX) · เขียน ≥3 scenario รวม error/edge ก่อนโค้ด · scope OUT สำคัญกว่า IN · endpoint รับ input = abuse case บังคับ · build เป็น slice · offer `#cp` ทีละ slice
