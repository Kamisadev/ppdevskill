# Verification Recipes (per work type)

Static checks (type-check, lint, "syntax looks right") do not count. Execute the recipe, report observed output in a `VERIFIED:` block (format in SKILL.md). Cannot run → `NOT VERIFIED:` block, never a bare "done." Delegate to the `verification-runner` subagent when available — paste its returned block as-is.

| Work type | Required verification |
|---|---|
| **Code change (general)** | Run the entrypoint/script/command exercising the change. Show actual output. No error in the run. |
| **New or modified test** | Run the suite, see green. **Prove the test catches the bug:** temporarily break the code under test, confirm red, restore. A test that stays green on broken code is a fake test. |
| **Next.js route/component** | (1) `npx tsc --noEmit` → (2) `npm run build` (catches SSR/RSC boundary issues dev mode hides) → (3) `npm run dev` → (4) hit the affected route (curl or navigate) → (5) read server log AND browser console — no errors, no hydration warnings. Skipping any step is a violation. |
| **API endpoint** | `curl`/`fetch` against the running server. Verify status code AND response shape against the STEP 2.2 contract. |
| **DB schema / migration** | Run the migration on a dev/test DB. Verify resulting schema (`\d` / `DESCRIBE`). Run a representative query, confirm the result. |
| **Background job / cron** | Trigger manually. Observe end-to-end. Confirm side effects (file written, message sent, row inserted). |
| **Config / env change** | Restart the affected process. Confirm the new value loaded (log, health endpoint, debug print). |
| **Trust-boundary change** (input/auth/query/file/dep — see `references/sec.md`) | Exercise the abuse case, do not read for it: send the injection/forged-token/cross-tenant request → confirm rejected/403/404 AND legit path still works. New/changed deps → run `npm audit` / `pip-audit` / equivalent, paste output. |
| **Cannot verify** (env unavailable, prod secret, manual UI step) | Do NOT claim done. *"I did not run X because Y"* + list every concrete check the user must perform. |
