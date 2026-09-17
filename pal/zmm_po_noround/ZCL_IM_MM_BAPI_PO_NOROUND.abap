*----------------------------------------------------------------------*
* Class       : ZCL_IM_MM_BAPI_PO_NOROUND                              *
* BAdI impl.  : ZMM_BAPI_PO_NOROUND  (definition ME_BAPI_PO_CUST,      *
*               interface IF_EX_ME_BAPI_PO_CREATE_02)                  *
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
*   Method INBOUND sets that flag on every item of every PO that       *
*   comes through BAPI_PO_CREATE1 / BAPI_PO_CHANGE, whoever the caller *
*   is. Decision 17/09/26: no caller gate. Manual ME21N, ME59N and the *
*   MRP run (PR quantity) do not pass through this BAdI and keep the   *
*   standard rounding unchanged.                                       *
*                                                                      *
*   Every other method is intentionally empty = standard behaviour.   *
*   The class was created with SE19 "Copy Sample"; the sample logic   *
*   from CL_EXM_IM_ME_BAPI_PO_CUST was removed on 17/09/26.            *
*----------------------------------------------------------------------*
CLASS zcl_im_mm_bapi_po_noround DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_badi_interface .
    INTERFACES if_ex_me_bapi_po_create_02 .

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_im_mm_bapi_po_noround IMPLEMENTATION.


  METHOD if_ex_me_bapi_po_create_02~extensionin.
* Intentionally empty - standard behaviour. Sample code removed 17/09/26.
  ENDMETHOD.


  METHOD if_ex_me_bapi_po_create_02~extensionout.
* Intentionally empty - standard behaviour. Sample code removed 17/09/26.
  ENDMETHOD.


  METHOD if_ex_me_bapi_po_create_02~inbound.
*----------------------------------------------------------------------*
* Switch off quantity rounding on every item of the BAPI call.         *
* Signature confirmed on the PAL system 17/09/26: CH_ITEM              *
* (BAPIMEPOITEM_TP) and CH_ITEMX (BAPIMEPOITEMX_TP), both changing.    *
*----------------------------------------------------------------------*
* ASSUMPTION: an item with no matching POITEMX row is left alone. The  *
*   BAPI transfers no field of such an item anyway, and on a           *
*   BAPI_PO_CHANGE call an added X-row would make the BAPI process an  *
*   item the caller did not flag.                                      *
*----------------------------------------------------------------------*

    FIELD-SYMBOLS: <ls_item>  TYPE bapimepoitem,
                   <ls_itemx> TYPE bapimepoitemx.

*   The flag must be set in POITEM and mirrored in POITEMX, else the
*   BAPI ignores it (SAP AIS reply, INC01192).
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


  METHOD if_ex_me_bapi_po_create_02~map2e_extensionout.
* Intentionally empty - standard behaviour. Sample code removed 17/09/26.
  ENDMETHOD.


  METHOD if_ex_me_bapi_po_create_02~map2i_extensionin.
* Intentionally empty - standard behaviour. Sample code removed 17/09/26.
  ENDMETHOD.


  METHOD if_ex_me_bapi_po_create_02~outbound.
* Intentionally empty - standard behaviour. Sample code removed 17/09/26.
  ENDMETHOD.


  METHOD if_ex_me_bapi_po_create_02~partners_on_item_active.
* Intentionally empty - CH_ACTIVE keeps its default (no). See note 1022311.
  ENDMETHOD.


  METHOD if_ex_me_bapi_po_create_02~text_output.
* Intentionally empty - standard behaviour. Sample code removed 17/09/26.
  ENDMETHOD.


  METHOD if_ex_me_bapi_po_create_02~toggle_order_unit.
* Intentionally empty - standard behaviour. Sample code removed 17/09/26.
  ENDMETHOD.
ENDCLASS.
