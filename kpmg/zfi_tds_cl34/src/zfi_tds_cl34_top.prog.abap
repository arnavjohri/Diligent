*&---------------------------------------------------------------------*
*& Report/Include : ZFI_TDS_CL34_TOP
*& Title          : TDS Reporting as per Clause 34(a) - global declarations
*& Project        : KPMG - UDAY / Astral          Module: FI
*& Related FS     : Clause 34 TDS Report FS.xlsx, v1, 21.08.2026
*& Author         : Arnav Johri                   Date: 26.08.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   Types, global tables and constants for report ZFI_TDS_CL34.
*&   Declarations only - no executable statement lives in this include.
*&
*& CHANGE HISTORY
*&   26.08.2026  Arnav Johri  <TR>  Initial development
*&   07.09.2026  Arnav Johri  <TR>  WhldgTaxItemStatus V/D/M/S excluded;
*&                                  vendor code F4 + ALPHA conversion;
*&                                  F4 on section code
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Tables addressed by the selection screen.
*& Each SELECT-OPTIONS in ZFI_TDS_CL34_SCR is declared over the field it
*& actually filters, so both the field length and the dictionary value
*& help are the right ones. Section code exists only on BSEG; the vendor
*& account of a withholding item is WITH_ITEM-WT_ACCO.
*&
*& 07/09/26: S_LIFNR is nevertheless declared over LFA1-LIFNR, not over
*& WT_ACCO. Both are CHAR 10 and hold the same value, but only the data
*& element LIFNR carries the vendor search help and the ALPHA conversion
*& exit - see the note in ZFI_TDS_CL34_SCR.
*&---------------------------------------------------------------------*
*BOC By Arnav on 07/09/26
* LFA1 added for the S_LIFNR select-option, T059Z for S_SECTN. Each
* select-option is declared over the field it really filters, so it gets
* that field's length and its dictionary help. WITH_ITEM stays declared -
* the TYPES below are typed against its fields throughout.
*TABLES: bkpf,
*        bseg,
*        with_item.
TABLES: bkpf,
        bseg,
        with_item,
        lfa1,
        t059z.
*EOC By Arnav on 07/09/26

*&---------------------------------------------------------------------*
*& Output structure - the 25 columns of the FS "Output Screen" tab plus
*& one hidden currency component.
*&
*& Every field is typed against a real dictionary field, never against a
*& literal CHAR(n) / DEC(n,m), so no field length is guessed anywhere in
*& this build.
*&
*& WAERS is the company code currency of the document (T001-WAERS). It is
*& carried so the currency of BASE_AMT / TDS_AMT / THRESHOLD / CUM_AMT is
*& known in the row, but it is NOT yet registered as the ALV currency
*& reference of those columns - see DISPLAY_ALV. It is set technical and
*& is not a 26th column.
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_output,
         sr        TYPE i,                              " col A  running number, continuous over the whole list
         belnr     TYPE with_item-belnr,                " col B  FI document number
         lifnr     TYPE with_item-wt_acco,              " col C  vendor - account of the withholding item, KOART = 'K'
         name1     TYPE lfa1-name1,                     " col D  vendor name
         pan_no    TYPE lfa1-j_1ipanno,                 " col E  vendor PAN, CHAR 40 - never declare it as CHAR 10
         gl_code   TYPE bseg-hkont,                     " col F  derived - see the GL derivation form
         gl_name   TYPE skat-txt50,                     " col G  GL long text, SKAT not SKA1 (SKA1 has no text field)
         section   TYPE t059z-qscod,                    " col H  official withholding tax key
         sec_desc  TYPE t059ot-text40,                  " col I  text of the official key - T059OT, not T059Z
