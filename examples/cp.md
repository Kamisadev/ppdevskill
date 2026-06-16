# ตัวอย่าง `#cp` — Commit & Push

`#cp` เป็น action ไม่ใช่ mode — เรียกหลังงาน verified แล้ว แสดง GATE (inspect diff จริง + one logical change + no junk + **stage เฉพาะไฟล์ใน scope**), commit message ที่อธิบายแค่ตัว change, และ VERIFIED จาก `git log`

---

**User:** `#cp`

**Assistant:**

> #cp | GATE: inspect diff | stage เฉพาะ scope

ดู diff จริงก่อน ไม่ derive message จากความจำ:

```
VERIFIED (diff inspection):
$ git status --short
 M authMiddleware.js
 M test/auth.test.js
?? scratch.log          ← junk ไม่เกี่ยว ไม่ stage
$ git diff --stat
authMiddleware.js   | 6 +++++-
test/auth.test.js   | 14 ++++++++++
```

- **one logical change?** ✓ null guard + test ของมัน = หน่วยเดียว
- **junk/secret scan:** `scratch.log` ไม่ใช่ส่วนของ fix → **stage เฉพาะ 2 ไฟล์ใน scope** ไม่ใช้ `git add -A` (Principle 13 ฝั่ง commit + `git-auto.md`)

```
VERIFIED (commit):
$ git add authMiddleware.js test/auth.test.js
$ git commit -m "fix 500 on /users when token outlives deleted user"
$ git log -1 --stat
fix 500 on /users when token outlives deleted user
 authMiddleware.js | 6 +++++-
 test/auth.test.js | 14 ++++++++++
```

commit แล้ว 2 ไฟล์ ตรง scope. `scratch.log` ไม่ติดไป. **push?** บอก `#cp push` — ถ้าเป็น `main` จะ confirm ก่อน

---

**สิ่งที่ตัวอย่างนี้สอน:** message มาจาก diff จริง ไม่ใช่ความจำ · **stage เฉพาะไฟล์ใน scope ห้าม `git add -A`** — `scratch.log` ถูกทิ้งไว้ · message อธิบายแค่ change ไม่มี AI attribution / ไม่มี emoji · push เฉพาะตอนสั่ง, `main` ต้อง confirm · แสดง `git log -1` จริง ไม่เคลม "committed" ลอย ๆ
