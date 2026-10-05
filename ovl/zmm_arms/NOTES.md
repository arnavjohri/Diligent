# ovl/zmm_arms — SAPMZMMPREPROLE1 (End User Authorisation request, "ARMS")

Module pool, package ZMM_OTH. Users raise MM role/authorisation requests (role, plant,
purchasing group, storage location, receipt location, approver). The requests go through
creator release, then L3 / IM / L1 approval, then the ICE core team.
Tables: ZMM_PREP_ROLEREQ (header), ZMM_PREP_ROLEREI (items).

- Shipping: **paste-only**. It is a module pool with screens 100/105/120, so no `src/` and
  no abapGit ZIP.
- Repo source copy (full-width): `ovl/atc/sources/modpool/SAPMZMMPREPROLE1.abap` + the
  `MZMMPREPROLE1*.abap` includes.
- `original/SAPMZMMPREPROLE1_listing.txt`: the SE38 print listing supplied 05.10.2026. It is
  cut at column 72. Use `ZR_PROG_DOWNLOAD` next time to get full lines.
- Tcode ZMM_ARMS is hardcoded to show a popup ("discontinued, use ZICE_ARMS") and leave the
  program (`MODULE ICE_ARMS`). Find out which tcode the client actually runs before changing
  anything.
- Hardcoded values are listed in `HARDCODES.md`.
