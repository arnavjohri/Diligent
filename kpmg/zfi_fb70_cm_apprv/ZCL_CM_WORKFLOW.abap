*----------------------------------------------------------------------*
* Class       : ZCL_CM_WORKFLOW
* Author      : Arnav Johri
* Date        : 15.10.2026
* Description : Starts the journal entry verification workflow
*               (scenario WS02800046, class CL_FDC_ACCDOC_VER, event
*               SUBMITTED) for a customer credit memo parked in FB70.
*               Credit memo counterpart of ZCL_GL_WORKFLOW. Differences:
*               - takes the parked document as the X and Y tables handed
*                 over by BTE 00002218 (header, segments, one-time data)
*                 instead of reading it by key; the Y (old state) tables
*                 are received but not evaluated in this version;
*               - no status read after the raise: the event is delivered
*                 only after the caller's COMMIT WORK, so the caller
*                 (Z_FI_CM_APPR_START_WF) commits or rolls back on
*                 EV_STATUS.
*               The release flag XWFFR still goes through
*               PRELIMINARY_POSTING_DOC_READ / _WRITE on the database
*               copy: DOC_WRITE rewrites all four tables and the BTE
*               does not hand over VBSET (tax lines).
* Create via  : SE24 (source-based) or ADT, paste whole file.
*----------------------------------------------------------------------*
CLASS zcl_cm_workflow DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: tt_vbkpf TYPE STANDARD TABLE OF fvbkpf WITH DEFAULT KEY,
           tt_vbseg TYPE STANDARD TABLE OF fvbseg WITH DEFAULT KEY,
           tt_vbsec TYPE STANDARD TABLE OF fvbsec WITH DEFAULT KEY.

    CONSTANTS: gc_status_ok  TYPE char1 VALUE 'S',
               gc_status_err TYPE char1 VALUE 'E'.

    "! Raise CL_FDC_ACCDOC_VER.SUBMITTED for the parked credit memo.
    "! IT_VBKPF/IT_VBSEG/IT_VBSEC: X tables (new state) from BTE 00002218.
    "! IT_YVBKPF/IT_YVBSEG/IT_YVBSEC: Y tables (old state), empty on first
    "!   park; received for completeness, not evaluated in this version.
    "! IV_SUBMITTER: FB70 user; SY-UNAME when initial.
    "! EV_STATUS: S = event raised, caller must COMMIT WORK.
    "!            E = nothing raised, caller must ROLLBACK WORK.
    METHODS start_workflow
      IMPORTING
        it_vbkpf     TYPE tt_vbkpf
        it_vbseg     TYPE tt_vbseg
        it_vbsec     TYPE tt_vbsec OPTIONAL
        it_yvbkpf    TYPE tt_vbkpf OPTIONAL
        it_yvbseg    TYPE tt_vbseg OPTIONAL
        it_yvbsec    TYPE tt_vbsec OPTIONAL
        iv_submitter TYPE syuname OPTIONAL
      EXPORTING
        ev_status    TYPE char1.

  PROTECTED SECTION.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_saknr,
             saknr TYPE saknr,
           END OF ty_saknr,
           tt_saknr TYPE STANDARD TABLE OF ty_saknr WITH DEFAULT KEY,
           BEGIN OF ty_acc_grp,
             saknr TYPE saknr,
             ktoks TYPE ktoks,
           END OF ty_acc_grp,
           tt_acc_grp TYPE STANDARD TABLE OF ty_acc_grp WITH DEFAULT KEY.

    CONSTANTS: gc_objtype TYPE sibftypeid VALUE 'CL_FDC_ACCDOC_VER',
               gc_event   TYPE sibfevent  VALUE 'SUBMITTED',
               gc_debit   TYPE shkzg      VALUE 'S',
               gc_us      TYPE c LENGTH 2 VALUE 'US'.

    METHODS set_release_flag
      IMPORTING
        is_vbkpf     TYPE fvbkpf
      RETURNING
        VALUE(rv_ok) TYPE abap_bool.

    METHODS set_element
      IMPORTING
        io_container TYPE REF TO if_swf_ifs_parameter_container
        iv_name      TYPE swfdname
        iv_value     TYPE any.

ENDCLASS.


