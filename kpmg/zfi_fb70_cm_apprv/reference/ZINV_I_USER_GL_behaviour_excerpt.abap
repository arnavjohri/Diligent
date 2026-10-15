* Reference excerpt, as pasted by Arnav on 15/10/26. Existing object, not ours. Do not edit.
* Full behaviour implementation of ZINV_I_USER_GL (handler lhc_xlhead + saver
* lsc_zinv_i_user_gl) was pasted in chat; only the workflow-relevant part of
* lsc_zinv_i_user_gl->save_modified is kept here.
*
* Sequence per document id in the uploaded file, after validation passed:
*   1. ls_doc_header-doc_status = '2'.                      "park, not post
*   2. CALL FUNCTION 'Z_ACC_DOC_POST' DESTINATION 'NONE'     "or Z_ACC_DOC_POST_MCR
*        ... IMPORTING obj_key ... TABLES ... objkey_split return.
*   3. For every obj_key (BELNR(10) BUKRS(4) GJAHR(4)) with no A/E message:
*
                  DATA(lr_gl_workflow) = NEW zcl_gl_workflow( ).

                  CALL METHOD lr_gl_workflow->start_workflow(
                    EXPORTING
                      journal_entry       = lv_jnl_entry
                      source_company_code = lv_comp_code
                      fiscal_year         = lv_fiscal_year
                      multiple_wf         = lv_multiple_wf     "only > 950 lines
                    IMPORTING
                      status              = lv_status_wf ).

                  IF lv_status_wf = 'E'.
                    CALL FUNCTION 'Z_BAPI_TRANSACTION_ROLLBACK' DESTINATION 'NONE'.
                    ...log 'Workflow error for document id &'...
                  ENDIF.
*
* No amount threshold, no document type check anywhere in the behaviour implementation.
