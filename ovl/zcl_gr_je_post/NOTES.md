# OVL — `ZCL_GR_JE_POST`: post a group journal entry from ABAP

**What:** one public method `POST` that wraps the Data Monitor posting engine
(`cl_fincs_dp_document_post_fac=>get_factory( )->create( )->post( )`). Caller gives
dimension, cons chart of accounts, version, year, period, document type and an item table
typed on `ACDOCU`; the class builds `FINCS_S_DOCUMENT_HEAD_POST` and
`FC05_T_PDOC_S4H_QFLE` by `MOVE-CORRESPONDING` and posts. Messages come back as `BAPIRET2_T`.

**Why this way:** no posting OData exists on this release (`API_CNSLDTNGRPJRNLENTR` is
S/4HANA 2022+), the Fiori app's own classes are BOPF/draft-bound. Research in
`ovl/cnsldtn_grpjrnl_api/NOTES.md`.

**Ships by:** paste. ADT: create class `ZCL_GR_JE_POST`, replace the whole source with
`ZCL_GR_JE_POST.abap`. SE24: switch to source-code-based view first.

**Test from SE24 (no BAdI needed):** SE24 → `ZCL_GR_JE_POST` → Test (F8) → method `POST` →
fill the six header parameters with a test version/period, add one or two `IT_ITEMS` rows
(`RBUNIT`, `RITEM`, `SUBIT`, `RBUPTR` if the FS item needs a partner, amount and currency
in the fields the document type's customising requires), execute. `ET_RETURN` shows the
result; the document is in `ACDOCU` (SE16, filter `DOCTY`, `RVERS`, `RYEAR`, `POPER`).

**Assumptions in the source (A1–A3):** ACDOCU field names in the engine structures; message
handler class `CL_FINCS_TE_MESSAGE_HANDLER`; initial run ID and draft indicator accepted.
Each one is a possible activation or runtime message, fixed in one cycle.

**Not yet in v1:** deletion of the previous run (`IF_FINCS_DOCUMENT_REFRESH`, re-runs would
double the amounts), engine test run (`POST_TEST_RUN`), reading messages out of the message
handler. Version 2 once v1 has posted one document.

**Next object:** the BAdI wiring in `IF_BADI_FINCS_CUST_DATAMON~EXECUTE` (10 lines calling
this class, `iv_commit = abap_false`), after the class is active.
