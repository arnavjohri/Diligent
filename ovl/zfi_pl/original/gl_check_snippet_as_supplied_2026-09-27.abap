*  SELECT saknr FROM ska1 INTO TABLE @DATA(it_chk_gl1) WHERE ktopl = 'ONGC' AND xbilk = ' ' AND xloev = ' '.
  SELECT GLAccount               AS saknr
    FROM I_GLAccountInChartOfAccounts
    INTO TABLE @DATA(it_chk_gl1)
    WHERE ChartOfAccounts          = 'ONGC'
      AND IsBalanceSheetAccount    = ' '
      AND AccountIsMarkedForDeletion = ' '.

  IF it_chk_gl1 IS NOT INITIAL.
*    SELECT saknr FROM skb1 INTO TABLE @DATA(it_chk_gl2)
*                  FOR ALL ENTRIES IN @it_chk_gl1 WHERE saknr = @it_chk_gl1-saknr AND bukrs = @p_comp1 AND xloeb = ' '.
    SELECT GLAccount               AS saknr
      FROM I_GLAccountInCompanyCode
      INTO TABLE @DATA(it_chk_gl2)
      FOR ALL ENTRIES IN @it_chk_gl1
      WHERE GLAccount              = @it_chk_gl1-saknr
        AND CompanyCode            = @p_comp1
        AND AccountIsBlockedForPosting = ' '.
    "Code Remediation changes S4 2025 Conversion End of change SAP_ABAP and 12.06.2026
    IF it_chk_gl2 IS NOT INITIAL.
      SELECT * FROM zfi_pnl_gl INTO TABLE @DATA(it_gls).

      IF it_gls IS NOT INITIAL.
        LOOP AT it_gls  INTO DATA(wa_gls).
          DELETE it_chk_gl2 WHERE saknr = wa_gls-gl_acct.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDIF.