CLASS zcl_cm_workflow IMPLEMENTATION.

  METHOD start_workflow.
    DATA: ls_vbkpf      TYPE fvbkpf,
          ls_vbseg      TYPE fvbseg,
          lv_amt_coc    TYPE vbsegs-dmbtr,
          lv_amt_glb    TYPE vbsegs-dmbe2,
          lv_amt_third  TYPE vbsegs-dmbe3,
          lv_amt_func   TYPE vbsegs-wrbtr,
          lt_costcenter TYPE kostl_t,
          lt_accgroup   TYPE ktoks_t,
          lt_bukrs      TYPE fdc_bukrs_t,
          lt_saknr      TYPE tt_saknr,
          ls_saknr      TYPE ty_saknr,
          lt_acc_grp    TYPE tt_acc_grp,
          ls_acc_grp    TYPE ty_acc_grp,
          ls_lpor       TYPE sibflpor,
          lv_submitter  TYPE string,
          lo_doc        TYPE REF TO cl_fdc_accdoc_ver,
          lo_container  TYPE REF TO if_swf_ifs_parameter_container.

    ev_status = gc_status_err.

*--- 1. Header: the X table carries exactly one parked document
    READ TABLE it_vbkpf INTO ls_vbkpf INDEX 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

*--- 2. Release flag on the database copy (same two calls as
*      ZCL_GL_WORKFLOW). The document must already be committed;
*      Z_FI_CM_APPR_START_WF guarantees that before calling here.
    IF set_release_flag( ls_vbkpf ) = abap_false.
      RETURN.
    ENDIF.

*--- 3. Amounts for the workflow conditions: sum of the debit lines,
*      the same rule as ZCL_GL_WORKFLOW so the configured thresholds
*      mean the same thing for both flows.
* ASSUMPTION: thresholds are compared net of tax. For a credit memo the
*             debit lines are the revenue lines; tax sits in VBSET and
*             the customer line is the credit. If FI wants the gross
*             customer amount, sum the credit lines (SHKZG = 'H') here.
    CLEAR: lv_amt_coc, lv_amt_glb, lv_amt_third, lv_amt_func.
    LOOP AT it_vbseg INTO ls_vbseg WHERE shkzg = gc_debit.
      lv_amt_coc   = lv_amt_coc   + ls_vbseg-dmbtr.
      lv_amt_glb   = lv_amt_glb   + ls_vbseg-dmbe2.
      lv_amt_third = lv_amt_third + ls_vbseg-dmbe3.
      lv_amt_func  = lv_amt_func  + ls_vbseg-wrbtr.
    ENDLOOP.

*--- 4. Cost centres and account groups of the lines, company code
    CLEAR: lt_costcenter, lt_accgroup, lt_bukrs, lt_saknr.
    LOOP AT it_vbseg INTO ls_vbseg.
      IF ls_vbseg-kostl IS NOT INITIAL.
        APPEND ls_vbseg-kostl TO lt_costcenter.
      ENDIF.
      IF ls_vbseg-saknr IS NOT INITIAL.
        ls_saknr-saknr = ls_vbseg-saknr.
        APPEND ls_saknr TO lt_saknr.
      ENDIF.
    ENDLOOP.

    SORT lt_saknr BY saknr.
    DELETE ADJACENT DUPLICATES FROM lt_saknr COMPARING saknr.

    IF lt_saknr IS NOT INITIAL.
*     Account group by G/L account, all charts of accounts, as in
*     ZCL_GL_WORKFLOW. The customer line has no SAKNR and is skipped.
      SELECT saknr, ktoks
        FROM ska1
        FOR ALL ENTRIES IN @lt_saknr
        WHERE saknr = @lt_saknr-saknr
        INTO TABLE @lt_acc_grp.
      LOOP AT lt_acc_grp INTO ls_acc_grp WHERE ktoks IS NOT INITIAL.
        APPEND ls_acc_grp-ktoks TO lt_accgroup.
      ENDLOOP.
    ENDIF.

    APPEND ls_vbkpf-bukrs TO lt_bukrs.

*--- 5. Application object of the standard scenario
* ASSUMPTION: FB70 is single company code, so VBKPF-BUKRS is also the
*             source company code of the parked document key.
    CREATE OBJECT lo_doc
      EXPORTING
        iv_accdocnumber           = ls_vbkpf-belnr
        iv_sourcecompanycode      = ls_vbkpf-bukrs
        iv_fiscalyear             = ls_vbkpf-gjahr
        iv_accountingdocumenttype = ls_vbkpf-blart
        iv_amountincocdcrcy       = lv_amt_coc
        iv_amountinglobcrcy       = lv_amt_glb
        iv_amountinthirdcrcy      = lv_amt_third
        iv_amountinfunccrcy       = lv_amt_func
        it_costcenter             = lt_costcenter
        it_accountgroup           = lt_accgroup
        it_companycode            = lt_bukrs.

    ls_lpor-instid = lo_doc->ms_por-instid.

