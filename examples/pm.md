# ตัวอย่าง `#pm` — Post-mortem

โหมด post-mortem — เขียน RCA **หลัง fix ลงแล้ว** แสดง GATE 5 (ต้องมี repro + root cause + fix + validation ครบในมือ ไม่งั้นปฏิเสธ) และโครงสร้าง blameless

---

**User:** `#pm` เขียน post-mortem เคส 500 ตอน login เมื่อกี้

**Assistant:**

> #pm | GATE 5 PASS | RCA

ของครบในมือ (มาจาก ledger ของ `#dbg`): repro ✓ root cause ✓ fix ✓ validation ✓ — เขียนได้

**Post-mortem: `GET /users` คืน 500 ตอน login**

- **Impact:** ผู้ใช้ที่ถูกลบบัญชีแต่ token ยังไม่หมดอายุ → 500 ทุก request. กระทบ ~0.3% ของ login, 2 ชม. ก่อนพบ
- **Timeline (UTC+7):** 14:02 deploy → 14:10 error rate พุ่ง → 14:55 พบ stack → 15:08 fix merged
- **Root cause:** `authMiddleware.js:42` access `req.user.role` โดยไม่เช็ก `db.findUser(id)` คืน `null`. ตัว JWT verify ทำงานถูก — ช่องว่างคือ "token valid แต่ user หายไปแล้ว" ไม่มีใครคิดถึงตอนเขียน
- **Fix:** null guard → คืน 401 เมื่อ user ไม่มีในระบบ
- **Validation:** test เพิ่ม 1 เคส (stale token) + curl ยืนยัน 401 (ดู `#dbg` VERIFIED block)
- **ไม่ใช่ความผิดใคร (blameless):** ระบบปล่อยให้ token อายุยืนกว่าอายุบัญชีได้ = ช่องว่างเชิงดีไซน์ ไม่ใช่คนเขียนพลาด

**Action items:**
1. `[#rf]` รวม user-existence check เป็น middleware เดียว กัน bug class นี้ทั้งระบบ
2. `[ops]` alert เมื่อ 5xx rate > 1% ภายใน 5 นาที (รอบนี้กว่าจะรู้ 8 นาที)
3. `[#ft]` revoke token ทันทีเมื่อลบบัญชี

---

**สิ่งที่ตัวอย่างนี้สอน:** ไม่มี 4 อย่างครบ (repro/root cause/fix/validation) = ปฏิเสธเขียน · blameless โทษระบบ ไม่โทษคน · action item ผูกกลับเข้าโหมด (`#rf`/`#ft`) · ledger ของ `#dbg` คือวัตถุดิบของ `#pm`
