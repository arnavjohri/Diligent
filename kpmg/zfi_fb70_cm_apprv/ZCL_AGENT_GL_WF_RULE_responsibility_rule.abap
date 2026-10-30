  METHOD if_rsm_badi_static_rule~responsibility_rule.

**-->variables
    DATA: lv_belnr    TYPE belnr_d,
          lv_gjahr    TYPE gjahr,
          lv_bukrs    TYPE bukrs,
          lv_usrname  TYPE ppnam,
          lv_sobjid   TYPE hrp1001-sobid,
          lv_objid    TYPE hrp1001-objid,
          lv_zseq     TYPE poper,
*          lv_iteartion         TYPE i,
          lv_appr_lvl TYPE i,
          lv_instid   TYPE sibfboriid.

    DATA: lv_user TYPE sy-uname.
    DATA: lt_swr_messag TYPE STANDARD TABLE OF swr_messag.
    DATA: lt_swr_mstruc TYPE STANDARD TABLE OF swr_mstruc.

**-->References
    DATA:
      lo_agt_detn_fail TYPE REF TO cx_rsm_agt_detn_tech_exception.

    FIELD-SYMBOLS : <fs_value> TYPE any.
    LOOP AT it_parameter_name_value_pair ASSIGNING FIELD-SYMBOL(<fs_parameter_name_value_pair>).
      CASE <fs_parameter_name_value_pair>-name.
        WHEN 'ACCOUNTINGDOCUMENT'.
          ASSIGN <fs_parameter_name_value_pair>-value->* TO <fs_value>.
          lv_belnr = <fs_value>.
        WHEN 'COMPANYCODE'.
          ASSIGN <fs_parameter_name_value_pair>-value->* TO <fs_value>.
          lv_bukrs = <fs_value>.
        WHEN 'APPROVERLEVEL'.
          ASSIGN <fs_parameter_name_value_pair>-value->* TO <fs_value>.
          lv_zseq = <fs_value>.
        WHEN 'ACCOUNTINGDOCCREATEDBYUSER'.
          ASSIGN <fs_parameter_name_value_pair>-value->* TO <fs_value>.
          lv_usrname = <fs_value>.
        WHEN 'FISCALYEAR'.
          ASSIGN <fs_parameter_name_value_pair>-value->* TO <fs_value>.
          lv_gjahr = <fs_value>.

      ENDCASE.
      UNASSIGN:<fs_value>.
    ENDLOOP.

    IF lv_belnr IS NOT INITIAL.

      SELECT pernr,subty,endda,usrid FROM pa0105 WHERE endda GE @sy-datum AND
                                                       subty IN ( '0001', '0002' , '0003' )
                                     INTO TABLE @DATA(lt_pa0105).
      IF sy-subrc EQ 0.

        SELECT zpm_low,zpm_high FROM zglbparam INTO TABLE @DATA(lt_hr_jbkey) WHERE zparam_id = 'ZHR_JOBKEY_WF'.

        SELECT otype,objid,rsign,relat,sclas,subty,sobid FROM hrp1001
                                                         WHERE  otype = 'S' AND
                                                                relat = '007' AND
                                                                endda GE @sy-datum AND
                                                                sclas = 'C'
                                                         INTO TABLE @DATA(lt_hrp1001_jb).

        SELECT objid,stext FROM hrp1000  WHERE  plvar = '01' AND
                                                otype = 'C' AND
                                                istat = '1' AND
                                                langu = @sy-langu AND
                                                endda GE @sy-datum
                                            INTO TABLE @DATA(lt_hrp1000_jb).

        SORT lt_pa0105 BY endda DESCENDING.
        SELECT otype,objid,rsign,relat,sclas,subty,sobid FROM hrp1001 WHERE otype IN ('P','S') AND
                                                                relat IN ('002','008') AND
                                                                endda GE @sy-datum AND
                                                                sclas IN ('P','S')
                                                          INTO TABLE @DATA(lt_hrp1001).

        IF sy-subrc EQ 0.

          CASE lv_zseq.
            WHEN '001'.
              lv_appr_lvl = 1.
            WHEN '002'.
              lv_appr_lvl = 2.
            WHEN '003'.
              lv_appr_lvl = 3.
            WHEN '004'.
              lv_appr_lvl = 4.
            WHEN '005'.
              lv_appr_lvl = 5.
            WHEN OTHERS.
          ENDCASE.

          READ TABLE lt_pa0105 INTO DATA(ls_pa0105) WITH KEY  subty = '0001'
                                                              usrid = lv_usrname.
          IF sy-subrc EQ 0.
            READ TABLE lt_hrp1001 INTO DATA(ls_hrp1001) WITH KEY otype = 'P'
                                                                 objid = ls_pa0105-pernr
                                                                 relat = '008'
                                                                 sclas = 'S'.
            IF sy-subrc EQ 0.
              lv_sobjid = ls_hrp1001-sobid.
              READ TABLE lt_hrp1001 INTO ls_hrp1001 WITH KEY otype = 'S'
                                                             objid = lv_sobjid
                                                             rsign = 'A'
                                                             relat = '002'
                                                             sclas = 'S'
                                                             subty = 'A002'.
              IF sy-subrc EQ 0.
                lv_sobjid = ls_hrp1001-sobid.
                READ TABLE lt_hrp1001 INTO ls_hrp1001 WITH KEY otype = 'S'
                                                               objid = lv_sobjid
                                                               relat = '008'
                                                               sclas = 'P'.
                IF sy-subrc EQ 0.
                  lv_sobjid = ls_hrp1001-sobid.                " Immediate Supervisor
                ELSE.
                  CLEAR:lv_sobjid.
                ENDIF.
              ELSE.
                CLEAR:lv_sobjid.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

      APPEND INITIAL LINE TO et_agents ASSIGNING FIELD-SYMBOL(<fs_agent>).

      READ TABLE lt_pa0105 INTO ls_pa0105 WITH KEY subty = '0001'
                                                   pernr = lv_sobjid.
      IF sy-subrc EQ 0 AND lv_appr_lvl = 1.
        <fs_agent> = ls_pa0105-usrid.
      ELSE.

        CONCATENATE lv_belnr lv_bukrs lv_gjahr INTO lv_instid.
        CONDENSE lv_instid.

        SELECT wi_id FROM sww_wi2obj INTO TABLE @DATA(lt_wi_id) WHERE instid = @lv_instid AND wi_rh_task = 'TS02800035'.
        IF sy-subrc EQ 0.

          SELECT wi_id,wi_aagent,wi_cd,wi_ct
            FROM swwwihead
            INTO TABLE @DATA(lt_last_approver)
            FOR ALL ENTRIES IN @lt_wi_id
            WHERE wi_id = @lt_wi_id-wi_id AND wi_type = 'W'
              AND wi_stat = 'COMPLETED' AND wi_rh_task = 'TS02800035' AND step_id = 'Verify'.

          IF sy-subrc EQ 0.

            SORT lt_last_approver BY wi_cd DESCENDING wi_ct DESCENDING.
            READ TABLE lt_last_approver INTO DATA(ls_last_approver) INDEX 1.
            IF sy-subrc EQ 0.