*--- 6. Event container, element names as in ZCL_GL_WORKFLOW
    lo_container = cl_swf_evt_event=>get_event_container(
                     im_objcateg = cl_swf_evt_event=>mc_objcateg_cl
                     im_objtype  = gc_objtype
                     im_event    = gc_event ).

    IF iv_submitter IS NOT INITIAL.
      lv_submitter = gc_us && iv_submitter.
    ELSE.
      lv_submitter = gc_us && sy-uname.
    ENDIF.

    set_element( io_container = lo_container
                 iv_name      = 'AccountingDocumentType'
                 iv_value     = lo_doc->blart ).
    set_element( io_container = lo_container
                 iv_name      = 'AmountInCompanyCodeCurrency'
                 iv_value     = lo_doc->dmbtr ).
    set_element( io_container = lo_container
                 iv_name      = 'AmountInGlobalCurrency'
                 iv_value     = lo_doc->dmbe2 ).
    set_element( io_container = lo_container
                 iv_name      = 'AmountInThirdCurrency'
                 iv_value     = lo_doc->dmbe3 ).
    set_element( io_container = lo_container
                 iv_name      = 'AmountInFunctionalCurrency'
                 iv_value     = lo_doc->fcsl ).
    set_element( io_container = lo_container
                 iv_name      = 'CostCenter_T'
                 iv_value     = lo_doc->mt_costcenter ).
    set_element( io_container = lo_container
                 iv_name      = 'AccountGroup_T'
                 iv_value     = lo_doc->mt_accountgroup ).
    set_element( io_container = lo_container
                 iv_name      = 'CompanyCode_T'
                 iv_value     = lo_doc->mt_companycode ).
    set_element( io_container = lo_container
                 iv_name      = 'Submitter'
                 iv_value     = lv_submitter ).

*--- 7. Raise. Delivered on the caller's COMMIT WORK.
    TRY.
        cl_swf_evt_event=>raise(
          im_objcateg        = cl_swf_evt_event=>mc_objcateg_cl
          im_objtype         = gc_objtype
          im_event           = gc_event
          im_objkey          = ls_lpor-instid
          im_event_container = lo_container ).
        ev_status = gc_status_ok.
      CATCH cx_swf_evt_invalid_objtype cx_swf_evt_invalid_event.
        ev_status = gc_status_err.
    ENDTRY.

  ENDMETHOD.


  METHOD set_release_flag.
    DATA: lt_vbkpf TYPE STANDARD TABLE OF fvbkpf,
          lt_vbseg TYPE STANDARD TABLE OF fvbseg,
          lt_vbsec TYPE STANDARD TABLE OF fvbsec,
          lt_vbset TYPE STANDARD TABLE OF fvbset.

    FIELD-SYMBOLS: <ls_vbkpf> TYPE fvbkpf,
                   <ls_vbseg> TYPE fvbseg.

    rv_ok = abap_false.

    CALL FUNCTION 'PRELIMINARY_POSTING_DOC_READ'
      EXPORTING
        belnr                   = is_vbkpf-belnr
        bukrs                   = is_vbkpf-bukrs
        gjahr                   = is_vbkpf-gjahr
      TABLES
        t_vbkpf                 = lt_vbkpf
        t_vbsec                 = lt_vbsec
        t_vbseg                 = lt_vbseg
        t_vbset                 = lt_vbset
      EXCEPTIONS
        document_line_not_found = 1
        document_not_found      = 2
        input_incomplete        = 3
        OTHERS                  = 4.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    READ TABLE lt_vbkpf ASSIGNING <ls_vbkpf> INDEX 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    <ls_vbkpf>-xwffr = abap_true.

*   BZALT must be filled for the verification app, as in ZCL_GL_WORKFLOW
    LOOP AT lt_vbseg ASSIGNING <ls_vbseg>.
      IF <ls_vbseg>-bzalt IS INITIAL.
        <ls_vbseg>-bzalt = <ls_vbseg>-buzei.
      ENDIF.
    ENDLOOP.

    CALL FUNCTION 'PRELIMINARY_POSTING_DOC_WRITE'
      TABLES
        t_vbkpf              = lt_vbkpf
        t_vbsec              = lt_vbsec
        t_vbseg              = lt_vbseg
        t_vbset              = lt_vbset
      EXCEPTIONS
        abnormal_termination = 1
        insert_error         = 2
        update_error         = 3
        read_error           = 4
        OTHERS               = 5.
    IF sy-subrc = 0.
      rv_ok = abap_true.
    ENDIF.

  ENDMETHOD.


  METHOD set_element.
*   An element missing from the event container is skipped, the same
*   behaviour as the per-element TRY blocks in ZCL_GL_WORKFLOW.
    TRY.
        io_container->set( name  = iv_name
                           value = iv_value ).
      CATCH cx_root.                                     "#EC CATCH_ALL
        RETURN.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
