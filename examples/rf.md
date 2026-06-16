# ตัวอย่าง `#rf` — Refactor

โหมด refactor — เปลี่ยนโครงสร้าง **ไม่เปลี่ยนพฤติกรรม** แสดง GATE 3 (safety net + named smell + behavior pinned) และการพิสูจน์ว่าพฤติกรรมเหมือนเดิม

---

**User:** `#rf` ฟังก์ชัน `calculatePrice()` มันรกมาก ช่วย clean up หน่อย

**Assistant:**

> #rf | GATE 3 FAIL: ยังไม่มี safety net + smell ยังไม่ระบุ | BLOCKED

refactor ที่ไม่มี test กันหลัง = เปลี่ยนพฤติกรรมโดยไม่รู้ตัว. ขอเช็ก 3 อย่าง (Principle 5: refactor กับ behavior change ห้ามปนกัน):
- **Safety net:** `calculatePrice()` มี test ครอบอยู่ไหม? ถ้าไม่มี ต้องเขียน characterization test กันก่อน
- **Named smell:** รก "แบบไหน"? long function / nested conditional / duplicate logic — ชี้ให้ชัด
- **Behavior pinned:** สรุปพฤติกรรมปัจจุบันเป็น 1 ประโยค

**User:** มี test ครอบ 12 เคส. smell คือ nested if 4 ชั้นคิดส่วนลด. พฤติกรรม: รับ cart คืนราคาหลังหักส่วนลดตาม tier ลูกค้า

**Assistant:**

> #rf | GATE 3 PASS | STEP 3.2 transform

safety net พร้อม (12 tests) · smell = deep nesting ของ discount logic · behavior pinned = "รับ cart → ราคาหลังหัก tier discount"

รัน test ก่อนแตะ เพื่อยืนยัน baseline เขียว:

```
VERIFIED (baseline ก่อน refactor):
$ npm test -- price
Tests: 12 passed, 12 total
```

transform: แทน nested if ด้วย discount lookup table + early return — **พฤติกรรมเดิมทุกประการ** ไม่แตะสูตรคิดเงิน

```
VERIFIED (หลัง refactor):
$ npm test -- price
Tests: 12 passed, 12 total   ← เลขเดิม ไม่มีเคสไหนเปลี่ยน = พฤติกรรมคงเดิม
$ git diff --stat
calculatePrice.js | 38 +++++-----------------
```

12/12 เขียวเท่าเดิม พฤติกรรมไม่เปลี่ยน — commit ไหม? พิมพ์ `#cp`

เจอ off-by-one ใน rounding ระหว่างทาง → **ไม่แก้ในนี้** จดไว้ทำแยกเป็น `#dbg` (Principle 5)

---

**สิ่งที่ตัวอย่างนี้สอน:** ไม่มี safety net = ไม่ refactor · รัน test เขียวก่อน *และ* หลัง (เลขเท่าเดิม = พฤติกรรมคงที่) · เจอ bug ระหว่าง refactor → จดไว้ ไม่แก้ปนใน diff เดียว · offer `#cp` เมื่อ behavior พิสูจน์แล้วว่าไม่เปลี่ยน
