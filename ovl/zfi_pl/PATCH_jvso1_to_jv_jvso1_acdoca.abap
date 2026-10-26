* MZFIPLF01 (SAPFZFIPL / ZFI_PL) - JVSO1 reads moved to SAP view JV_JVSO1_ACDOCA
* Paste sheet: 24 sites in two FORMs. At each site ONE line is replaced by the
* block shown under it (old line commented, new line below, BOC/EOC around).
* Find the site with Ctrl+F on the "replace" line; the INTO @DATA(...) name is
* unique inside its FORM. Nothing else in the include changes.
* Full corrected include: ovl/zfi_pl/MZFIPLF01.abap

*============================================================================
* FORM cre_prd_proj
*============================================================================

* --- 01  FORM cre_prd_proj  - replace the line:  FROM jvso1 INTO TABLE @DATA(it_jvso1)
*BOC By Arnav on 26/10/26
* JVSO1 is no longer written once JVA runs on ACDOCA (S/4HANA). JV line
* items are read through the SAP view JV_JVSO1_ACDOCA (SQL view CJVSO1_ACD),
* which exposes the JVSO1 field names: field list and WHERE are unchanged.
* ASSUMPTION: ACDOCA-VNAME is filled for every year the report is run for;
* the view returns no line for a project whose ACDOCA-VNAME is blank.
*      FROM jvso1 INTO TABLE @DATA(it_jvso1)
      FROM jv_jvso1_acdoca INTO TABLE @DATA(it_jvso1)
*EOC By Arnav on 26/10/26

* --- 02  FORM cre_prd_proj  - replace the line:  SELECT SINGLE  SUM( ksl )  FROM jvso1 INTO @DATA(vat1)
*BOC By Arnav on 26/10/26
*        SELECT SINGLE  SUM( ksl )  FROM jvso1 INTO @DATA(vat1)
        SELECT SINGLE  SUM( ksl )  FROM jv_jvso1_acdoca INTO @DATA(vat1)
*EOC By Arnav on 26/10/26

* --- 03  FORM cre_prd_proj  - replace the line:  SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_o1)
*BOC By Arnav on 26/10/26
*      SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_o1)
      SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_o1)
*EOC By Arnav on 26/10/26

* --- 04  FORM cre_prd_proj  - replace the line:  SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_g1)
*BOC By Arnav on 26/10/26
*      SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_g1)
      SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_g1)
*EOC By Arnav on 26/10/26

* --- 05  FORM cre_prd_proj  - replace the line:  SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_c1)
*BOC By Arnav on 26/10/26
*      SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_c1)
      SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_c1)
*EOC By Arnav on 26/10/26

* --- 06  FORM cre_prd_proj  - replace the line:  FROM jvso1 INTO TABLE @DATA(it_jvso2)
*BOC By Arnav on 26/10/26
*        FROM jvso1 INTO TABLE @DATA(it_jvso2)
        FROM jv_jvso1_acdoca INTO TABLE @DATA(it_jvso2)
*EOC By Arnav on 26/10/26

* --- 07  FORM cre_prd_proj  - replace the line:  SELECT SINGLE  SUM( ksl )  FROM jvso1 INTO @DATA(vat2)
*BOC By Arnav on 26/10/26
*          SELECT SINGLE  SUM( ksl )  FROM jvso1 INTO @DATA(vat2)
          SELECT SINGLE  SUM( ksl )  FROM jv_jvso1_acdoca INTO @DATA(vat2)
*EOC By Arnav on 26/10/26

* --- 08  FORM cre_prd_proj  - replace the line:  SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_o2)
*BOC By Arnav on 26/10/26
*        SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_o2)
        SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_o2)
*EOC By Arnav on 26/10/26

* --- 09  FORM cre_prd_proj  - replace the line:  SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_g2)
*BOC By Arnav on 26/10/26
*        SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_g2)
        SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_g2)
*EOC By Arnav on 26/10/26

* --- 10  FORM cre_prd_proj  - replace the line:  SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_c2)
*BOC By Arnav on 26/10/26
*        SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_c2)
        SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_c2)
*EOC By Arnav on 26/10/26

* --- 11  FORM cre_prd_proj  - replace the line:  FROM jvso1 INTO TABLE @DATA(it_jvso3)
*BOC By Arnav on 26/10/26
*        FROM jvso1 INTO TABLE @DATA(it_jvso3)
        FROM jv_jvso1_acdoca INTO TABLE @DATA(it_jvso3)
