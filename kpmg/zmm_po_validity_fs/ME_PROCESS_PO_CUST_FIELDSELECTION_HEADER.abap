METHOD IF_EX_ME_PROCESS_PO_CUST~FIELDSELECTION_HEADER.
  FIELD-SYMBOLS: <FS> LIKE LINE OF CH_FIELDSELECTION.
*BOC By Arnav on 12/10/26
* Validity Start / Validity End (EKKO-KDATB / KDATE, Additional Data tab)
* are shown only for the PO document types listed in TVARVC variable
* ZPO_VALIDITY_DOCTYPE (selection option, e.g. I EQ SBP). Every other
* document type gets them hidden. Field status in the merged result is
* the most restrictive one, so hiding here wins over NBF customizing.
* Metafields MMMFD_VALID_FROM (037, EKKO-KDATB) and MMMFD_VALID_TO (038,
* EKKO-KDATE) confirmed in type group MMMFD on 12/10/26. Not the item-level
* MMMFD_VALID_STARTDATE / _ENDDATE (851/852), which are lean-service dates.
  CONSTANTS: lc_validity_var TYPE rvari_vnam VALUE 'ZPO_VALIDITY_DOCTYPE',
             lc_selopt       TYPE rsscr_kind VALUE 'S'.

  DATA: lr_bsart    TYPE RANGE OF ekko-bsart,
        lv_validity TYPE mmpur_fs-fieldstatus VALUE '-'.

  DATA(ls_header) = im_header->get_data( ).

  SELECT sign, opti AS option, low, high
    FROM tvarvc
    WHERE name = @lc_validity_var
      AND type  = @lc_selopt
    INTO TABLE @lr_bsart.

  IF lr_bsart IS NOT INITIAL AND ls_header-bsart IN lr_bsart.
    lv_validity = '.'.          " optional for the listed types
  ENDIF.
*EOC By Arnav on 12/10/26

  LOOP AT CH_FIELDSELECTION ASSIGNING <FS>.
    IF <FS>-METAFIELD = 90000131 OR <FS>-METAFIELD = 90000132 OR
       <FS>-METAFIELD = 90000143 OR <FS>-METAFIELD = 90000148 OR
       <FS>-METAFIELD = 90000121.
      <FS>-FIELDSTATUS = '+'.
*BOC By Arnav on 12/10/26
    ELSEIF <FS>-METAFIELD = mmmfd_valid_from OR
           <FS>-METAFIELD = mmmfd_valid_to.
      <FS>-FIELDSTATUS = lv_validity.
*EOC By Arnav on 12/10/26
    ELSE.
      <FS>-FIELDSTATUS = '.'.
    ENDIF.
  ENDLOOP.
ENDMETHOD.
