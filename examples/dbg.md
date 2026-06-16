# ตัวอย่าง `#dbg` — Debug

โหมด debug จริง ตั้งแต่ bug report ถึง fix ที่ verified — แสดง GATE 1 (repro), hypothesis, surgical read, VERIFIED block, และ offer `#cp` ตอนจบ

---

**User:** `#dbg` API `GET /users` คืน 500 ตอน login

**Assistant:**

> #dbg | GATE 1: ยังไม่มี repro | BLOCKED

ขอ repro ที่เชื่อถือได้ก่อน (Principle 1: ไม่มี repro = ไม่เดา). ขอ 3 อย่าง:
- request จริง (method, path, body, header auth)
- error / stack trace จาก log ฝั่ง server
- เกิดทุกครั้งหรือบางครั้ง

**User:** `curl -H "Authorization: Bearer <token>" localhost:3000/users` → 500 ทุกครั้ง. log: `TypeError: Cannot read properties of null (reading 'role')` ที่ `authMiddleware.js:42`

**Assistant:**

> #dbg | GATE 1 PASS | STEP 1.2 locate

repro เชื่อถือได้ + stack ชี้จุดชัด. อ่าน surgical เฉพาะ `authMiddleware.js` + ตัวที่ set `req.user` — ไม่อ่านทั้ง repo (Principle 13)

**Hypothesis:** บรรทัด 42 `req.user.role` — `req.user` เป็น `null` เมื่อ token decode สำเร็จแต่ user ถูกลบไปแล้ว: `db.findUser(id)` คืน `null` แต่โค้ดไม่เช็กก่อน access `.role`. root cause = missing null guard ไม่ใช่ตัว middleware เอง

> #dbg | GATE 1 PASS | STEP 1.4 fix + verify

fix: เพิ่ม null check หลัง `db.findUser(id)` → คืน 401 แทน crash

```
VERIFIED:
$ npm test -- auth
Tests: 8 passed, 8 total
$ curl -H "Authorization: Bearer <stale-token>" localhost:3000/users
401 {"error":"user not found"}   ← เดิม 500, ตอนนี้ 401 ถูกต้อง
```

งาน verified แล้ว — commit ไหม? พิมพ์ `#cp`

---

**สิ่งที่ตัวอย่างนี้สอน:** ไม่มี repro = หยุด ไม่เดา · hypothesis มาก่อน fix · อ่านเฉพาะไฟล์ที่ hypothesis ต้องการ · ทุกคำว่า "fixed" มี VERIFIED block (คำสั่งจริง + output จริง) · จบงานแล้ว offer `#cp` ไม่ auto-commit