****Logic to check in case of substitution where low level approver approves on behalf of higher level Approver
              SELECT * FROM swwwipagent INTO TABLE @DATA(lt_ptn_agent) WHERE wi_id = @ls_last_approver-wi_id.
              IF sy-subrc EQ 0.
                DESCRIBE TABLE lt_ptn_agent LINES DATA(lv_pt_agnt).
                IF lv_pt_agnt GT 1.

                  SORT lt_hr_jbkey BY zpm_high DESCENDING.
                  LOOP AT lt_hr_jbkey INTO DATA(ls_hr_jbkey).
                    LOOP AT lt_ptn_agent INTO DATA(ls_ptn_agent).
                      READ TABLE lt_hrp1001 INTO ls_hrp1001 WITH KEY otype = 'P'
                                                                           objid = ls_ptn_agent-user_id
                                                                           relat = '008'
                                                                           sclas = 'S'.
                      IF sy-subrc EQ 0.
                        READ TABLE lt_hrp1001_jb INTO DATA(ls_hrp1001_jb) WITH KEY otype = 'S'
                                                                       objid = ls_hrp1001-sobid
                                                                       relat = '007'
                                                                       sclas = 'C'.
                        IF sy-subrc EQ 0.
                          IF ls_hrp1001_jb-sobid = ls_hr_jbkey-zpm_low.
                            DATA(lv_agent) = ls_ptn_agent-user_id.
                            EXIT.
                          ENDIF.
                        ENDIF.
                      ENDIF.
                    ENDLOOP.
                    IF lv_agent IS NOT INITIAL.
                      IF lv_agent NE ls_last_approver-wi_aagent.
                        ls_last_approver-wi_aagent = lv_agent.
                        EXIT.
                      ENDIF.
                      IF lv_agent EQ ls_last_approver-wi_aagent.
                        EXIT.
                      ENDIF.
                    ENDIF.
                  ENDLOOP.
                ENDIF.
              ENDIF.

              READ TABLE lt_pa0105 INTO DATA(ls_pa0105_1) WITH KEY subty = '0001'
                                                                   usrid = ls_last_approver-wi_aagent.


              IF sy-subrc EQ 0.
                lv_sobjid = ls_pa0105_1-pernr.
                READ TABLE lt_hrp1001 INTO ls_hrp1001 WITH KEY otype = 'P'
                                                               objid = lv_sobjid
                                                               relat = '008'
                                                               sclas = 'S'.
                IF sy-subrc EQ 0.
                  lv_sobjid = ls_hrp1001-sobid.
                  READ TABLE lt_hrp1001 INTO ls_hrp1001 WITH KEY otype = 'S'
                                                                 objid = lv_sobjid
                                                                 rsign = 'A'
                                                                 relat = '002'
                                                                 sclas = 'S'.
                  IF sy-subrc EQ 0.
                    lv_sobjid = ls_hrp1001-sobid.
                    READ TABLE lt_hrp1001 INTO ls_hrp1001 WITH KEY otype = 'S'
                                                                   objid = lv_sobjid
                                                                   relat = '008'
                                                                   sclas = 'P'.
                    IF sy-subrc EQ 0.
                      lv_sobjid = ls_hrp1001-sobid.
                      READ TABLE lt_pa0105 INTO ls_pa0105 WITH KEY subty = '0001'
                                                                   pernr = lv_sobjid.
                      IF sy-subrc EQ 0.
                        <fs_agent> = ls_pa0105-usrid.
                      ENDIF.
                    ENDIF.
                  ENDIF.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.


      SELECT zpm_low,zdesc FROM zglbparam INTO TABLE @DATA(lt_lst_appr) WHERE zparam_id = 'ZJV_FINAL_APPR_POS'.

      lv_objid = ls_last_approver-wi_aagent.

      READ TABLE lt_hrp1001 INTO ls_hrp1001 WITH KEY otype = 'P'
                                                     objid = lv_objid
                                                     relat = '008'
                                                     sclas = 'S'.
      IF sy-subrc EQ 0.
        lv_objid = ls_hrp1001-sobid.
        READ TABLE lt_hrp1001_jb INTO ls_hrp1001_jb WITH KEY otype = 'S'
                                                       objid = lv_objid
                                                       relat = '007'
                                                       sclas = 'C'.
        IF sy-subrc EQ 0.
          lv_objid = ls_hrp1001_jb-sobid.
          READ TABLE lt_hrp1000_jb INTO DATA(ls_hrp1000_jb) WITH KEY objid = lv_objid.
          READ TABLE lt_lst_appr INTO DATA(ls_lst_appr) WITH KEY zpm_low = ls_hrp1000_jb-objid.
          IF ls_lst_appr IS NOT INITIAL AND ls_hrp1000_jb IS NOT INITIAL.

            <fs_agent> = ls_last_approver-wi_aagent.
            lv_user = <fs_agent>.

            SELECT SINGLE wi_chckwi FROM swwwihead INTO @DATA(lv_top_wi_id)
                                                   WHERE wi_id = @ls_last_approver-wi_id.

            IF lv_top_wi_id IS NOT INITIAL.

              CALL FUNCTION 'Z_JV_MASSGL_WF' STARTING NEW TASK 'TASK_ID'
                DESTINATION 'NONE'
                EXPORTING
                  im_workitem_id  = lv_top_wi_id
                  im_language     = sy-langu
                  im_user         = lv_user
                  im_decision_key = 0001
                TABLES
                  message_lines   = lt_swr_messag
                  message_struct  = lt_swr_mstruc.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

