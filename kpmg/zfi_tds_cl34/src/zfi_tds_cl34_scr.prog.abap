*&---------------------------------------------------------------------*
*& Report/Include : ZFI_TDS_CL34_SCR
*& Title          : TDS Report Clause 34 - selection screen
*& Project        : KPMG - UDAY / Astral          Module: FI
*& Related FS     : Clause 34 TDS Report FS.xlsx, v1, 21.08.2026
*& Author         : Arnav Johri                   Date: 26.08.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   Selection screen for report ZFI_TDS_CL34. Declarations only - the
*&   default values are proposed in INIT_DEFAULTS and the plausibility
*&   checks run in VALIDATE_SELECTION, both in ZFI_TDS_CL34_FORMS.
*&
*& CHANGE HISTORY
*&   26.08.2026  Arnav Johri  <TR>  Initial development
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& The five fields of the FS "Input Screen" tab, in the FS's own order.
*&
*& Company code, fiscal year and posting date are the FS's mandatory
*& filter and are therefore OBLIGATORY; section code and vendor code are
*& optional narrowing filters. Company codes 1000 and 4000 are stated in
*& the FS as applicability, not as a filter, so nothing is defaulted or
*& hardcoded to them.
*&
*& Every SELECT-OPTIONS sits on the field it actually filters, not on a
*& convenient look-alike, so the length and the dictionary value help are
*& the correct ones:
*&   S_BUKRS  BKPF-BUKRS       - company code of the FI document header
*&   S_SECCO  BSEG-SECCO       - section code; it exists on the line item
*&                               only, neither BKPF nor WITH_ITEM has it
*&   S_LIFNR  LFA1-LIFNR      - the vendor. It filters the account of the
*&                               withholding tax item, which is also output
*&                               column C, but it is declared over LFA1 so
*&                               the field gets F4 and ALPHA (07/09/26)
*&   P_GJAHR  BKPF-GJAHR       - single value, per the FS input screen
*&   S_BUDAT  BKPF-BUDAT       - posting date From / To
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.

*BOC By Arnav on 07/09/26
* S_LIFNR moved off WITH_ITEM-WT_ACCO onto LFA1-LIFNR. Both are CHAR 10
* and hold the same value, so the filter is unchanged - but the data
* element LIFNR carries the vendor search help AND the ALPHA conversion
* exit, which WT_ACCO does not. Two things follow from that:
*   - F4 now works on the field;
*   - a vendor typed as 100025 is converted to 0000100025 by the
*     selection screen itself, so the leading zeros no longer have to
*     be typed by hand. That was the reported complaint.
*
* The driver SELECT still filters CUSTOMERSUPPLIERACCOUNT against
* S_LIFNR and GT_LFA1 is still read on WT_ACCO - only the dictionary
* reference of the SCREEN FIELD moved. WITH_ITEM-WT_ACCO stores the
* vendor in internal format with its leading zeros, which is what the
* two live runs proved when column E (PAN) populated on every row, so
* converting the input to internal format is the correct direction.
*
* Field name and length are unchanged, so existing variants stay valid.
*SELECT-OPTIONS: s_bukrs FOR bkpf-bukrs OBLIGATORY,
*                s_secco FOR bseg-secco,
*                s_lifnr FOR with_item-wt_acco.
SELECT-OPTIONS: s_bukrs FOR bkpf-bukrs OBLIGATORY,
                s_secco FOR bseg-secco,
                s_lifnr FOR lfa1-lifnr.
*EOC By Arnav on 07/09/26

PARAMETERS:     p_gjahr TYPE bkpf-gjahr OBLIGATORY.

SELECT-OPTIONS: s_budat FOR bkpf-budat OBLIGATORY.

SELECTION-SCREEN END OF BLOCK b1.

*&---------------------------------------------------------------------*
*& MANUAL POST-CREATION STEPS
*&
*& WHICH OF THESE APPLY DEPENDS ON HOW THE OBJECT ARRIVES.
*&
*&   abapGit ZIP (ZFI_TDS_CL34.zip in the object folder)
*&     Steps 1 and 2 are carried: the import creates the four programs,
*&     and zfi_tds_cl34.prog.xml holds the title plus the Fixed point
*&     arithmetic and Unicode attributes in its PROGDIR and TPOOL.
*&     STEPS 3 AND 4 STILL HAVE TO BE DONE BY HAND. The selection texts
*&     and the text symbol are deliberately NOT in the text pool: TPOOL
*&     entries carrying a KEY were a suspect in an abapGit import error,
*&     so the pool holds the report title and nothing else.
*&     Verify step 2 regardless: attributes are the one thing worth
*&     eyeing after any import.
*&
*&   Paste from this file
*&     Nothing below travels with the source. Work through the whole
*&     list; it is the paste sheet's checklist.
*&
*& 1. OBJECT CREATION
*&    ZFI_TDS_CL34                      executable program (type 1)
*&    ZFI_TDS_CL34_TOP                  INCLUDE (type I)
*&    ZFI_TDS_CL34_SCR                  INCLUDE (type I)
*&    ZFI_TDS_CL34_FORMS                INCLUDE (type I)
*&    The three includes must be created as type INCLUDE (I), NOT as
*&    executable programs, and ZFI_TDS_CL34_TOP must not carry a REPORT
*&    or PROGRAM statement of its own - the main program owns it.
*&
*& 2. Goto -> Attributes
*&    Title                    TDS Report - Clause 34 compliance
*&    Fixed point arithmetic   MUST be ticked. Every SELECT in this
*&                             program uses strict ABAP SQL
*&                             (comma-separated field lists, @ escaped
*&                             host variables), which the compiler only
*&                             accepts when this attribute is on. With
*&                             it off the first strict SELECT fails with
*&                             "This ABAP SQL statement uses additions
*&                             that can only be used when the fixed
*&                             point arithmetic flag is activated", and
*&                             the follow-on errors point at the inline
*&                             declared target ("Field LT_CC is
*&                             unknown") rather than at the attribute.
*&                             SE38 ticks it for a new program, but a
*&                             program created by copy or by a wizard
*&                             can arrive with it off.
*&
*& 3. Goto -> Text elements -> Selection texts
*&     S_BUKRS   Company Code
*&     S_SECCO   Section Code
*&     S_LIFNR   Vendor Code
*&     P_GJAHR   Fiscal Year
*&     S_BUDAT   Posting Date
*&
*&    Do not tick "Dictionary reference" on the selection texts - the
*&    dictionary labels for LIFNR and SECCO are not the words the FS
*&    asks for. Leaving it unticked does NOT affect F4 or the ALPHA
*&    conversion: those come from the field's dictionary reference in
*&    the SELECT-OPTIONS, not from the selection text.
*&
*& 4. Goto -> Text elements -> Text symbols
*&     b01       Selection
*&
*& Until steps 3 and 4 are done - by hand either way, ZIP or paste - the
*& block frame is blank and the fields show their technical names.
*&---------------------------------------------------------------------*
