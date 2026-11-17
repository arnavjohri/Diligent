//----------------------------------------------------------------------
// Object    : ZI_BR_HOUSEBANKACCT (DDL source, classic view)
// Purpose   : Bank revaluation for Group Reporting (OVL) - helper for
//             ZI_BR_BANKREVAL_ITM. One row per house bank account
//             (T012K) with the G/L account normalised to the 10-digit
//             internal form, so the join to the line items matches
//             whether T012K-HKONT was stored with or without leading
//             zeros (03/11/26: house bank came back blank although the
//             T012K row for OVL / HB101 / 96488 exists).
// Author    : Arnav Johri
// Date      : 03.11.2026
//----------------------------------------------------------------------
// ASSUMPTION: G/L accounts at OVL are numeric (SAKNR with ALPHA), so a
//   left pad with '0' to 10 characters yields the ACDOCA value. A blank
//   HKONT becomes '0000000000' and matches nothing.
// 03/11/26 v2: T012K is a redirected table on this release (SE16N header:
//   Proxy Object V_T012K_BAM, "T012K Compatibility View"). ABAP SQL and
//   SE16N read the compatibility view over Bank Account Management (57
//   accounts, HB101.. for OVL); a CDS select from t012k reads the physical
//   table, which holds only the old ECC entries (HB_01..HB_09, 100 rows).
//   Source switched to the compatibility view; field names are identical.
// ASSUMPTION: V_T012K_BAM is the CDS entity name of the replacement
//   object (SE11 -> T012K -> Extras -> Proxy Object). If activation says
//   it is unknown, read the entity name there and substitute it.
// 17/11/26 v3: one row per company code + G/L account. BAM holds two
//   account IDs for G/L 95312 (HB130 and HB131), so every line item of
//   that account joined twice and the query showed 95312 on two rows
//   with the full balance on each (testing sheet 16/11/26, Khyati Sharma).
//   Any G/L with two BAM rows under the same account ID would have been
//   doubled without a visible second row (suspected for 93201, HB001).
//   Grouped by company code + G/L; house bank, account ID, bank account
//   number and currency are the MIN over the rows of that G/L, so a G/L
//   with two account IDs shows the alphabetically first one (95312: HB130).
//   The ITM join (CompanyCode + GLAccount) and the cube are unchanged.
// ASSUMPTION: V_T012K_BAM-HKONT is stored in the 10-digit internal form
//   (SE16N on 03/11/26 showed the unconverted value 0000096488), so the
//   lpad is not needed and the view groups on the raw field - a function
//   in the select list of a grouped classic view was not risked. If a
//   mapped G/L ever comes back without house bank, check the stored
//   HKONT of its BAM row; an unpadded value needs the lpad back in a
//   second helper on top of this one.
//----------------------------------------------------------------------
@AbapCatalog.sqlViewName: 'ZIBRHBANKACCT'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Bank Revaluation - house bank account per G/L'
@VDM.viewType: #BASIC
@ClientHandling.algorithm: #SESSION_VARIABLE
define view ZI_BR_HOUSEBANKACCT
  //BOC By Arnav on 03/11/26
  //  as select from t012k
  as select from V_T012K_BAM
  //EOC By Arnav on 03/11/26
{
  //BOC By Arnav on 17/11/26 - one row per company code + G/L account
  //  key bukrs                    as CompanyCode,
  //  key hbkid                    as HouseBank,
  //  key hktid                    as HouseBankAccount,
  //      lpad( hkont, 10, '0' )   as GLAccount,
  //      bankn                    as BankAccountNumber,
  //      @Semantics.currencyCode: true
  //      waers                    as BankAccountCurrency
  key bukrs                    as CompanyCode,
  key hkont                    as GLAccount,
      min( hbkid )             as HouseBank,
      min( hktid )             as HouseBankAccount,
      min( bankn )             as BankAccountNumber,
      @Semantics.currencyCode: true
      min( waers )             as BankAccountCurrency
  //EOC By Arnav on 17/11/26 - one row per company code + G/L account
}
//BOC By Arnav on 17/11/26 - one row per company code + G/L account
group by
  bukrs,
  hkont
//EOC By Arnav on 17/11/26 - one row per company code + G/L account
