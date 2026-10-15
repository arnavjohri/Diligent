*----------------------------------------------------------------------*
* Class       : ZCL_CM_WORKFLOW
* Author      : Arnav Johri
* Date        : 15.10.2026
* Description : Credit memo copy of ZCL_GL_WORKFLOW->START_WORKFLOW.
*               Raises CL_FDC_ACCDOC_VER.SUBMITTED (scenario WS02800046)
*               for a customer credit memo parked in FB70.
*               Same sequence as the GL class; differences only:
*               - document comes in as the BTE 00002218 tables instead
*                 of PRELIMINARY_POSTING_DOC_READ;
*               - XWFFR set by UPDATE instead of DOC_WRITE (no VBSET
*                 available, BZALT already filled by FB70);
*               - no status select after the raise (runs before the
*                 caller's COMMIT WORK); caller commits on EV_STATUS = S.
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
ENDCLASS.


CLASS zcl_cm_workflow IMPLEMENTATION.

  METHOD start_workflow.
** Data Declarations
    DATA: lv_objtype          TYPE sibftypeid,
          lv_event            TYPE sibfevent,
          lr_event_parameters TYPE REF TO if_swf_ifs_parameter_container,
          ls_lpor             TYPE sibflpor,
          ls_vbkpf            TYPE fvbkpf,
          lv_amt_coc          TYPE vbsegs-dmbtr,
          lv_amt_glb          TYPE vbsegs-dmbe2,
          lv_amt_third        TYPE vbsegs-dmbe3,
          lv_amt_func         TYPE vbsegs-wrbtr,
          lv_submitter        TYPE string,
          it_costcenter       TYPE kostl_t,
          it_accountgroup     TYPE ktoks_t,
          it_companycode      TYPE fdc_bukrs_t.

    ev_status = gc_status_err.

* Setting values of Event Name
    lv_objtype = 'CL_FDC_ACCDOC_VER'. " Class Name
    lv_event   = 'SUBMITTED'.         " Event Name

* Parked document header as handed over by BTE 00002218
    READ TABLE it_vbkpf INTO ls_vbkpf INDEX 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

* Workflow release flag (GL class: DOC_READ + DOC_WRITE). Write only,
* by the VBKPF key AUSBK / BELNR / GJAHR taken from the BTE header.
    UPDATE vbkpf
      SET xwffr = @abap_true
      WHERE ausbk = @ls_vbkpf-ausbk
        AND belnr = @ls_vbkpf-belnr
        AND gjahr = @ls_vbkpf-gjahr.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

* Account groups of the G/L lines
    IF it_vbseg IS NOT INITIAL.
      SELECT saknr, ktoks
        FROM ska1
        FOR ALL ENTRIES IN @it_vbseg
        WHERE saknr = @it_vbseg-saknr
        INTO TABLE @DATA(lt_acc_grp).
    ENDIF.

    LOOP AT it_vbseg INTO DATA(ls_item).
      IF ls_item-kostl IS NOT INITIAL.
        APPEND ls_item-kostl TO it_costcenter.
      ENDIF.

      READ TABLE lt_acc_grp INTO DATA(ls_acc_grp) WITH KEY saknr = ls_item-saknr.
      IF sy-subrc = 0 AND ls_acc_grp-ktoks IS NOT INITIAL.
        APPEND ls_acc_grp-ktoks TO it_accountgroup.
      ENDIF.
    ENDLOOP.

    APPEND ls_vbkpf-bukrs TO it_companycode.

* Amounts: sum of debit lines, as in the GL class
* ASSUMPTION: thresholds compared net of tax (debit = revenue lines).
*             For gross use the credit lines, SHKZG = 'H'.
    CLEAR: lv_amt_coc, lv_amt_glb, lv_amt_third, lv_amt_func.
    LOOP AT it_vbseg INTO DATA(ls_vbseg) WHERE shkzg = 'S'.
      lv_amt_coc   = lv_amt_coc   + ls_vbseg-dmbtr.
      lv_amt_glb   = lv_amt_glb   + ls_vbseg-dmbe2.
      lv_amt_third = lv_amt_third + ls_vbseg-dmbe3.
      lv_amt_func  = lv_amt_func  + ls_vbseg-wrbtr.
    ENDLOOP.

    DATA(lr_wf_cm) = NEW cl_fdc_accdoc_ver(
                       iv_accdocnumber           = ls_vbkpf-belnr
                       iv_sourcecompanycode      = ls_vbkpf-bukrs
                       iv_fiscalyear             = ls_vbkpf-gjahr
                       iv_amountincocdcrcy       = lv_amt_coc
                       iv_accountingdocumenttype = ls_vbkpf-blart
                       iv_amountinglobcrcy       = lv_amt_glb
                       iv_amountinthirdcrcy      = lv_amt_third
                       iv_amountinfunccrcy       = lv_amt_func
                       it_costcenter             = it_costcenter
                       it_accountgroup           = it_accountgroup
                       it_companycode            = it_companycode ).

    ls_lpor-instid = lr_wf_cm->ms_por-instid. "Get the key

    CALL METHOD cl_swf_evt_event=>get_event_container
      EXPORTING
        im_objcateg  = cl_swf_evt_event=>mc_objcateg_cl
        im_objtype   = lv_objtype
        im_event     = lv_event
      RECEIVING
        re_reference = lr_event_parameters.

    IF iv_submitter IS NOT INITIAL.
      lv_submitter = 'US' && iv_submitter.
    ELSE.
      lv_submitter = 'US' && sy-uname.
    ENDIF.

    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'AccountingDocumentType'
            value = lr_wf_cm->blart.
      CATCH cx_root.                                     "#EC CATCH_ALL
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'AmountInCompanyCodeCurrency'
            value = lr_wf_cm->dmbtr.
      CATCH cx_root.                                     "#EC CATCH_ALL
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'AmountInGlobalCurrency'
            value = lr_wf_cm->dmbe2.
      CATCH cx_root.                                     "#EC CATCH_ALL
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'AmountInThirdCurrency'
            value = lr_wf_cm->dmbe3.
      CATCH cx_root.                                     "#EC CATCH_ALL
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'AmountInFunctionalCurrency'
            value = lr_wf_cm->fcsl.
      CATCH cx_root.                                     "#EC CATCH_ALL
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'CostCenter_T'
            value = lr_wf_cm->mt_costcenter.
      CATCH cx_root.                                     "#EC CATCH_ALL
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'AccountGroup_T'
            value = lr_wf_cm->mt_accountgroup.
      CATCH cx_root.                                     "#EC CATCH_ALL
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'CompanyCode_T'
            value = lr_wf_cm->mt_companycode.
      CATCH cx_root.                                     "#EC CATCH_ALL
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'Submitter'
            value = lv_submitter.
      CATCH cx_root.                                     "#EC CATCH_ALL
    ENDTRY.

* Raise the event passing the prepared event container.
* Delivered on the caller's COMMIT WORK (Z_FI_CM_APPR_START_WF).
    TRY.
        CALL METHOD cl_swf_evt_event=>raise
          EXPORTING
            im_objcateg        = cl_swf_evt_event=>mc_objcateg_cl
            im_objtype         = lv_objtype
            im_event           = lv_event
            im_objkey          = ls_lpor-instid
            im_event_container = lr_event_parameters.
        ev_status = gc_status_ok.
      CATCH cx_swf_evt_invalid_objtype.
        ev_status = gc_status_err.
      CATCH cx_swf_evt_invalid_event.
        ev_status = gc_status_err.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