*BOC By Arnav on 30/10/26
* CM approval mails (FS 30/10/26): kind P at level 1 (parked), kind A at
* level 2 / 3 (approved by the previous level), to the initiator and the
* agent determined above. Credit memos only; the JV upload is untouched.
* Not sent on the final-approver auto-approve branch (ls_lst_appr set).
* The COMMIT is inside Z_CM_WF_MAIL_SEND, which runs in its own task like
* Z_JV_MASSGL_WF above. Duplicate guard below via SWW_WI2OBJ.
* ASSUMPTION: credit memo document type 'DG', same constant as the BTE
*   module and the POST enhancement.
      DATA: lv_cm_blart  TYPE blart,
            lv_cm_kind   TYPE char1,
            lv_cm_level  TYPE numc2,
            lv_cm_task   TYPE char32,
            lv_cm_instid TYPE sibfboriid,
            lv_cm_wicnt  TYPE i.

      IF <fs_agent> IS NOT INITIAL AND lv_appr_lvl > 0 AND ls_lst_appr IS INITIAL.
        SELECT SINGLE blart
          FROM vbkpf
          WHERE ausbk = @lv_bukrs
            AND belnr = @lv_belnr
            AND gjahr = @lv_gjahr
          INTO @lv_cm_blart.

* Duplicate guard without a Z table: the Verify work items already created
* for this document. First determination of level n sees n-1 of them; a
* re-determination, forward or restart sees n and sends nothing.
        CONCATENATE lv_belnr lv_bukrs lv_gjahr INTO lv_cm_instid.
        CONDENSE lv_cm_instid.
        SELECT COUNT( * )
          FROM sww_wi2obj
          WHERE instid     = @lv_cm_instid
            AND wi_rh_task = 'TS02800035'
          INTO @lv_cm_wicnt.

        IF sy-subrc = 0 AND lv_cm_blart = 'DG' AND lv_cm_wicnt < lv_appr_lvl.
          lv_cm_level = lv_appr_lvl.
          IF lv_appr_lvl = 1.
            lv_cm_kind = zcl_cm_workflow=>gc_mail_parked.
          ELSE.
            lv_cm_kind = zcl_cm_workflow=>gc_mail_approval.
          ENDIF.
          lv_cm_task = |CMMAIL{ lv_belnr }{ lv_cm_level }|.

          CALL FUNCTION 'Z_CM_WF_MAIL_SEND' STARTING NEW TASK lv_cm_task
            DESTINATION 'NONE'
            EXPORTING
              iv_bukrs     = lv_bukrs
              iv_belnr     = lv_belnr
              iv_gjahr     = lv_gjahr
              iv_kind      = lv_cm_kind
              iv_level     = lv_cm_level
              iv_approver  = <fs_agent>
              iv_initiator = lv_usrname.
        ENDIF.
      ENDIF.
*EOC By Arnav on 30/10/26

      CLEAR:ls_hrp1001,ls_hrp1001_jb,ls_hrp1000_jb,
    ls_lst_appr,ls_last_approver,lv_objid,lv_sobjid.

    ENDIF.
  ENDMETHOD.
