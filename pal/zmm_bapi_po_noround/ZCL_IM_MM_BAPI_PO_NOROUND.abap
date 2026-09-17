*----------------------------------------------------------------------*
* Class       : ZCL_IM_MM_BAPI_PO_NOROUND                              *
* BAdI impl.  : ZMM_BAPI_PO_NOROUND  (definition ME_BAPI_PO_CUST)     *
* Method      : IF_EX_ME_BAPI_PO_CUST~INBOUND                          *
*----------------------------------------------------------------------*
* Created by  : Arnav Johri                    Date : 17.09.2026       *
* Client      : Philippine Airlines (PAL)      Ref  : INC01192         *
* Module      : MM - Purchasing                                        *
*----------------------------------------------------------------------*
* Purpose                                                              *
*   POs posted from Ariba Sourcing ("send prices to S4") are created   *
*   through BAPI_PO_CREATE1. The BAPI rounds every item quantity to    *
*   the material master rounding value (MARC-BSTRF, MRP 1 view). The   *
*   rounded quantity exceeds the open PR quantity and the PO is not    *
*   created at all.                                                    *
*                                                                      *
*   SAP AIS MM Purchasing Development Support (case on INC01192):      *
*   "If you do not want the system to round the quantities, set the    *
*    field NO_ROUNDING = X in both BAPI_PO_CREATE1 structures POITEM   *
*    and POITEMX."                                                     *
*                                                                      *
*   This method sets that flag on every item - but ONLY when the       *
*   calling user is one of the Ariba / CIG technical users listed in   *
*   TVARVC selection variable ZMM_ARIBA_PO_USER. Any other caller of   *
*   the BAPI, manual ME21N and the MRP run (PR quantity) keep the      *
*   standard rounding unchanged.                                       *
*----------------------------------------------------------------------*
* ASSUMPTION: the INBOUND method exposes the item tables as CHANGING   *
*   parameters CH_ITEM (BAPIMEPOITEM_TP) and CH_ITEMX (BAPIMEPOITEMX_TP)*
*   Verify in SE18 > ME_BAPI_PO_CUST > Interface > INBOUND before      *
*   pasting. If the names differ on this release, rename the two       *
*   parameters below; the logic does not change.                       *
* ASSUMPTION: TVARVC ZMM_ARIBA_PO_USER not maintained or empty means   *
*   "do nothing" - standard rounding stays active and the PO fails as  *
*   today. A BAPI BAdI cannot raise a dialog message, so this is       *
*   documented in NOTES.md instead of being reported at run time.      *
*----------------------------------------------------------------------*
METHOD if_ex_me_bapi_po_cust~inbound.

  CONSTANTS: lc_tvarv_name TYPE rvari_vnam VALUE 'ZMM_ARIBA_PO_USER',
             lc_tvarv_type TYPE rsscr_kind VALUE 'S',
             lc_sign_incl  TYPE tvarv_sign VALUE 'I',
             lc_opti_eq    TYPE tvarv_opti VALUE 'EQ'.

  DATA: lt_tvarvc TYPE STANDARD TABLE OF tvarvc,
        lr_uname  TYPE RANGE OF sy-uname,
        ls_uname  LIKE LINE OF lr_uname.

  FIELD-SYMBOLS: <ls_item>  TYPE bapimepoitem,
                 <ls_itemx> TYPE bapimepoitemx.

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
* 2. Ariba caller: switch off quantity rounding on every item.
*    Flag must be set in POITEM and mirrored in POITEMX, else the
*    BAPI ignores it (SAP AIS reply, INC01192).
* ------------------------------------------------------------------
  LOOP AT ch_item ASSIGNING <ls_item>.

    <ls_item>-no_rounding = abap_true.

    READ TABLE ch_itemx ASSIGNING <ls_itemx>
         WITH KEY po_item = <ls_item>-po_item.
    IF sy-subrc = 0.
      <ls_itemx>-no_rounding = abap_true.
    ELSE.
*     Caller sent no X-row for this item: add one so the flag is honoured
      APPEND INITIAL LINE TO ch_itemx ASSIGNING <ls_itemx>.
      <ls_itemx>-po_item     = <ls_item>-po_item.
      <ls_itemx>-po_itemx    = abap_true.
      <ls_itemx>-no_rounding = abap_true.
    ENDIF.

  ENDLOOP.

ENDMETHOD.