*        " ASSUMPTION: col J is the item text of the vendor line, not
*        the BKPF header text - see QUERIES Q5.
         nature    TYPE bseg-sgtxt,                     " col J
         budat     TYPE bkpf-budat,                     " col K  posting date (FS heading says "Document Date (SAP)")
         xblnr     TYPE bkpf-xblnr,                     " col L  reference = invoice number, per FS [L6]
         bldat     TYPE bkpf-bldat,                     " col M  document date
         augbl     TYPE bseg-augbl,                     " col N  clearing document, blank while the item is open
         augdt     TYPE bseg-augdt,                     " col O  clearing date, blank while the item is open
         base_amt  TYPE with_item-wt_qsshh,             " col P  base amount in company code currency
         taxcode   TYPE with_item-wt_withcd,            " col Q  withholding tax code
         rate_sec  TYPE t059z-qsatz,                    " col R  rate configured for the section
         rate_ded  TYPE with_item-qsatz,                " col S  rate actually deducted on the item
         tds_amt   TYPE with_item-wt_qbshh,             " col T  tax amount in company code currency
         exdf      TYPE fiwtin_tan_exem-wt_exdf,        " col U  exemption valid from
         exdt      TYPE fiwtin_tan_exem-wt_exdt,        " col V  exemption valid to
         threshold TYPE fiwtin_tan_exem-fiwtin_exem_thr," col W  " ASSUMPTION: threshold shown as an amount, not as Y/N
         cert_no   TYPE fiwtin_tan_exem-wt_exnr,        " col X  exemption certificate number
         cum_amt   TYPE fiwtin_acc_exem-acc_amt,        " col Y  accumulated base amount held by the exemption table
*BOC By Arnav on 07/09/26
*        Col Z. Columns P and T are now reported as magnitudes, and the
*        sign they used to carry was the only thing on the report that
*        said which way the vendor was posted. This restores it as its
*        own column instead of leaving it to be inferred from the
*        document number range, which does not hold - 1700000000 is a
*        17* document posted the other way.
*        Derived from the RAW amount before ABS( ), not from a second
*        read of BSEG-SHKZG: the raw sign is by definition exactly what
*        was lost, so the column cannot disagree with the amount.
         drcr      TYPE bseg-shkzg,                     " col Z  S = vendor debited, H = vendor credited
*EOC By Arnav on 07/09/26
         waers     TYPE t001-waers,                     " hidden - company code currency of the row, see DISPLAY_ALV
       END OF ty_output,
       tt_output TYPE STANDARD TABLE OF ty_output WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& Document key. Built once from the driver read and reused, guarded by
*& IS NOT INITIAL, as the FOR ALL ENTRIES driver of every follow-on read
*& that is keyed by the FI document.
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_dockey,
         bukrs TYPE bkpf-bukrs,
         belnr TYPE bkpf-belnr,
         gjahr TYPE bkpf-gjahr,
       END OF ty_dockey,
       tt_dockey TYPE STANDARD TABLE OF ty_dockey WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& Driver buffer - the withholding tax items themselves.
*&
*& " ASSUMPTION: one output row per WITH_ITEM key
*& (BUKRS / BELNR / GJAHR / BUZEI / WITHT). WT_WITHCD is NOT a key field
*& of WITH_ITEM, so any DELETE ADJACENT DUPLICATES on this buffer must
*& compare the five key fields above and nothing else. A SORT may append
*& further fields for a deterministic display order - BUILD_OUTPUT sorts
*& on the five plus WT_WITHCD and never de-duplicates.
*&
*& The HH suffix is the company code currency, HB the transaction
*& currency. The FS asks for company code currency, so HH is used.
*&
*& The buffer is FILLED FROM THE CDS VIEW I_WITHHOLDINGTAXITEM, which is
*& what FS [B2] asks for, but it is TYPED from WITH_ITEM, the table that
*& view reads. Typing from the view as well would put its element names
*& in a second place and double the surface an activation error can come
*& from; the underlying table's names are stable across releases. The
*& component order below is the order FETCH_WT_ITEMS lists the view
*& elements in - strict ABAP SQL assigns by POSITION, so the two must be
*& kept aligned.
*&
*&   ty_witem-bukrs      <- CompanyCode
*&   ty_witem-belnr      <- AccountingDocument        FS [B2]
*&   ty_witem-gjahr      <- FiscalYear
*&   ty_witem-buzei      <- AccountingDocumentItem
*&   ty_witem-witht      <- WithholdingTaxType
*&   ty_witem-wt_withcd  <- WithholdingTaxCode        FS [Q2]
*&   ty_witem-wt_acco    <- CustomerSupplierAccount   FS [C2]
*&   ty_witem-wt_qsshh   <- WhldgTaxBaseAmtInCoCodeCrcy  FS [P2]
*&   ty_witem-wt_qbshh   <- WhldgTaxAmtInCoCodeCrcy      FS [T2]
*&   ty_witem-qsatz      <- WithholdingTaxPercent        FS [S2]
*&
*& " ASSUMPTION: the six element names the FS spells out are correct and
*& the four it does not spell out (CompanyCode, FiscalYear,
*& AccountingDocumentItem, WithholdingTaxType) follow the standard
*& naming. None of them can be verified without the target system. If
*& the view rejects any of them, FETCH_WT_ITEMS is the only form to
*& change - see its comment.
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_witem,
         bukrs     TYPE with_item-bukrs,
         belnr     TYPE with_item-belnr,
         gjahr     TYPE with_item-gjahr,
         buzei     TYPE with_item-buzei,
         witht     TYPE with_item-witht,
         wt_withcd TYPE with_item-wt_withcd,
         wt_acco   TYPE with_item-wt_acco,
         wt_qsshh  TYPE with_item-wt_qsshh,
         wt_qbshh  TYPE with_item-wt_qbshh,
         qsatz     TYPE with_item-qsatz,
       END OF ty_witem,
       tt_witem TYPE STANDARD TABLE OF ty_witem WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& Header buffer. AWTYP carries the reference transaction - 'RMRP' for a
