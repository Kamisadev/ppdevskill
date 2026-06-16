# ppdevskill — Engineering Partner Skill

Claude Skill ที่เปลี่ยน Claude จาก "AI ที่พ่นโค้ดให้เสร็จ ๆ ไป" ให้กลายเป็น **เพื่อนร่วมงานวิศวกรรมจริง ๆ** — เข้าใจความต้องการที่แท้จริง แก้ให้ถูกจุด ไม่ over-engineer และเขียนโค้ดอย่างมีหลักการ

---

## คืออะไร

`ppdevskill` คือ skill เดียวที่รวม workflow งานวิศวกรรมซอฟต์แวร์ไว้ครบ 5 โหมด แต่ละโหมดมี **gate (ด่านบังคับ)** ที่ข้ามไม่ได้ เพื่อกัน Claude ไม่ให้ลงมือเขียนโค้ดก่อนที่ข้อมูลจะครบและก่อนที่ผู้ใช้จะอนุมัติ

หัวใจของ skill คือ **zero drift** — LLM มักจะ "หลุด" กฎเมื่อบทสนทนายาวขึ้นหรือเมื่อผู้ใช้เร่ง skill นี้บังคับให้ Claude ยึดกฎตามตัวอักษรทุกครั้ง แม้ผู้ใช้จะบอกว่า "ทำเลย" หรือ "ข้าม gate ไปเถอะ" ก็ไม่ถือเป็นการอนุญาตให้ละเมิดกฎ

---

## โหมดทั้งหมด

| โหมด | คำสั่ง | ใช้เมื่อ |
|---|---|---|
| Debug | `#dbg` | เจอ bug, มี error / stack trace, ของพัง |
| Feature | `#ft` | เพิ่ม / สร้าง / implement ฟีเจอร์ใหม่ |
| Refactor | `#rf` | ทำความสะอาด / จัดโครงสร้างโค้ด (ไม่เปลี่ยนพฤติกรรม) |
| Review | `#rv` | review / audit PR, diff, plan, design doc |
| Post-mortem | `#pm` | เขียน RCA / post-mortem หลังแก้ bug เสร็จ |
| Commit/Push | `#cp` | commit และ push (ข้อความสะอาด ไม่มี AI attribution) |

- `#pp` — auto-route: ให้ Claude เลือกโหมดเองจากบริบท
- **Security** เป็นด่านขวาง (cross-cutting) ไม่ใช่โหมดที่ 6 — ทุกการเปลี่ยนแปลงที่แตะ trust boundary (input / auth / token / file / SQL / shell / crypto / secret / network) จะเปิด security gate อัตโนมัติ และ **ปิดไม่ได้**

---

## ใช้ยังไง

### 1. ติดตั้ง

**วิธีง่ายสุด — ผ่าน npm:**

```bash
npx ppdevskill@latest install        # copy เข้า ~/.claude/skills/ + ถามว่าจะ wire hook ไหม
npx ppdevskill install --with-hook   # wire Stop hook ให้เลย ไม่ถาม
npx ppdevskill install --no-hook     # ไม่แตะ settings.json (print snippet ให้ paste เอง)
```

installer จะ backup ของเดิมก่อน, `chmod +x` hook ให้, และไม่ทับ key อื่นใน settings.json. เสร็จแล้ว restart Claude Code.

**หรือ git clone:**

```bash
git clone https://github.com/Kamisadev/ppdevskill.git ~/.claude/skills/ppdevskill
```

โครงสร้างไฟล์:

```
ppdevskill/
├── SKILL.md              # hub หลัก — กฎ, principles, routing
├── references/
│   ├── dbg.md            # gate + ขั้นตอนโหมด debug
│   ├── ft.md             # gate + ขั้นตอนโหมด feature
│   ├── rf.md             # gate + ขั้นตอนโหมด refactor
│   ├── rv.md             # gate + ขั้นตอนโหมด review
│   ├── pm.md             # gate + ขั้นตอนโหมด post-mortem
│   ├── sec.md            # security gate (OWASP Top 10)
│   ├── verify.md         # ตารางวิธี verify ตามชนิดงาน
│   └── git-auto.md       # ขั้นตอน #cp commit / push
├── hooks/
│   ├── verify-guard.sh       # Stop hook — บังคับ VERIFIED block ด้วยกลไก
│   └── settings.snippet.json # config ที่ merge เข้า settings.json
└── examples/                 # worked example ต่อโหมด — อ่าน on demand
    ├── dbg.md            # ตัวอย่างโหมด debug (gate → VERIFIED)
    ├── ft.md             # ตัวอย่างโหมด feature
    ├── rf.md             # ตัวอย่างโหมด refactor
    ├── rv.md             # ตัวอย่างโหมด review
    ├── pm.md             # ตัวอย่างโหมด post-mortem
    └── cp.md             # ตัวอย่าง commit / push
```

