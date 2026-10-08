# FBV0 / CORE_GJ 912: vendor line on the corporate venture

## What it is
Not a Z object. A diagnosis record for JVA error CORE_GJ 912
"No partner found for venture &1 and vendor &2", raised by standard FM
`VALID_BTYPE` (called from SAPMF05A during posting) when a vendor line is
coded to OVL's corporate venture CP0001. Kept so the next occurrence does not
need a trace. No source here, so no `original/`.

## Mechanism (the one place to look)
`VALID_BTYPE`, vendor branch:

    CALL FUNCTION 'GJ_PARTNER_CHECK' ... partner = i_lifnr ...
    IF sy-subrc = 1 AND ( sy-tcode = 'FBV0' OR sy-tcode = 'FBVB' OR ... ).
      RETURN.
    ELSE.
      " needs T8JV-OPERATOR -> KNA1-LIFNR = vendor, else MESSAGE e912

`GJ_PARTNER_CHECK` returns 0 straight away for the corporate venture
(`T8JZ-CORPVENT`), so a "pass" lands in the operator check. CP0001 has no
operator, so it always fails. On a normal venture an employee vendor gets
`sy-subrc = 1` and the FBV0/FBVB exemption lets it through.

## How it was found (reuse this)
1. Error popup: Performance Assistant gives the message class/number (CORE_GJ 912).
2. Where-used and the Z/Y source scan were empty, so standard code.
3. ST05 on the user's ID from our own ID (Activate Trace with Filter -> user),
   on the user's application server (AL08/SM51), with **DB SQL Trace +
   Buffer & ABAP SQL Engine Trace**. JVA tables (T8J*) are buffered and do not
   show in a plain SQL trace.
4. In the export, the rows just before `T100 ECORE_GJ 912` showed the call
   chain: SAPMF05A -> `VALID_BTYPE` -> `GJ_PARTNER_CHECK`. The absence of T8JO/T8JQ
   reads, and of a KNA1 read after T8JV, pinned the branch taken.
5. SE37 source of `GJ_PARTNER_CHECK` and `VALID_BTYPE`, plus SE16N T8JZ / T8JV.

## Gotchas
- Never debug or post on the user's ID; trace it from your own.
- Do not modify `VALID_BTYPE`. It is standard; the route is an SAP note or incident.
- "298" on the FBV3 overview is PK 29 + SGL indicator 8, not a posting key.