*& logistics invoice - and AWKEY the reference key from which the MM
*& invoice number and year are cut.
*&
*& The GLCode Logic tab says "For records having AWKEY as RMRP". That is
*& the ONE FS instruction implemented against its own words, and the FS
*& itself is the evidence: two rows further down the same tab it says
*& "Get AWKEY and provide first 10 digits of AWKEY in BELNR of RSEG and
*& Fiscal year in GJAHR". A field cannot both equal 'RMRP' and hold a
*& ten digit invoice number followed by a four digit year. RMRP is the
*& reference TRANSACTION, which is AWTYP; AWKEY is the reference KEY the
*& same tab then cuts the invoice number out of. Testing AWKEY = 'RMRP'
*& would match no document at all, every purchase-order invoice would
*& silently take the direct-FI branch, and column F would be wrong for
*& most of the report without anything failing visibly. Registered as a
*& query for Bhavin Suthar.
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_bkpf,
         bukrs TYPE bkpf-bukrs,
         belnr TYPE bkpf-belnr,
         gjahr TYPE bkpf-gjahr,
         budat TYPE bkpf-budat,
         bldat TYPE bkpf-bldat,
         xblnr TYPE bkpf-xblnr,
         awtyp TYPE bkpf-awtyp,
         awkey TYPE bkpf-awkey,
       END OF ty_bkpf,
       tt_bkpf TYPE STANDARD TABLE OF ty_bkpf WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& Line item buffer. One read serves two purposes, so KTOSL is NOT
*& pushed into the WHERE clause: the vendor line of the document supplies
*& columns J / N / O and the section code filter, while the
*& KTOSL = 'WIT' lines of the same document supply the offsetting GL for
*& the direct-FI branch of the GL derivation.
*&
*& KOART and LIFNR are carried for one purpose only - FORM
*& READ_VENDOR_LINE identifies the vendor line with them, which is the
*& condition FS [J2] states verbatim ("where LIFNR <> blank").
*&
*& GHKON is the offsetting account in general ledger accounting
*& (position 364). GKONT at position 362 is a different field and must
*& never be substituted for it.
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_bseg,
         bukrs TYPE bseg-bukrs,
         belnr TYPE bseg-belnr,
         gjahr TYPE bseg-gjahr,
         buzei TYPE bseg-buzei,
         koart TYPE bseg-koart,
         ktosl TYPE bseg-ktosl,
         lifnr TYPE bseg-lifnr,
         sgtxt TYPE bseg-sgtxt,
         augbl TYPE bseg-augbl,
         augdt TYPE bseg-augdt,
         secco TYPE bseg-secco,
         ghkon TYPE bseg-ghkon,
*        Header dates propagated onto the line item. FS [K2] and [M2]
*        name these two BSEG fields, not their BKPF originals, so they
*        are read here and columns K and M come off the vendor line.
         h_budat TYPE bseg-h_budat,
         h_bldat TYPE bseg-h_bldat,
       END OF ty_bseg,
       tt_bseg TYPE STANDARD TABLE OF ty_bseg WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& Vendor master. J_1IPANNO is the PAN and it also keys the four
*& exemption columns U / V / W / X and the cumulative column Y, so a
*& column-wide blank here blanks six columns at once.
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_venkey,
         lifnr TYPE lfa1-lifnr,
       END OF ty_venkey,
       tt_venkey TYPE STANDARD TABLE OF ty_venkey WITH DEFAULT KEY.