### 1.5 เปิดการบังคับด้วยกลไก (hooks) — แนะนำ

ทำให้กฎ VERIFIED block บังคับด้วย Stop hook จริง ไม่พึ่งวินัย LLM ล้วน. merge `hooks/settings.snippet.json` เข้า `~/.claude/settings.json` (global) หรือ `.claude/settings.json` (ต่อ project) — ถ้ามี key `hooks` อยู่แล้ว เพิ่ม entry `Stop` เข้าไป **อย่าทับ**.

```bash
chmod +x ~/.claude/skills/ppdevskill/hooks/verify-guard.sh
```

หลัง merge: response ที่มี ppdevskill banner + อ้างว่าเสร็จ (`done`/`เสร็จ`/`works`) แต่ไม่มี `VERIFIED:`/`NOT VERIFIED:` block → hook **block** + บังคับแก้ในเทิร์นนั้น. **scope เฉพาะ ppdevskill** (ดูจาก banner) — workflow อื่นไม่โดน. **fail-open** — hook พังเมื่อไหร่ = ปล่อยผ่าน ไม่เคย brick session. ต้องมี `jq`.

> **ledger**: `#dbg`/`#ft`/`#rf` เขียน gate state ลง `.ppdev/<mode>-ledger.md` ใน repo ที่ทำงานอยู่ → รอด context compaction. เพิ่ม `.ppdev/` ใน `.gitignore` ของ repo นั้น.

### 2. เรียกใช้

พิมพ์คำสั่งโหมดในแชต หรือปล่อยให้ trigger ทำงานเอง:

```
#dbg API /users คืน 500 ตอน login
#ft เพิ่มหน้า export CSV ให้รายงานยอดขาย
#rv ช่วย review PR นี้หน่อย
#pp <อธิบายงาน>   ← ให้เลือกโหมดให้
```

Claude จะตอบเป็นภาษาไทย (เก็บศัพท์เทคนิค / ชื่อ function / path / error เป็นภาษาอังกฤษ) พร้อม banner บอกโหมดและสถานะ gate ทุกครั้ง เช่น:

```
> #dbg | GATE 1 PASS | STEP 1.2
```

---

## ประโยชน์

- **กันโค้ดมั่ว** — ไม่มี gate ไม่เขียนโค้ด ข้อมูลไม่ครบต้อง brainstorm ก่อน ไม่เดามั่ว
- **แก้ถูกจุด** — หา root cause ก่อน ไม่แก้ที่อาการ
- **ไม่ over-engineer** — ยึดหลัก YAGNI ไม่สร้าง abstraction ก่อนเวลา
- **บอกความจริง** — ไม่ประจบ ไม่ hedge ไม่ rubber-stamp มีจุดยืนและคำแนะนำที่ชัดเจน
- **ไม่อ้างว่าเสร็จลอย ๆ** — ทุกคำว่า "เสร็จ / done / works" ต้องมี `VERIFIED:` block (คำสั่งที่รันจริง + output จริง) กำกับ
- **Security มาก่อน** — แตะ trust boundary เมื่อไหร่ ต้องผ่าน security gate (อ้างอิง OWASP Top 10) เสมอ ปิดไม่ได้
- **บังคับด้วยกลไก ไม่ใช่แค่ขอ** — Stop hook บังคับ VERIFIED block, ledger ลงไฟล์กัน drift ในเซสชันยาว (ดู `hooks/`)
- **มีตัวอย่างจริง + offer commit ให้เอง** — `examples/<mode>.md` แสดงแต่ละโหมดตั้งแต่ gate ถึง VERIFIED block · พองาน verified แล้ว skill จะ **offer `#cp` ให้เอง** (ไม่ auto-commit, ไม่ offer ตอนงานยังพัง) ไม่ต้องนึกเองว่าถึงเวลา commit
- **แยก concern ชัด** — เปลี่ยนพฤติกรรมกับ refactor ห้ามอยู่ใน diff เดียวกัน หนึ่ง response หนึ่งโหมด

---

## ปรัชญาหลัก

> "ขอเวลาห้านาทีเพื่อทำให้ถูก ดีกว่าทำผิดไปห้าชั่วโมง" — **การปฏิเสธคือฟีเจอร์**

แก้ที่ความต้องการจริง ไม่ใช่แค่คำสั่งที่พิมพ์มา ถ้าสองอย่างนี้ขัดกัน Claude จะหยุดถามก่อนเสมอ
