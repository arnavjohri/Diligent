* Reference copy, as pasted by Arnav on 15/10/26. Existing object, not ours. Do not edit.
  METHOD get_agent.

    DATA(lv_usrname) = initiator.

    DATA: lv_sobjid   TYPE hrp1001-sobid,
          lv_appr_lvl TYPE i.

    SELECT pernr,usrid FROM pa0105 WHERE endda = '99991231' AND
                                            subty = '0001'
                                      INTO TABLE @DATA(lt_pa0105).
    IF sy-subrc EQ 0.

      SELECT otype,objid,rsign,relat,sclas,subty, sobid FROM hrp1001 WHERE otype IN ('P','S') AND
                                                              relat IN ('002','008') AND
                                                              endda = '99991231' AND
                                                              sclas IN ('P','S')
                                                        INTO TABLE @DATA(lt_hrp1001).
      IF sy-subrc EQ 0.

        READ TABLE lt_pa0105 INTO DATA(ls_pa0105) WITH KEY usrid = lv_usrname.
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
                lv_sobjid = ls_hrp1001-sobid.                " Manager
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
    IF lv_sobjid IS NOT INITIAL.
      objid = lv_sobjid.
    ENDIF.
  ENDMETHOD.