TYPES: BEGIN OF ty_lfa1,
         lifnr     TYPE lfa1-lifnr,
         name1     TYPE lfa1-name1,
         j_1ipanno TYPE lfa1-j_1ipanno,
       END OF ty_lfa1,
       tt_lfa1 TYPE STANDARD TABLE OF ty_lfa1 WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& Company code. Supplies the country for the withholding tax config
*& reads, the chart of accounts for the GL text read and the currency of
*& every amount column. The FS asks for a hardcoded chart of accounts;
*& it is read per company code instead.
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_t001,
         bukrs TYPE t001-bukrs,
         land1 TYPE t001-land1,
         waers TYPE t001-waers,
         ktopl TYPE t001-ktopl,
       END OF ty_t001,
       tt_t001 TYPE STANDARD TABLE OF ty_t001 WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& GL account text. SKA1 carries no text field at all on this release,
*& so column G is read from the text table SKAT in the logon language.
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_glkey,
         ktopl TYPE skat-ktopl,
         saknr TYPE skat-saknr,
       END OF ty_glkey,
       tt_glkey TYPE STANDARD TABLE OF ty_glkey WITH DEFAULT KEY.

TYPES: BEGIN OF ty_skat,
         spras TYPE skat-spras,
         ktopl TYPE skat-ktopl,
         saknr TYPE skat-saknr,
         txt50 TYPE skat-txt50,
       END OF ty_skat,
       tt_skat TYPE STANDARD TABLE OF ty_skat WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& Withholding tax code configuration.
*& T059Z is keyed LAND1 + WITHT + WT_WITHCD - the FS names only
*& WT_WITHCD, the two missing key parts come from T001-LAND1 and
*& WITH_ITEM-WITHT. QSCOD is the official withholding tax key (column H)
*& and QSATZ the configured rate (column R).
*&
*& T059Z has no text field. The description in column I is the text of
*& the official key and lives in T059OT, whose key field is WT_QSCOD -
*& note the different field name on the two tables.
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Withholding tax code configuration. One read of T059Z serves three
*& columns, exactly as FS [H2] [I2] [R2] describe it: the official
*& withholding tax key (QSCOD, col H), its 40 character text (TXT40,
*& col I) and the configured rate (QSATZ, col R).
*&
*& FS [I2] says to take the col I text from T059Z-TXT40. **That field does
*& not exist** - proved on the Astral system itself, activation 27/08/26:
*& "No component exists with the name TXT40" against ZFI_TDS_CL34_TOP.
*& T059Z has no text field at all; its texts are language dependent and
*& live in separate tables. Column I is therefore read from T059OT, the
*& text of the OFFICIAL withholding tax key - which is what column H
*& holds, so the two agree. T059ZT was the alternative (text of the tax
*& CODE, key SPRAS / LAND1 / WITHT / WT_WITHCD) and is the one to switch
*& to if the business means the code text rather than the section text.
*& Registered as QUERIES Q9.
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_t059z,
         land1     TYPE t059z-land1,
         witht     TYPE t059z-witht,
         wt_withcd TYPE t059z-wt_withcd,
         qscod     TYPE t059z-qscod,
         qsatz     TYPE t059z-qsatz,
       END OF ty_t059z,
       tt_t059z TYPE STANDARD TABLE OF ty_t059z WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& Text of the official withholding tax key = column I.
*& Key: MANDT, SPRAS, LAND1, WT_QSCOD. Note the field is WT_QSCOD here
*& and QSCOD on T059Z - the name changes between the two tables and that
*& is an easy place to introduce a bug.
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_t059ot,
         spras    TYPE t059ot-spras,
         land1    TYPE t059ot-land1,
         wt_qscod TYPE t059ot-wt_qscod,
         text40   TYPE t059ot-text40,
       END OF ty_t059ot,
       tt_t059ot TYPE STANDARD TABLE OF ty_t059ot WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& Exemption certificate key, built once and used as the FOR ALL ENTRIES
*& driver of both FIWTIN reads. The posting date is deliberately NOT part
*& of this key: validity is a property of the individual certificate row
*& and is evaluated per output row in READ_EXEMPTION, so the date never
*& enters the database read. Supplying company code, account type and
*& account keeps the read off an unindexed PAN scan.
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_exkey,
         bukrs     TYPE fiwtin_tan_exem-bukrs,
         koart     TYPE fiwtin_tan_exem-koart,
         accno     TYPE fiwtin_tan_exem-accno,
         witht     TYPE fiwtin_tan_exem-witht,
         wt_withcd TYPE fiwtin_tan_exem-wt_withcd,
         pan_no    TYPE fiwtin_tan_exem-pan_no,
       END OF ty_exkey,
       tt_exkey TYPE STANDARD TABLE OF ty_exkey WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& Exemption certificate (columns U / V / W / X).
