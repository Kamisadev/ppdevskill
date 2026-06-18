# ตัวอย่าง `#plan` — Ultra Plan (Orchestrator)

โหมด plan ตั้งแต่ GATE 0 (outcome + size gate + unknowns + DoD) ถึง slice table แบบเต็มและ hand off slice 1 — แสดงการ refuse งานเล็ก, แตก slice ตาม dependency, และ "ไม่เขียนโค้ดเอง"

---

**User:** `#plan` อยากให้ระบบสมาชิก login ด้วย Google ได้ แล้วก็เก็บ audit log ทุกครั้งที่ login

**Assistant:**

> #plan | GATE 0 FAIL: outcome + unknowns ยังไม่ครบ | BLOCKED

ก่อนวางแผนต้องผ่าน GATE 0. ขอเคลียร์:
- **Outcome (end state):** ผู้ใช้กดปุ่ม "Sign in with Google" แล้วเข้าระบบได้ และทุก login (สำเร็จ/ล้มเหลว) ถูกบันทึกใน audit log ที่ค้นย้อนหลังได้ — ใช่ไหม?
- **Unknown ที่เปลี่ยนรูปแผน:** ตอนนี้ auth เป็น session-based หรือ JWT? เพราะ OAuth callback ต้อง plug เข้า seam เดิม — ถ้า seam ยังไม่มีต้อง refactor ก่อน
- **Constraint:** มี user เดิม login ด้วย email/password อยู่ไหม (ต้องไม่ break)?

**User:** ใช่ตาม outcome. ตอนนี้เป็น session-based, มี user email/password เดิมอยู่ ห้าม break. audit log ยังไม่มี table

**Assistant:**

> #plan | GATE 0 PASS · size gate PASS (3 modes, 4 slices, มี dependency) | STEP P.2

**Outcome:** Google login ใช้งานได้ + audit log ทุก login ค้นย้อนหลังได้ · **DoD:** user ใหม่ login ผ่าน Google ได้, user เดิม email/password ยัง login ได้, ทุก attempt มี row ใน `audit_log`

| # | Slice (outcome) | Mode | Depends on | Risk / unknown | Rollback | Verify |
|---|---|---|---|---|---|---|
| 1 | แยก auth ออกเป็น provider seam (email/pw เป็น provider ตัวแรก, พฤติกรรมเดิมเป๊ะ) | `#rf` | — | session ผูกกับ controller ตรงๆ อาจกระจายหลายที่ | revert commit (no behavior change) | recipe: refactor → full test suite เขียว เท่าเดิม |
| 2 | `audit_log` table + write บน login ปัจจุบัน | `#ft` | — | schema เปลี่ยนยาก migrate ทีหลัง | drop table + flag off | recipe: feature → test happy/empty + row จริงใน DB |
| 3 | Google OAuth เป็น provider ตัวที่สอง ผ่าน seam ของ slice 1 | `#ft` | 1 | callback CSRF / state param (trust boundary → sec.md) | feature flag `google_auth` | recipe: feature → e2e login flow + abuse case |
| 4 | ต่อ audit write เข้า path login ทั้งสอง provider | `#ft` | 2,3 | race เมื่อ login พร้อมกัน | flag off audit | recipe: feature → ทั้งสอง provider เกิด log row |

**Critical path:** 1 → 3 → 4 (Google ต้องรอ seam). slice 2 รันขนานกับ 1 ได้ (ไม่พึ่งกัน).

slice 1 ไม่มี dependency ค้าง — เริ่มที่ `#rf` (seam ก่อน feature). เข้าเลยไหม? (จด table นี้ลง `.ppdev/plan-ledger.md` แล้ว)

---

**สิ่งที่ตัวอย่างนี้สอน:** GATE 0 = outcome เป็น end state + unknown ที่เปลี่ยนแผน (session vs JWT) + DoD ของทั้ง arc · 1 slice = 1 mode (refactor seam แยกจาก feature — Principle 5) · order ตาม dependency ไม่ใช่ความสะดวก · ทุก slice มี rollback + verify recipe · `#plan` ไม่เขียนโค้ด — hand off slice 1 แล้วหยุด · slice เข้า mode ไหนก็เจอ gate ของ mode นั้นเต็มๆ
