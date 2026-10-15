* Reference copy, as pasted by Arnav on 14/10/26. Existing object, not ours. Do not edit.
  METHOD start_workflow..
** Data Declarations
    DATA: lv_objtype          TYPE sibftypeid,
          lv_app_id           TYPE sibfboriid,
          lv_event            TYPE sibfevent,
          lt_vbkpf            TYPE STANDARD TABLE OF fvbkpf,
          lt_vbseg            TYPE STANDARD TABLE OF fvbseg,
          lt_vbsec            TYPE STANDARD TABLE OF fvbsec,
          lt_vbset            TYPE STANDARD TABLE OF fvbset,
          lr_event_parameters TYPE REF TO if_swf_ifs_parameter_container,
          lv_param_name       TYPE swfdname,
          lv_id               TYPE char10,
          ls_lpor             TYPE sibflpor,
          lv_amt_coc          TYPE vbsegs-dmbtr,
          lv_amt_glb          TYPE vbsegs-dmbe2,
          lv_amt_third        TYPE vbsegs-dmbe3,
          lv_amt_func         TYPE vbsegs-wrbtr,
          it_costcenter	      TYPE kostl_t,
          it_accountgroup	    TYPE ktoks_t,
          it_companycode      TYPE fdc_bukrs_t.

* Setting values of Event Name
    lv_objtype = 'CL_FDC_ACCDOC_VER'. " Your Class Name
    lv_event   = 'SUBMITTED'.  " Event Name.

    CALL FUNCTION 'PRELIMINARY_POSTING_DOC_READ'
      EXPORTING
        belnr                   = journal_entry
        bukrs                   = source_company_code
        gjahr                   = fiscal_year
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
    .
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    READ TABLE  lt_vbkpf ASSIGNING FIELD-SYMBOL(<fs_vbkpf>) INDEX 1.
    IF sy-subrc EQ 0.
      <fs_vbkpf>-xwffr =  abap_true.
    ENDIF.

    LOOP AT lt_vbseg ASSIGNING FIELD-SYMBOL(<fs_vbseg>).
      IF <fs_vbseg>-bzalt IS INITIAL.
        <fs_vbseg>-bzalt = <fs_vbseg>-buzei.
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
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    SELECT saknr , ktoks FROM ska1 INTO TABLE @DATA(lt_acc_grp) FOR ALL ENTRIES IN @lt_vbseg WHERE saknr = @lt_vbseg-saknr.

    LOOP AT lt_vbseg INTO DATA(ls_item).
      IF ls_item-kostl IS NOT INITIAL.
        APPEND ls_item-kostl TO it_costcenter.
      ENDIF.

      READ TABLE lt_acc_grp INTO DATA(ls_acc_grp) WITH KEY saknr = ls_item-saknr.
      IF ls_acc_grp-ktoks IS NOT INITIAL.
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

    DATA(lr_wf_gl) = NEW cl_fdc_accdoc_ver( iv_accdocnumber = journal_entry
                                    iv_sourcecompanycode = source_company_code
                                    iv_fiscalyear = fiscal_year
                                    iv_amountincocdcrcy = lv_amt_coc
                                    iv_accountingdocumenttype = ls_vbkpf-blart
                                    iv_amountinglobcrcy =  lv_amt_glb
                                    iv_amountinthirdcrcy =  lv_amt_third
                                    iv_amountinfunccrcy = lv_amt_func
                                    it_costcenter	= it_costcenter
                                    it_accountgroup	    = it_accountgroup
                                    it_companycode   = it_companycode
                                                                        ).

    ls_lpor-instid = lr_wf_gl->ms_por-instid. "Get the key

    CALL METHOD cl_swf_evt_event=>get_event_container
      EXPORTING
        im_objcateg  = cl_swf_evt_event=>mc_objcateg_cl
        im_objtype   = lv_objtype
        im_event     = lv_event
      RECEIVING
        re_reference = lr_event_parameters.

*   (nine TRY ... lr_event_parameters->set( name = ... value = ... ) ... CATCH cx_root. ENDTRY.
*    blocks follow in the original, each with a TEST-SEAM. Element names and sources:)
*     'AccountingDocumentType'       lr_wf_gl->blart
*     'AmountInCompanyCodeCurrency'  lr_wf_gl->dmbtr
*     'AmountInGlobalCurrency'       lr_wf_gl->dmbe2
*     'AmountInThirdCurrency'        lr_wf_gl->dmbe3
*     'AmountInFunctionalCurrency'   lr_wf_gl->fcsl
*     'CostCenter_T'                 lr_wf_gl->mt_costcenter
*     'AccountGroup_T'               lr_wf_gl->mt_accountgroup
*     'CompanyCode_T'                lr_wf_gl->mt_companycode
*     'Submitter'                    'US' && sy-uname

* Raise the event passing the prepared event container
    TRY.
        CALL METHOD cl_swf_evt_event=>raise
          EXPORTING
            im_objcateg        = cl_swf_evt_event=>mc_objcateg_cl
            im_objtype         = lv_objtype
            im_event           = lv_event
            im_objkey          = ls_lpor-instid
            im_event_container = lr_event_parameters.

*        COMMIT WORK.
      CATCH cx_swf_evt_invalid_objtype .
      CATCH cx_swf_evt_invalid_event .
    ENDTRY.
*Check if workflow successfully started
    IF multiple_wf EQ abap_true.
      WAIT UP TO 10 SECONDS.
    ENDIF.

    CLEAR:lv_app_id.
    lv_app_id = ls_lpor-instid.

*    SELECT SINGLE status FROM swfflexivproc
*                         WHERE applicationobjectid = @lv_app_id AND
*                               scenarioid = 'WS02800046'
*                         INTO @DATA(lv_status).
    SELECT SINGLE taskprocessingstatus,parkedbyuser FROM c_gljrnlentrytobeverified WHERE accountingdocument = @journal_entry AND
                                   companycode = @source_company_code AND fiscalyear = @fiscal_year
                             INTO (@DATA(lv_status) , @DATA(lv_user)).
    IF sy-subrc NE 0.
      status = 'E'.
    ELSE.
      IF lv_status = 'ERROR'.
        status = 'E'.
      ELSE.
        DATA(lo_wf_gl_agent) = NEW zcl_agent_gl(  ).

        DATA: lv_initiator TYPE ppnam,
              lv_sobjid    TYPE hrp1001-sobid.

        CLEAR:lv_sobjid.
        lv_initiator = lv_user.
        lo_wf_gl_agent->get_agent(
                                  EXPORTING
                                  initiator  = lv_initiator
                                  IMPORTING
                                  objid      = lv_sobjid
                             ).

        IF lv_sobjid IS NOT INITIAL.
          status = 'S'.
        ENDIF.
      ENDIF.
    ENDIF.

    CLEAR: lv_amt_coc,lv_amt_glb,lv_amt_glb,lv_amt_func,ls_vbkpf,
           ls_lpor,lr_event_parameters,lv_initiator,lv_sobjid,lv_status,lv_user,lr_wf_gl.
    REFRESH:  lt_vbkpf  ,
              lt_vbseg  ,
              lt_vbsec  ,
              lt_vbset  ,
              it_costcenter  ,
              it_accountgroup ,
              it_companycode.
  ENDMETHOD.