*& " ASSUMPTION: the certificate row taken is the one valid on the
*& posting date (WT_EXDF <= BUDAT AND WT_EXDT >= BUDAT) for the
*& document's own tax type and tax code; where several still qualify,
*& the one with the latest WT_EXDF, and among those the one carrying the
*& document's own section code.
*& " ASSUMPTION: SECCODE and FIWTIN_TANEX_SUB are key fields of
*& FIWTIN_TAN_EXEM that this report does NOT restrict on - the FS does
*& not make the certificate section code specific. They are read so the
*& sort key is total and the pick is reproducible, and SECCODE is used
*& only to break a tie. QUERIES.md carries the question for Ankita.
*& The threshold field FIWTIN_EXEM_THR is a currency amount whose
*& reference is the company code currency, not the WAERS field of this
*& table.
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_tanex,
         bukrs            TYPE fiwtin_tan_exem-bukrs,
         koart            TYPE fiwtin_tan_exem-koart,
         accno            TYPE fiwtin_tan_exem-accno,
         fiwtin_tanex_sub TYPE fiwtin_tan_exem-fiwtin_tanex_sub,
         seccode          TYPE fiwtin_tan_exem-seccode,
         witht            TYPE fiwtin_tan_exem-witht,
         wt_withcd        TYPE fiwtin_tan_exem-wt_withcd,
         wt_exdf          TYPE fiwtin_tan_exem-wt_exdf,
         pan_no           TYPE fiwtin_tan_exem-pan_no,
         wt_exdt          TYPE fiwtin_tan_exem-wt_exdt,
         wt_exnr          TYPE fiwtin_tan_exem-wt_exnr,
         fiwtin_exem_thr  TYPE fiwtin_tan_exem-fiwtin_exem_thr,
       END OF ty_tanex,
       tt_tanex TYPE STANDARD TABLE OF ty_tanex WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& Accumulated base amount (column Y).
*& The section code field is SECCO here and SECCODE on the sister table
*& FIWTIN_TAN_EXEM - they are not interchangeable.
*& " ASSUMPTION: the table already accumulates, so the row with the
*& latest WT_DATE not after the upper posting date bound is shown as it
*& stands. The rows are never summed.
*& " ASSUMPTION: SECCO is a key field of FIWTIN_ACC_EXEM that this
*& report does NOT restrict on (build decision D-14 lists the
*& restricting fields and SECCO is not among them). It is read so the
*& sort key is total, and it breaks a tie in favour of the document's
*& own section code where two rows share the latest WT_DATE. Which
*& section code's accumulation belongs on the row is the first question
*& for Ankita Parikh in QUERIES.md.
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_accex,
         bukrs     TYPE fiwtin_acc_exem-bukrs,
         accno     TYPE fiwtin_acc_exem-accno,
         witht     TYPE fiwtin_acc_exem-witht,
         wt_withcd TYPE fiwtin_acc_exem-wt_withcd,
         secco     TYPE fiwtin_acc_exem-secco,
         wt_date   TYPE fiwtin_acc_exem-wt_date,
         koart     TYPE fiwtin_acc_exem-koart,
         pan_no    TYPE fiwtin_acc_exem-pan_no,
         acc_amt   TYPE fiwtin_acc_exem-acc_amt,
       END OF ty_accex,
       tt_accex TYPE STANDARD TABLE OF ty_accex WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& Logistics invoice key, cut from BKPF-AWKEY on the RMRP branch.
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_mmkey,
         belnr TYPE rseg-belnr,
         gjahr TYPE rseg-gjahr,
       END OF ty_mmkey,
       tt_mmkey TYPE STANDARD TABLE OF ty_mmkey WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& Logistics invoice item. RSEG-BUZEI is NUMC 6 (data element RBLGP),
*& not the NUMC 3 BUZEI of BSEG - the two must not be moved into one
*& another. RSEG does carry BUKRS, so no RBKP detour is needed.
*& BWKEY on the item is the valuation area, which is correct under both
*& plant-level and company-code-level valuation. RSEG-WERKS, which the
*& FS names, is correct only under plant-level valuation and is
*& therefore neither read nor carried here.
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_rseg,
         belnr TYPE rseg-belnr,
         gjahr TYPE rseg-gjahr,
         buzei TYPE rseg-buzei,
         bukrs TYPE rseg-bukrs,
         ebeln TYPE rseg-ebeln,
         ebelp TYPE rseg-ebelp,
         zekkn TYPE rseg-zekkn,
         matnr TYPE rseg-matnr,
