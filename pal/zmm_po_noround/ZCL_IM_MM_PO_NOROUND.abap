*----------------------------------------------------------------------*
* Class       : ZCL_IM_MM_PO_NOROUND                                   *
* BAdI impl.  : ZMM_PO_NOROUND  (definition ME_PROCESS_PO_CUST)        *
* Method      : IF_EX_ME_PROCESS_PO_CUST~PROCESS_ITEM                  *
*----------------------------------------------------------------------*
* Created by  : Arnav Johri                    Date : 17.09.2026       *
* Client      : Philippine Airlines (PAL)      Ref  : INC01192         *
* Module      : MM - Purchasing                                        *
*----------------------------------------------------------------------*
* FALLBACK. Primary object is ZCL_IM_MM_BAPI_PO_NOROUND (BAdI          *
* ME_BAPI_PO_CUST, method INBOUND). Use this one only if that BAdI     *
* cannot be implemented on the target system. Never activate both.    *
*----------------------------------------------------------------------*
* Purpose                                                              *
*   POs posted from Ariba Sourcing ("send prices to S4") are created   *
*   through BAPI_PO_CREATE1. Every item quantity is rounded to the     *
*   material master rounding value (MARC-BSTRF, MRP 1 view). The       *
*   rounded quantity exceeds the open PR quantity and no PO is created.*
*                                                                      *
*   SAP AIS MM Purchasing Development Support (case on INC01192):      *
*   "If you do not want the system to round the quantities, set the    *
*    field NO_ROUNDING = X in both BAPI_PO_CREATE1 structures POITEM   *
*    and POITEMX."                                                     *
*                                                                      *
*   The BAPI maps that flag to MEPOITEM-NO_ROUNDING. This method sets  *
*   the same field on every item - but ONLY when the calling user is   *
*   one of the Ariba / CIG technical users listed in TVARVC selection  *
*   variable ZMM_ARIBA_PO_USER. Manual ME21N, ME59N, other BAPI        *
*   callers and the MRP run (PR quantity) keep standard rounding.      *
*----------------------------------------------------------------------*
* ASSUMPTION: PROCESS_ITEM runs before the item quantity check that    *
*   applies the rounding, so a flag set here has the same effect as    *
*   the flag the BAPI caller would have sent. The SE37 unit test in    *
*   NOTES.md proves this; if the PO still rounds, the flag has to be   *
*   set by the caller (CIG add-on) instead.                            *
* ASSUMPTION: TVARVC ZMM_ARIBA_PO_USER not maintained or empty means   *
*   "do nothing" - standard rounding stays active and the PO fails as  *
*   today. No message is raised here on purpose: PROCESS_ITEM runs     *
*   inside the BAPI as well as in dialog, and a message here would     *
*   fire once per item on every PO the CIG user posts.                 *
*----------------------------------------------------------------------*
METHOD if_ex_me_process_po_cust~process_item.

  CONSTANTS: lc_tvarv_name TYPE rvari_vnam VALUE 'ZMM_ARIBA_PO_USER',
             lc_tvarv_type TYPE rsscr_kind VALUE 'S',
             lc_sign_incl  TYPE tvarv_sign VALUE 'I',
             lc_opti_eq    TYPE tvarv_opti VALUE 'EQ'.

  DATA: lt_tvarvc TYPE STANDARD TABLE OF tvarvc,
        lr_uname  TYPE RANGE OF sy-uname,
        ls_uname  LIKE LINE OF lr_uname,
        ls_item   TYPE mepoitem.

* ------------------------------------------------------------------
* 1. Who is calling? Only the Ariba / CIG technical user(s) qualify.
*    Maintained in STVARV (selection options) - no hardcoded user.
* ------------------------------------------------------------------
  SELECT sign, opti, low, high
    FROM tvarvc
    WHERE name = @lc_tvarv_name
      AND type = @lc_tvarv_type
    INTO CORRESPONDING FIELDS OF TABLE @lt_tvarvc.

  LOOP AT lt_tvarvc INTO DATA(ls_tvarvc).
    CLEAR ls_uname.
    ls_uname-sign   = ls_tvarvc-sign.
    ls_uname-option = ls_tvarvc-opti.
    ls_uname-low    = ls_tvarvc-low.
    ls_uname-high   = ls_tvarvc-high.
*   A row keyed in with only LOW filled must not break the IN check
    IF ls_uname-sign IS INITIAL.
      ls_uname-sign = lc_sign_incl.
    ENDIF.
    IF ls_uname-option IS INITIAL.
      ls_uname-option = lc_opti_eq.
    ENDIF.
    APPEND ls_uname TO lr_uname.
  ENDLOOP.

* Variable not maintained, or another caller: leave standard rounding on
  IF lr_uname IS INITIAL OR sy-uname NOT IN lr_uname.
    RETURN.
  ENDIF.

* ------------------------------------------------------------------
* 2. Ariba caller: switch off quantity rounding on this item.
*    Write back only when the flag is not already set, so SET_DATA
*    is not called again on every re-processing of the same item.
* ------------------------------------------------------------------
  ls_item = im_item->get_data( ).

  IF ls_item-no_rounding = abap_true.
    RETURN.
  ENDIF.

  ls_item-no_rounding = abap_true.
  im_item->set_data( ls_item ).

ENDMETHOD.
