*----------------------------------------------------------------------*
* Class       : ZCL_CM_WORKFLOW
* Author      : Arnav Johri
* Date        : 15.10.2026
* Description : Copy of ZCL_GL_WORKFLOW->START_WORKFLOW for a customer
*               credit memo parked in FB70. Same code, except:
*               - PRELIMINARY_POSTING_DOC_READ removed: the tables come
*                 in from BTE 00002218 (IT_VBKPF, IT_VBSEG, IT_VBSEC);
*               - PRELIMINARY_POSTING_DOC_WRITE replaced by one UPDATE
*                 of XWFFR, because the BTE gives no VBSET and a write
*                 with an empty VBSET would delete the tax lines;
*               - the status SELECT at the end removed: it runs before
*                 the caller's COMMIT WORK and would always give 'E'.
* Create via  : ADT or SE24 source-based, paste whole file.
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
          lt_vbkpf            TYPE STANDARD TABLE OF fvbkpf,
          lt_vbseg            TYPE STANDARD TABLE OF fvbseg,
          lt_vbsec            TYPE STANDARD TABLE OF fvbsec,
          lr_event_parameters TYPE REF TO if_swf_ifs_parameter_container,
          ls_lpor             TYPE sibflpor,
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
    lv_objtype = 'CL_FDC_ACCDOC_VER'. " Your Class Name
    lv_event   = 'SUBMITTED'.  " Event Name.

* Document as handed over by BTE 00002218 (was PRELIMINARY_POSTING_DOC_READ)
    lt_vbkpf = it_vbkpf.
    lt_vbseg = it_vbseg.
    lt_vbsec = it_vbsec.

    READ TABLE  lt_vbkpf ASSIGNING FIELD-SYMBOL(<fs_vbkpf>) INDEX 1.
    IF sy-subrc EQ 0.
      <fs_vbkpf>-xwffr =  abap_true.
    ELSE.
      RETURN.
    ENDIF.

    LOOP AT lt_vbseg ASSIGNING FIELD-SYMBOL(<fs_vbseg>).
      IF <fs_vbseg>-bzalt IS INITIAL.
        <fs_vbseg>-bzalt = <fs_vbseg>-buzei.
      ENDIF.
    ENDLOOP.

* Release flag on the parked header (was PRELIMINARY_POSTING_DOC_WRITE;
* no VBSET from the BTE, so only the flag is written)
    UPDATE vbkpf
      SET xwffr = @abap_true
      WHERE ausbk = @<fs_vbkpf>-ausbk
        AND belnr = @<fs_vbkpf>-belnr
        AND gjahr = @<fs_vbkpf>-gjahr.

    IF lt_vbseg IS NOT INITIAL.
      SELECT saknr , ktoks FROM ska1 FOR ALL ENTRIES IN @lt_vbseg
        WHERE saknr = @lt_vbseg-saknr INTO TABLE @DATA(lt_acc_grp).
    ENDIF.

    LOOP AT lt_vbseg INTO DATA(ls_item).
      IF ls_item-kostl IS NOT INITIAL.
        APPEND ls_item-kostl TO it_costcenter.
      ENDIF.

      READ TABLE lt_acc_grp INTO DATA(ls_acc_grp) WITH KEY saknr = ls_item-saknr.
      IF sy-subrc EQ 0 AND ls_acc_grp-ktoks IS NOT INITIAL.
        APPEND ls_acc_grp-ktoks  TO it_accountgroup.
      ENDIF.

    ENDLOOP.

    READ TABLE lt_vbkpf INTO DATA(ls_vbkpf) INDEX 1.
    APPEND ls_vbkpf-bukrs TO it_companycode.
    CLEAR:lv_amt_coc,lv_amt_glb,lv_amt_third,lv_amt_func.
    LOOP AT lt_vbseg INTO DATA(ls_vbseg) WHERE shkzg = 'S'.
      lv_amt_coc   =  lv_amt_coc +  ls_vbseg-dmbtr.
      lv_amt_glb   =  lv_amt_glb +  ls_vbseg-dmbe2.
      lv_amt_third =  lv_amt_third +  ls_vbseg-dmbe3.
      lv_amt_func  =  lv_amt_func +  ls_vbseg-wrbtr.
    ENDLOOP.

    DATA(lr_wf_cm) = NEW cl_fdc_accdoc_ver( iv_accdocnumber = ls_vbkpf-belnr
                                    iv_sourcecompanycode = ls_vbkpf-bukrs
                                    iv_fiscalyear = ls_vbkpf-gjahr
                                    iv_amountincocdcrcy = lv_amt_coc
                                    iv_accountingdocumenttype = ls_vbkpf-blart
                                    iv_amountinglobcrcy =  lv_amt_glb
                                    iv_amountinthirdcrcy =  lv_amt_third
                                    iv_amountinfunccrcy = lv_amt_func
                                    it_costcenter = it_costcenter
                                    it_accountgroup     = it_accountgroup
                                    it_companycode   = it_companycode
                                                                        ).

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
      CATCH cx_root .
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'AmountInCompanyCodeCurrency'
            value = lr_wf_cm->dmbtr.
      CATCH cx_root .
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'AmountInGlobalCurrency'
            value = lr_wf_cm->dmbe2.
      CATCH cx_root .
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'AmountInThirdCurrency'
            value = lr_wf_cm->dmbe3.
      CATCH cx_root .
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'AmountInFunctionalCurrency'
            value = lr_wf_cm->fcsl.
      CATCH cx_root .
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'CostCenter_T'
            value = lr_wf_cm->mt_costcenter.
      CATCH cx_root .
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'AccountGroup_T'
            value = lr_wf_cm->mt_accountgroup.
      CATCH cx_root .
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'CompanyCode_T'
            value = lr_wf_cm->mt_companycode.
      CATCH cx_root .
    ENDTRY.
    TRY.
        CALL METHOD lr_event_parameters->set
          EXPORTING
            name  = 'Submitter'
            value = lv_submitter.
      CATCH cx_root .
    ENDTRY.
*
* Raise the event passing the prepared event container
* (delivered on the COMMIT WORK in Z_FI_CM_APPR_START_WF)
    TRY.
        CALL METHOD cl_swf_evt_event=>raise
          EXPORTING
            im_objcateg        = cl_swf_evt_event=>mc_objcateg_cl
            im_objtype         = lv_objtype
            im_event           = lv_event
            im_objkey          = ls_lpor-instid
            im_event_container = lr_event_parameters.
        ev_status = gc_status_ok.
      CATCH cx_swf_evt_invalid_objtype .
        ev_status = gc_status_err.
      CATCH cx_swf_evt_invalid_event .
        ev_status = gc_status_err.
    ENDTRY.

    CLEAR: lv_amt_coc,lv_amt_glb,lv_amt_third,lv_amt_func,ls_vbkpf,
           ls_lpor,lr_event_parameters,lr_wf_cm.
    REFRESH:  lt_vbkpf  ,
              lt_vbseg  ,
              lt_vbsec  ,
              it_costcenter  ,
              it_accountgroup ,
              it_companycode.
  ENDMETHOD.

ENDCLASS.