*        FS [H20] "get MATNR, WERKS and BWTAR provide the same in MBEW"
*        and FS [H27] "where MATNR = RSEG-MATNR and BWKEY = RSEG_WERKS".
*        The plant is therefore what is passed into the MBEW valuation
*        area, which is correct wherever valuation is at plant level.
*        " ASSUMPTION: company codes 1000 and 4000 are valuated at plant
*        level, so BWKEY = WERKS. Under company-code-level valuation the
*        MBEW read finds nothing and column F falls back to blank for
*        stock purchase orders. Check OX14 / T001K.
         werks TYPE rseg-werks,
         bwtar TYPE rseg-bwtar,
       END OF ty_rseg,
       tt_rseg TYPE STANDARD TABLE OF ty_rseg WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& Purchase order account assignment. "EKKN is not blank" is read as
*& "a row exists whose SAKTO is filled", not merely "a row exists".
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_ekkn,
         ebeln TYPE ekkn-ebeln,
         ebelp TYPE ekkn-ebelp,
         zekkn TYPE ekkn-zekkn,
         sakto TYPE ekkn-sakto,
       END OF ty_ekkn,
       tt_ekkn TYPE STANDARD TABLE OF ty_ekkn WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& Material valuation. The valuation class is taken from the material
*& valuation segment rather than from RSEG-BKLAS, because RSEG holds the
*& class as of invoice time and the account determination is read
*& against current master data. LVORM guards against a segment flagged
*& for deletion.
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_mbew,
         matnr TYPE mbew-matnr,
         bwkey TYPE mbew-bwkey,
         bwtar TYPE mbew-bwtar,
         lvorm TYPE mbew-lvorm,
         bklas TYPE mbew-bklas,
       END OF ty_mbew,
       tt_mbew TYPE STANDARD TABLE OF ty_mbew WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& Automatic account determination. T030 is keyed KTOPL + KTOSL + BWMOD
*& + KOMOK + BKLAS. The valuation grouping code is not read from T001K -
*& that field is unverified on this landscape - so the read is not
*& selective on BWMOD or KOMOK and the ambiguity is resolved in ABAP,
*& preferring the blank grouping code and the blank account modifier.
*& Where no such general entry exists the document is logged in
*& GT_GLAMB and counted in REPORT_GL_GAPS - never resolved silently.
*& KONTS is the debit account, which is the one the FS asks for.
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_t030,
         ktopl TYPE t030-ktopl,
         ktosl TYPE t030-ktosl,
         bwmod TYPE t030-bwmod,
         komok TYPE t030-komok,
         bklas TYPE t030-bklas,
         konts TYPE t030-konts,
       END OF ty_t030,
       tt_t030 TYPE STANDARD TABLE OF ty_t030 WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& Result of the GL derivation, one entry per FI document, and the log
*& of the documents for which no GL could be derived.
*& A document that cannot be resolved keeps its row in the output with
*& columns F and G blank - the withholding figures are still valid and
*& reportable - and is counted in one aggregated message after the list
*& is built. Never a short dump, never a silent skip.
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_glmap,
         bukrs   TYPE bkpf-bukrs,
         belnr   TYPE bkpf-belnr,
         gjahr   TYPE bkpf-gjahr,
         gl_code TYPE bseg-hkont,
       END OF ty_glmap,
       tt_glmap TYPE STANDARD TABLE OF ty_glmap WITH DEFAULT KEY.

TYPES: BEGIN OF ty_glmsg,
         bukrs  TYPE bkpf-bukrs,
         belnr  TYPE bkpf-belnr,
         gjahr  TYPE bkpf-gjahr,
         reason TYPE string,
       END OF ty_glmsg,
       tt_glmsg TYPE STANDARD TABLE OF ty_glmsg WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& Constants. Every literal the logic tests against is named here, so no
