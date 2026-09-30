# ZMM_BP_CREATE_MAIL — assumptions and queries (FS 057)

Answers recorded from Arnav / functional (Om Prakash, Ankit) on 25/09/26. Anything still
open is marked OPEN.

| # | Question | FS ref | Answer / assumption | Status |
|---|---|---|---|---|
| Q1 | Date range and checkbox both filled — which wins? | 2.1 selection screen | **Checkbox wins.** Ticked → previous day regardless of range. Unticked + blank range → today. Unticked + range → range. | Closed |
| Q2 | Is the supplier number identical to the BP number? | 2.1 "LIFNR vs PARTNER" | **Yes** — LFA1 read directly with BUT000-PARTNER. No CVI_VEND_LINK hop. | Closed |
| Q3 | ADR6 CONSNUMBER 4 / 5 is an entry sequence, not a role — wrong order = wrong recipient | 2.1 recipients | **Use the FS logic as given** (004 = supplier manager, 005 = supplier contact). Risk accepted by functional; a BP whose e-mails were keyed in a different order will mail the wrong person. | Closed — risk accepted |
| Q4 | AN ID (Ariba Network ID) — where stored? | 1 overview | **Struck out in the FS** — dropped. | Closed |
| Q5 | "Creator user" is read but appears nowhere | 2.1 | **Leave out for now**; to be taken up later if wanted. | Closed — parked |
| Q6 | Subject line and sender | e-mail draft | Subject: *Your Supplier Account Has Been Successfully Created with Astral* (text symbol S01). Sender: not specified — implemented as optional TVARVC `ZMM_BP_MAIL_SENDER`, falling back to the job user's SU01 address. | Sender OPEN — confirm the address |
| Q7 | Several addresses on one BP | e-mail draft | **BUT020 holds exactly one** per BP (confirmed). Code keeps the lowest ADDRNUMBER if ever more. | Closed |
| Q8 | MC_STREET is an uppercase search field | e-mail draft | **Use ADRC-STREET** — carries the full street line. | Closed |
| Q9 | Hardcoded MDM address | 2.1 recipients | **TVARVC variable `ZMM_BP_MAIL_MDM`** instead of the hardcoded address; supports several rows. | Closed |
| Q10 | Re-runs would re-send | 2.1 | **No re-send guard needed.** Instead: **one mail per run covering every BP of the day, to everyone** — MDM + all supplier managers + all supplier contacts. | Closed — see R1 |
| Q11 | Language for country/region text | e-mail draft | SPRAS = EN per FS, constant `GC_LANGU = 'E'`. | Closed |
| Q12 | Time 12:05 AM on the selection screen | 2.1 | Read as the SM36 schedule, not a screen field. Manual step in TEXTS.md. | Assumed |
| Q13 | Program name, package, transaction code | — | Built as `ZMM_BP_CREATE_MAIL`, tcode `ZMM_BP_MAIL`. Package not given. | OPEN |
| Q14 | Target release | — | Not given. No CDS/RAP in this object; only 7.40+ syntax used (string templates, inline `@`, `escape( )`), safe on any S/4. | OPEN — probe not run |
| Q15 | Authorisation check | — | FS asks for none; none built. Report reads supplier addresses and e-mails for any user who can start it — restrict by SE93/role if wanted. | OPEN — flagged |

## Risks raised (not blocking, functional to acknowledge)

| # | Risk | Where in code |
|---|---|---|
| R1 | **One mail to everyone** means each supplier's contact and manager sees every other supplier created that day — name, full address, BP code and manager e-mail. This is the functional decision of 25/09/26 (Q10) and is built as asked. If this is not acceptable, the change is one mail per BP (loop in `SEND_MAIL`), about 20 lines. | `COLLECT_RECIPIENTS`, `BUILD_BODY` |
| R2 | A BP in a supplier grouping with no LFA1 row (supplier role not yet assigned) is logged as a warning and left out of the mail. It will **not** be picked up on a later day, because the driver is on creation date. | `BUILD_RECORDS` |
| R3 | ADR6 read restricted to PERSNUMBER = space (organisation e-mails only). If Astral stores the sequence-4/5 e-mails against a contact person instead, nothing is found. | `FETCH_DETAILS` |
| R4 | Mail wording lives in text symbols; an unmaintained symbol produces a blank line. | TEXTS.md |
