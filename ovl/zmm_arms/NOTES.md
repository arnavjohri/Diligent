# ovl/zmm_arms — SAPMZMMPREPROLE1 (End User Authorisation request, "ARMS")

Module pool, package ZMM_OTH. Users raise MM role/authorisation requests (role, plant,
purchasing group, storage location, receipt location, approver). The requests go through
creator release, then L3 / IM / L1 approval, then the ICE core team.
Tables: ZMM_PREP_ROLEREQ (header), ZMM_PREP_ROLEREI (items).

- Shipping: **paste-only**. It is a module pool with screens 100/105/120, so no `src/` and
  no abapGit ZIP.
- Repo source copy (full-width): `ovl/atc/sources/modpool/SAPMZMMPREPROLE1.abap` + the
  `MZMMPREPROLE1*.abap` includes.
- `original/SAPMZMMPREPROLE1_listing.txt`: the SE38 print listing supplied 05.10.2026, cut at
  column 72. Superseded by `original/SAPMZMMPREPROLE1.txt` (ZR_PROG_DOWNLOAD, 26.10.2026, full
  width, identical to the repo copy).
- **ZMM_ARMS is dead code; the business tool is ZOVL_ARMS.** Comparison in `TCODE_COMPARE.md`.
- Tcode ZMM_ARMS is hardcoded to show a popup ("discontinued, use ZICE_ARMS") and leave the
  program (`MODULE ICE_ARMS`). Find out which tcode the client actually runs before changing
  anything.
- Hardcoded values are listed in `HARDCODES.md` (old ZMM_ARMS program).
- **S/4 entry chain:** tcode ZOVL_ARMS → report `ZGRC_CALL_TODE` (exports memory ID `AUTH` = X)
  → `CALL TRANSACTION 'ZICE_ARMS'` → `SAPMZMMPREPROLE1_PHASEII`. Direct ZICE_ARMS is blocked by
  `MODULE pop_message` ("Please Use TRANSACTION ZOVL_ARMS"). Repo copy of the module pool is in
  `ovl/atc/sources/modpool/` (O01 include filled 26/10/26 from a full-width download).
- `original/SAPMZMMPREPROLE1_PHASEII.txt` + `original/ZGRC_CALL_TODE.txt`: ZR_PROG_DOWNLOAD
  listings, OCD/500, 26.10.2026 — identical to the repo copy (drift check done).
- Role-rename patch map (Uday, 10/26): `ROLE_RENAME.md`. **Corrected objects:**
  `MZMMPREPROLE1_PHASEIII01.abap` and `MZMMPREPROLE1_PHASEIIF01.abap` at this folder root —
  whole includes, paste into SE38, activate `SAPMZMMPREPROLE1_PHASEII`. Author tag `SAP_ABAP`
  (OVL precedent on OCD).
- Functional overview (Claude Doc): https://claude.ai/code/artifact/745608d2-f5ad-4d87-937e-f39dada3474c
- Hardcoded values register (Claude Doc): https://claude.ai/code/artifact/2f8d9310-fb7d-401a-9dd6-ad366facca2c — PDF export: `ZMM_ARMS_Hardcoded_Values_Register.pdf`
- Role catalogue for Security (Claude Doc): https://claude.ai/code/artifact/2dcf8f4d-d3f8-4def-a921-b3f249e84c0a — PDF: `ZICE_ARMS_Role_Catalogue_for_Security.pdf`
