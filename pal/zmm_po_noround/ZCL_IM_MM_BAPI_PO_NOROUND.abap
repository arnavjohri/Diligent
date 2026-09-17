METHOD if_ex_me_bapi_po_cust~inbound.
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
*   This method sets that flag on every item of every PO that comes   *
*   through BAPI_PO_CREATE1 / BAPI_PO_CHANGE, whoever the caller is.  *
*   Decision 17/09/26: no caller gate. Manual ME21N, ME59N and the     *
*   MRP run (PR quantity) do not pass through this BAdI and keep the  *
*   standard rounding unchanged.                                       *
*----------------------------------------------------------------------*
* ASSUMPTION: the INBOUND method exposes the item tables as CHANGING   *
*   parameters CH_ITEM (BAPIMEPOITEM_TP) and CH_ITEMX (BAPIMEPOITEMX_TP)*
*   Verify on the method signature before activating. If the names    *
*   differ on this release, rename the two below; the logic does not  *
*   change.                                                            *
* ASSUMPTION: an item with no matching POITEMX row is left alone. The  *
*   BAPI transfers no field of such an item anyway, and on a           *
*   BAPI_PO_CHANGE call an added X-row would make the BAPI process an  *
*   item the caller did not flag.                                      *
*----------------------------------------------------------------------*

  FIELD-SYMBOLS: <ls_item>  TYPE bapimepoitem,
                 <ls_itemx> TYPE bapimepoitemx.

* Switch off quantity rounding on every item. The flag must be set in
* POITEM and mirrored in POITEMX, else the BAPI ignores it.
  LOOP AT ch_item ASSIGNING <ls_item>.

    READ TABLE ch_itemx ASSIGNING <ls_itemx>
         WITH KEY po_item = <ls_item>-po_item.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    <ls_item>-no_rounding  = abap_true.
    <ls_itemx>-no_rounding = abap_true.

  ENDLOOP.

ENDMETHOD.