*EOC By Arnav on 26/10/26

* --- 12  FORM cre_prd_proj  - replace the line:  SELECT SINGLE  SUM( ksl )  FROM jvso1 INTO @DATA(vat3)
*BOC By Arnav on 26/10/26
*          SELECT SINGLE  SUM( ksl )  FROM jvso1 INTO @DATA(vat3)
          SELECT SINGLE  SUM( ksl )  FROM jv_jvso1_acdoca INTO @DATA(vat3)
*EOC By Arnav on 26/10/26

* --- 13  FORM cre_prd_proj  - replace the line:  SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_o3)
*BOC By Arnav on 26/10/26
*        SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_o3)
        SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_o3)
*EOC By Arnav on 26/10/26

* --- 14  FORM cre_prd_proj  - replace the line:  SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_g3)
*BOC By Arnav on 26/10/26
*        SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_g3)
        SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_g3)
*EOC By Arnav on 26/10/26

* --- 15  FORM cre_prd_proj  - replace the line:  SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_c3)
*BOC By Arnav on 26/10/26
*        SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_c3)
        SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_c3)
*EOC By Arnav on 26/10/26

* --- 16  FORM cre_prd_proj  - replace the line:  FROM jvso1 INTO TABLE @DATA(it_jvso4)
*BOC By Arnav on 26/10/26
*        FROM jvso1 INTO TABLE @DATA(it_jvso4)
        FROM jv_jvso1_acdoca INTO TABLE @DATA(it_jvso4)
*EOC By Arnav on 26/10/26

* --- 17  FORM cre_prd_proj  - replace the line:  SELECT SINGLE  SUM( ksl )  FROM jvso1 INTO @DATA(vat4)
*BOC By Arnav on 26/10/26
*          SELECT SINGLE  SUM( ksl )  FROM jvso1 INTO @DATA(vat4)
          SELECT SINGLE  SUM( ksl )  FROM jv_jvso1_acdoca INTO @DATA(vat4)
*EOC By Arnav on 26/10/26

* --- 18  FORM cre_prd_proj  - replace the line:  SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_o4)
*BOC By Arnav on 26/10/26
*        SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_o4)
        SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_o4)
*EOC By Arnav on 26/10/26

* --- 19  FORM cre_prd_proj  - replace the line:  SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_g4)
*BOC By Arnav on 26/10/26
*        SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_g4)
        SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_g4)
*EOC By Arnav on 26/10/26

* --- 20  FORM cre_prd_proj  - replace the line:  SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_c4)
*BOC By Arnav on 26/10/26
*        SELECT SINGLE SUM( ksl ) FROM jvso1 INTO @DATA(vat_c4)
        SELECT SINGLE SUM( ksl ) FROM jv_jvso1_acdoca INTO @DATA(vat_c4)
*EOC By Arnav on 26/10/26

*============================================================================
* FORM cre_non_prd
*============================================================================

* --- 21  FORM cre_non_prd  - replace the line:  FROM jvso1 INTO TABLE @DATA(it_jvso1)
*BOC By Arnav on 26/10/26
*      FROM jvso1 INTO TABLE @DATA(it_jvso1)
      FROM jv_jvso1_acdoca INTO TABLE @DATA(it_jvso1)
*EOC By Arnav on 26/10/26

* --- 22  FORM cre_non_prd  - replace the line:  FROM jvso1 INTO TABLE @DATA(it_jvso2)
*BOC By Arnav on 26/10/26
*        FROM jvso1 INTO TABLE @DATA(it_jvso2)
        FROM jv_jvso1_acdoca INTO TABLE @DATA(it_jvso2)
*EOC By Arnav on 26/10/26

* --- 23  FORM cre_non_prd  - replace the line:  FROM jvso1 INTO TABLE @DATA(it_jvso3)
*BOC By Arnav on 26/10/26
*        FROM jvso1 INTO TABLE @DATA(it_jvso3)
        FROM jv_jvso1_acdoca INTO TABLE @DATA(it_jvso3)
*EOC By Arnav on 26/10/26

* --- 24  FORM cre_non_prd  - replace the line:  FROM jvso1 INTO TABLE @DATA(it_jvso4)
*BOC By Arnav on 26/10/26
*        FROM jvso1 INTO TABLE @DATA(it_jvso4)
        FROM jv_jvso1_acdoca INTO TABLE @DATA(it_jvso4)
*EOC By Arnav on 26/10/26
