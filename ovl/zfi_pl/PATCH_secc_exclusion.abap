* ZFI_PL / SAPFZFIPL — unmapped-G/L check: exclude secondary cost elements
* Paste sheet. Replace ONLY the first SELECT of the it_chk_gl1 block.
* Anchor: the commented line  *  SELECT saknr FROM ska1 INTO TABLE @DATA(it_chk_gl1) ...
* Everything from  IF it_chk_gl1 IS NOT INITIAL.  onwards is unchanged.

*  SELECT saknr FROM ska1 INTO TABLE @DATA(it_chk_gl1) WHERE ktopl = 'ONGC' AND xbilk = ' ' AND xloev = ' '.
*BOC By Arnav on 27/09/26
* In S/4HANA secondary cost elements are G/L accounts (SKA1, account group
* SECC, account type S). They are not balance-sheet accounts, so the check
* below listed them as unmapped P&L G/Ls. ECC had no such SKA1 rows. The
* OVL trial balance excludes them, so they are excluded from this check.
* ASSUMPTION: I_GLAccountInChartOfAccounts exposes SKA1-KTOKS as GLAccountGroup.
*  SELECT GLAccount               AS saknr
*    FROM I_GLAccountInChartOfAccounts
*    INTO TABLE @DATA(it_chk_gl1)
*    WHERE ChartOfAccounts          = 'ONGC'
*      AND IsBalanceSheetAccount    = ' '
*      AND AccountIsMarkedForDeletion = ' '.
  SELECT GLAccount               AS saknr
    FROM I_GLAccountInChartOfAccounts
    INTO TABLE @DATA(it_chk_gl1)
    WHERE ChartOfAccounts          = 'ONGC'
      AND IsBalanceSheetAccount    = ' '
      AND AccountIsMarkedForDeletion = ' '
      AND GLAccountGroup          <> 'SECC'.
*EOC By Arnav on 27/09/26
