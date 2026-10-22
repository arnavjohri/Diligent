*----------------------------------------------------------------------*
* Class      : ZCL_GR_JE_POST
* Title      : Post a group journal entry (ACDOCU) via the Data Monitor
*              posting engine CL_FINCS_DP_DOCUMENT_POST
* Author     : Arnav Johri (Diligent)      Created: 22.10.2026
* Project    : OVL - Group Reporting, custom Data Monitor task (CXCD)
* Ships by   : paste (ADT, or SE24 source-code based)
*----------------------------------------------------------------------*
* Caller fills IT_ITEMS (ACDOCU line type) with RBUNIT, RBUPTR, RITEM,
* SUBIT and the amounts/currencies the document type needs. Header
* fields come from the importing parameters and are copied into every
* line. Everything else (posting level, document number, year/period
* checks, FS item checks) is done by the engine.
*
* ASSUMPTION A1: FINCS_S_DOCUMENT_HEAD_POST and the line type of
*   FC05_T_PDOC_S4H_QFLE use the ACDOCU field names (RDIMEN, RITCLG,
*   RVERS, RYEAR, POPER, DOCTY, RBUNIT, RITEM ...). MOVE-CORRESPONDING
*   keeps activation safe if a name differs: that field stays empty and
*   the engine reports it at runtime.
* ASSUMPTION A2: the message handler interface IF_FINCS_TE_MESSAGE_HANDLER
*   is implemented by CL_FINCS_TE_MESSAGE_HANDLER with a public
*   constructor without parameters. If activation says the class is
*   unknown, send the where-used list of the interface.
* ASSUMPTION A3: an initial run ID (FINCS_RUNID) and an initial draft
*   indicator (FINCS_DRAFT) are accepted for a direct posting.
* Not in this version: deletion of the previous run of the task
*   (IF_FINCS_DOCUMENT_REFRESH) and the engine test run
*   (POST_TEST_RUN). Run once per unit/period until version 2.
*----------------------------------------------------------------------*
CLASS zcl_gr_je_post DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES tt_acdocu TYPE STANDARD TABLE OF acdocu WITH DEFAULT KEY.

    "! Post one group journal entry through CL_FINCS_DP_DOCUMENT_POST
    METHODS post
      IMPORTING
        iv_rdimen TYPE fc_dimen            "Dimension, e.g. Y1
        iv_ritclg TYPE fc_itclg            "Consolidation chart of accounts, e.g. Y1
        iv_rvers  TYPE fc_rvers            "Consolidation version
        iv_ryear  TYPE fc_ryear            "Fiscal year
        iv_poper  TYPE fc_perid            "Period
        iv_docty  TYPE fc_docty            "Document type of the task
        it_items  TYPE tt_acdocu           "Lines: unit, partner, FS item, subitem, amounts
        iv_commit TYPE abap_bool DEFAULT abap_true   "abap_false inside the monitor BAdI
      EXPORTING
        et_return TYPE bapiret2_t
        ev_posted TYPE abap_bool.
ENDCLASS.


CLASS zcl_gr_je_post IMPLEMENTATION.

  METHOD post.
    DATA: lo_factory TYPE REF TO if_fincs_dp_document_post_fac,
          lo_post    TYPE REF TO if_fincs_dp_document_post,
          lo_msg     TYPE REF TO if_fincs_te_message_handler,
          ls_acdocu  TYPE acdocu,
          ls_head    TYPE fincs_s_document_head_post,
          ls_doc     TYPE LINE OF fc05_t_pdoc_s4h_qfle,
          lt_doc     TYPE fc05_t_pdoc_s4h_qfle,
          lv_runid   TYPE fincs_runid,            "A3: initial
          lv_draft   TYPE fincs_draft,            "A3: initial
          ls_return  TYPE bapiret2.

    CLEAR: et_return, ev_posted.

    IF it_items IS INITIAL.
      ls_return-type    = 'W'.
      ls_return-message = 'Nothing to post: item table is empty'.          "#EC NOTEXT
      APPEND ls_return TO et_return.
      RETURN.
    ENDIF.

*   Header - A1
    CLEAR ls_acdocu.
    ls_acdocu-rdimen = iv_rdimen.
    ls_acdocu-ritclg = iv_ritclg.
    ls_acdocu-rvers  = iv_rvers.
    ls_acdocu-ryear  = iv_ryear.
    ls_acdocu-poper  = iv_poper.
    ls_acdocu-docty  = iv_docty.
    MOVE-CORRESPONDING ls_acdocu TO ls_head.

*   Lines - A1; header fields win over whatever the caller put in them
    LOOP AT it_items INTO DATA(ls_item).
      ls_acdocu        = ls_item.
      ls_acdocu-rdimen = iv_rdimen.
      ls_acdocu-ritclg = iv_ritclg.
      ls_acdocu-rvers  = iv_rvers.
      ls_acdocu-ryear  = iv_ryear.
      ls_acdocu-poper  = iv_poper.
      ls_acdocu-docty  = iv_docty.
      CLEAR ls_doc.
      MOVE-CORRESPONDING ls_acdocu TO ls_doc.
      APPEND ls_doc TO lt_doc.
    ENDLOOP.

    TRY.
        lo_factory = cl_fincs_dp_document_post_fac=>get_factory( ).
        lo_post    = lo_factory->create( ).
        lo_msg     = NEW cl_fincs_te_message_handler( ).                     "A2

        lo_post->post( iv_runid           = lv_runid
                       iv_draft           = lv_draft
                       is_head            = ls_head
                       it_document        = lt_doc
                       io_message_handler = lo_msg ).

        IF iv_commit = abap_true.
          COMMIT WORK AND WAIT.
        ENDIF.

        ev_posted         = abap_true.
        ls_return-type    = 'S'.
        ls_return-message = 'Posting engine returned without error - check ACDOCU'. "#EC NOTEXT
        APPEND ls_return TO et_return.

      CATCH cx_root INTO DATA(lx_error).
        IF iv_commit = abap_true.
          ROLLBACK WORK.
        ENDIF.
        ev_posted         = abap_false.
        ls_return-type    = 'E'.
        ls_return-message = lx_error->get_text( ).
        APPEND ls_return TO et_return.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