*& magic value appears in ZFI_TDS_CL34_FORMS.
*&
*& There is deliberately NO chart-of-accounts constant. FS cell [G2]
*& asks for a hardcoded KTOPL of 'ASTL'; a hardcoded chart of accounts
*& breaks as soon as a second one is in scope, so the chart is read from
*& T001-KTOPL per company code. Likewise there is no company code and no
*& country constant - the FS names company codes 1000 and 4000 as
*& applicability, not as a filter.
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Chart of accounts for the GL description, column G.
*&
*& FS [G2] says verbatim: provide "ASTL" in KTOPL. It is the one place
*& the FS asks for a hardcoded value, so it is honoured and named here
*& rather than buried in FETCH_GL_TEXTS. Everywhere else the chart comes
*& from T001 per company code, because the GLCode Logic tab asks for
*& exactly that ("fetch KTOPL from T001 using BUKRS and provide the same
*& in T030").
*&
*& " ASSUMPTION: every company code in scope, 1000 and 4000 included,
*& runs chart of accounts ASTL. A company code on a different chart
*& returns a blank column G, never a wrong description. Check with
*& SE16 on T001, field KTOPL.
*&---------------------------------------------------------------------*
CONSTANTS: gc_ktopl_gl     TYPE skat-ktopl  VALUE 'ASTL'.   " FS [G2], hardcoded on instruction

CONSTANTS: gc_koart_vendor TYPE bseg-koart  VALUE 'K',      " account type vendor
           gc_ktosl_wit    TYPE bseg-ktosl  VALUE 'WIT',    " transaction key of the withholding tax line
           gc_ktosl_bsx    TYPE t030-ktosl  VALUE 'BSX',    " transaction key of the inventory posting
           gc_awtyp_rmrp   TYPE bkpf-awtyp  VALUE 'RMRP',   " reference transaction of a logistics invoice
           gc_x            TYPE c LENGTH 1  VALUE 'X'.      " generic tick, e.g. the MBEW deletion flag

*BOC By Arnav on 07/09/26
*&---------------------------------------------------------------------*
*& Debit / credit indicator for column Z. The SAP values, so the column
*& reads the way every other FI report does.
*&---------------------------------------------------------------------*
CONSTANTS: gc_shkzg_debit  TYPE bseg-shkzg VALUE 'S',       " vendor debited
           gc_shkzg_credit TYPE bseg-shkzg VALUE 'H'.       " vendor credited
*EOC By Arnav on 07/09/26

*BOC By Arnav on 07/09/26
*&---------------------------------------------------------------------*
*& Withholding tax item statuses that are NOT reportable - the values of
*& I_WITHHOLDINGTAXITEM-WHLDGTAXITEMSTATUS excluded on instruction of
*& 07/09/26. Global rather than local because TWO reads apply them: the
*& driver in FETCH_WT_ITEMS and the section code F4 in F4_SECTION_CODE.
*& If the F4 offered a code whose only items are excluded ones, it would
*& offer a code that returns no rows.
*&
*& " ASSUMPTION: WHLDGTAXITEMSTATUS is a CHAR 1 element of the view. If
*& the view declares it longer, widen LENGTH here - these four are the
*& only place the codes are written down.
*&---------------------------------------------------------------------*
CONSTANTS: gc_wtstat_v TYPE c LENGTH 1  VALUE 'V',
           gc_wtstat_d TYPE c LENGTH 1  VALUE 'D',
           gc_wtstat_m TYPE c LENGTH 1  VALUE 'M',
           gc_wtstat_s TYPE c LENGTH 1  VALUE 'S'.
*EOC By Arnav on 07/09/26

*&---------------------------------------------------------------------*
*& Offsets used to cut the logistics invoice number and year out of
*& BKPF-AWKEY. AWKEY is CHAR 20: positions 0-9 hold the invoice number,
*& positions 10-13 the fiscal year.
*&---------------------------------------------------------------------*
CONSTANTS: gc_awkey_belnr_off TYPE i VALUE 0,
           gc_awkey_belnr_len TYPE i VALUE 10,
           gc_awkey_gjahr_off TYPE i VALUE 10,
           gc_awkey_gjahr_len TYPE i VALUE 4.

*&---------------------------------------------------------------------*
*& Selection range building blocks, used when INIT_DEFAULTS proposes a
*& posting date period and when BUDAT_UPPER reads the period back, and
*& the Indian fiscal year boundaries the proposal is built from. The year
*& always comes from SY-DATUM; the April-March boundaries below are the
*& ASSUMED fiscal year variant (V3), not a hardcoded date. Under a
*& calendar year variant (K4) the proposal INIT_DEFAULTS builds is
*& internally inconsistent - see the assumption marker there.
*&---------------------------------------------------------------------*
CONSTANTS: gc_sign_incl     TYPE c LENGTH 1 VALUE 'I',
           gc_option_bt     TYPE c LENGTH 2 VALUE 'BT',
           gc_fy_start_mm   TYPE c LENGTH 2 VALUE '04',     " Indian fiscal year starts in April
           gc_fy_first_mmdd TYPE c LENGTH 4 VALUE '0401',
           gc_fy_last_mmdd  TYPE c LENGTH 4 VALUE '0331'.

*&---------------------------------------------------------------------*
*& ALV heading width bounds. The list viewer picks which of the three
*& heading texts to draw from the column output length, so the width is
*& set from the heading itself and clamped between these two values.
*&---------------------------------------------------------------------*
CONSTANTS: gc_col_min_len TYPE lvc_outlen VALUE 10,
           gc_col_max_len TYPE lvc_outlen VALUE 40.

*&---------------------------------------------------------------------*
*& Global tables. FETCH_WT_ITEMS fills the driver and document buffers,
*& BUILD_OUTPUT fills the master data, configuration, exemption and GL
*& buffers and finally GT_OUTPUT.
*&---------------------------------------------------------------------*
DATA: gt_witem  TYPE tt_witem,                  " driver - withholding tax items
      gt_bkpf   TYPE tt_bkpf,                   " document headers of the driver set
      gt_bseg   TYPE tt_bseg,                   " all line items of the driver documents
      gt_dockey TYPE tt_dockey.                 " distinct BUKRS / BELNR / GJAHR of the driver set

DATA: gt_lfa1   TYPE tt_lfa1,                   " vendor master, name and PAN
      gt_t001   TYPE tt_t001,                   " company code - country, currency, chart of accounts
      gt_skat   TYPE tt_skat,                   " GL account texts in the logon language
      gt_t059z  TYPE tt_t059z,                  " withholding tax code configuration
      gt_t059ot TYPE tt_t059ot.                 " official withholding tax key texts

DATA: gt_tanex  TYPE tt_tanex,                  " exemption certificates
      gt_accex  TYPE tt_accex.                  " accumulated base amounts

DATA: gt_rseg   TYPE tt_rseg,                   " logistics invoice items, RMRP branch
      gt_ekkn   TYPE tt_ekkn,                   " purchase order account assignments
      gt_mbew   TYPE tt_mbew,                   " material valuation segments
      gt_t030   TYPE tt_t030,                   " automatic account determination
      gt_glmap  TYPE tt_glmap,                  " derived GL account per FI document
      gt_glmsg  TYPE tt_glmsg,                  " documents whose GL could not be derived
      gt_glamb  TYPE tt_glmsg.                  " documents whose BSX account determination was not unique

*BOC By Arnav on 07/09/26
*&---------------------------------------------------------------------*
*& Withholding items the section filter had to discard because their
*& official withholding tax key could not be determined - no T059Z entry
*& for the item's country, type and code, so column H is blank and the
*& row cannot be tested against S_SECTN. Counted rather than dropped in
*& silence - REPORT_GL_GAPS reports the count with the GL gaps.
*&
*& Renamed from GV_NOBSEG on 07/09/26. Until then the filter ran on the
*& vendor line's BSEG-SECCO and the unresolvable case was a missing
*& vendor line; now the filter is on column H and the unresolvable case
*& is a missing T059Z entry. A missing vendor line no longer makes an
*& item vanish - it only blanks columns J / K / M / N / O, as it did
*& before the filter existed - so it is no longer counted.
*&---------------------------------------------------------------------*
*DATA: gv_nobseg TYPE i.
DATA: gv_nosect TYPE i.
*EOC By Arnav on 07/09/26

*&---------------------------------------------------------------------*
*& Authorisation. GV_AUTHCC carries the first company code the user may
*& not display, blank when the check passes. Both are global only
*& because the START-OF-SELECTION event block has no local scope of its
*& own - see CHECK_AUTHORISATION.
*&---------------------------------------------------------------------*
DATA: gv_authcc TYPE bkpf-bukrs,
      gv_authtx TYPE string.

DATA: gt_output TYPE tt_output.                 " the 25 column output list

*&---------------------------------------------------------------------*
*& ALV instance. CL_SALV_TABLE only - the list has no editable cells, no
*& cell styles and no toolbar events, so CL_GUI_ALV_GRID is not needed
*& and a container would make the object paste-only for ever.
*&---------------------------------------------------------------------*
DATA: go_alv TYPE REF TO cl_salv_table.
