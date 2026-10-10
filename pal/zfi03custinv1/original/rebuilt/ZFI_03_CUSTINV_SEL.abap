*&---------------------------------------------------------------------*
*& Include ZFI_03_CUSTINV_SEL
*&---------------------------------------------------------------------*

*&----------------------------------------------------------------------------------------------*
*&        SELECT-OPTIONS/PARAMETERS                                                             *
*&----------------------------------------------------------------------------------------------*
*&  You can use this section to declare selection tables and fields                             *
*&----------------------------------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK blk1
  WITH FRAME TITLE TEXT-001.
  PARAMETERS p_rbukrs TYPE acdoca-rbukrs OBLIGATORY.
  SELECT-OPTIONS so_belnr FOR acdoca-belnr.
  SELECT-OPTIONS so_blart FOR acdoca-blart.
  PARAMETERS p_gjahr TYPE acdoca-gjahr OBLIGATORY.
  SELECT-OPTIONS so_kunnr FOR acdoca-kunnr.
  PARAMETERS p_cag TYPE but000-bu_group.
  SELECT-OPTIONS so_bldat FOR acdoca-bldat.
  PARAMETERS cb_print AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK blk1.

SELECTION-SCREEN BEGIN OF BLOCK blk2
  WITH FRAME TITLE TEXT-002.
  PARAMETERS: p_hbank TYPE hbkid,
              p_accid TYPE hktid.
  PARAMETERS p_billto AS LISTBOX VISIBLE LENGTH 255.
SELECTION-SCREEN END OF BLOCK blk2.

SELECTION-SCREEN BEGIN OF BLOCK blk3
  WITH FRAME TITLE TEXT-003.
  PARAMETERS: rb_view  RADIOBUTTON GROUP g1 USER-COMMAND test,
              rb_print RADIOBUTTON GROUP g1,
              rb_pdf   RADIOBUTTON GROUP g1,
              p_path   TYPE string,
              rb_email RADIOBUTTON GROUP g1,
              cb_late  AS CHECKBOX USER-COMMAND test.
SELECTION-SCREEN END OF BLOCK blk3.
