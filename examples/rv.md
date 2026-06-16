# ตัวอย่าง `#rv` — Review

โหมด review — มอง diff แบบ outsider, trace end-to-end, อ้าง `file:line`, ไม่ rubber-stamp แสดง finding ที่มีหลักฐานจริงพร้อม severity

---

**User:** `#rv` review PR นี้หน่อย เพิ่ม endpoint reset password

**Assistant:**

> #rv | GATE 4 PASS | outsider trace

trace end-to-end: `POST /auth/reset` → `resetController.js` → `tokenService.js` → `mailer.js`. review แบบไม่เชื่อว่าโค้ดถูก จนกว่าจะ trace เอง (Principle 7: ไม่ rubber-stamp)

**Findings:**

- **[BLOCKER] `tokenService.js:18`** — reset token สร้างจาก `Math.random()` เดาได้ ไม่ใช่ CSPRNG. attacker brute-force token รีเซ็ตรหัสคนอื่นได้ → ใช้ `crypto.randomBytes(32)`. (trust boundary = token → security gate, `references/sec.md` A07)
- **[BLOCKER] `resetController.js:34`** — token เทียบด้วย `==` ไม่มี expiry check. token ไม่มีวันหมดอายุ → เพิ่ม TTL + constant-time compare
- **[MAJOR] `resetController.js:12`** — ไม่มี rate limit บน endpoint → enumerate email ได้ จับคู่กับ A07
- **[MINOR] `mailer.js:9`** — log เต็ม reset URL ลง console = token รั่วใน log (A09 logging) → log แค่ user id

**Verdict:** ขอ **ไม่ approve** — 2 BLOCKER แตะ security boundary โดยตรง. ไม่ใช่ nitpick: ช่องโหว่ account takeover จริง

หลังแก้ → ส่งเข้า `#dbg`/`#ft` รายข้อ แล้ว review รอบสองเฉพาะจุดที่แก้

---

**สิ่งที่ตัวอย่างนี้สอน:** review = trace เอง ไม่เชื่อคำอธิบาย PR · ทุก finding อ้าง `file:line` + severity · endpoint auth = ดึง security lens อัตโนมัติ · "ไม่ approve" คือ valid outcome ไม่ใช่ความหยาบคาย · review ไม่ผลิตโค้ด → ไม่มี VERIFIED block แต่ทุกข้อต้องมีหลักฐานจาก diff จริง
