*&---------------------------------------------------------------------*
*& Report/Include : ZFI_TDS_CL34
*& Title          : TDS Report - Clause 34 compliance
*& Project        : KPMG - UDAY / Astral          Module: FI
*& Related FS     : Clause 34 TDS Report FS.xlsx, v1, 21.08.2026
*& Author         : Arnav Johri                   Date: 26.08.2026
*& Transport      : <TR>
*&---------------------------------------------------------------------*
*& DESCRIPTION
*&   Lists every FI document in which withholding tax (TDS) was deducted,
*&   GL wise and document number wise, for compliance reporting under
*&   clause 34. One row per withholding tax item. The driver reads the two
*&   CDS views the FS names, I_WITHHOLDINGTAXITEM inner-joined to
*&   I_JOURNALENTRY; the header and line item buffers are read from BKPF
*&   and BSEG, which is what the FS asks for everywhere else. Output is a
*&   CL_SALV_TABLE ALV list of 25 columns.
*&
*&   Include structure:
*&     ZFI_TDS_CL34_TOP    types, global data, constants
*&     ZFI_TDS_CL34_SCR    selection screen
*&     ZFI_TDS_CL34_FORMS  all form routines
*&
*& CHANGE HISTORY
*&   26.08.2026  Arnav Johri  <TR>  Initial development
*&   07.09.2026  Arnav Johri  <TR>  WhldgTaxItemStatus V/D/M/S excluded;
*&                                  vendor code F4 + ALPHA conversion;
*&                                  F4 on section code
*&---------------------------------------------------------------------*
REPORT zfi_tds_cl34.

INCLUDE zfi_tds_cl34_top.
INCLUDE zfi_tds_cl34_scr.
INCLUDE zfi_tds_cl34_forms.

*&---------------------------------------------------------------------*
*& Propose a sensible default period so the user does not face an empty
*& obligatory posting-date range. The default is derived from SY-DATUM,
*& never from a hardcoded date or company code.
*&---------------------------------------------------------------------*
INITIALIZATION.

  PERFORM init_defaults.

*&---------------------------------------------------------------------*
*& Input plausibility. TYPE 'E' is only legal here - anywhere else it
*& ends the report on a blank screen.
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN.

  PERFORM validate_selection.

*BOC By Arnav on 07/09/26
*&---------------------------------------------------------------------*
*& Value help for Section Code - the official withholding tax key of
*& output column H. The list is built from the keys the report can
*& actually return in the company code and fiscal year already typed on
*& the screen, with their descriptions. Both driving fields are
*& obligatory, so nothing is lost by requiring them first.
*&
*& Vendor Code needs no event of its own: S_LIFNR is declared over
*& LFA1-LIFNR, so its F4 and its leading-zero conversion both come from
*& the dictionary.
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_sectn-low.

  PERFORM f4_section_code USING 'S_SECTN-LOW'.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_sectn-high.

  PERFORM f4_section_code USING 'S_SECTN-HIGH'.
*EOC By Arnav on 07/09/26

*&---------------------------------------------------------------------*
*& Read the withholding items and their documents, then derive the 25
*& output columns. Both forms fill global tables declared in _TOP.
*&---------------------------------------------------------------------*
START-OF-SELECTION.

* AT SELECTION-SCREEN does not run in a background job started from a
* variant, so the authorisation check has to be repeated here or every
* scheduled run of this report would be unprotected. In dialog it is
* dead weight - VALIDATE_SELECTION has already kept the user on the
* selection screen - and it costs one T001 read.
  PERFORM check_authorisation CHANGING gv_authcc.

  IF gv_authcc IS NOT INITIAL.
    gv_authtx = |No display authorisation for company code { gv_authcc }|.
    MESSAGE gv_authtx TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM fetch_wt_items.
  PERFORM build_output.

  IF gt_output IS INITIAL.
*   The diagnostic counters must survive an empty result. A run whose
*   every withholding item was discarded by the section code filter for
*   want of a vendor line, or whose GL could not be derived anywhere,
*   has to say so - "no documents found" would make that run
*   indistinguishable from one that legitimately matched nothing, on a
*   compliance report. Only ONE status message survives on the screen,
*   so REPORT_GL_GAPS REPLACES the generic message rather than joining
*   it. Its own guard tests exactly the same three counters.
    IF gt_glmsg IS INITIAL AND gt_glamb IS INITIAL AND gv_nosect IS INITIAL.
      MESSAGE 'No TDS documents found for the given selection' TYPE 'S' DISPLAY LIKE 'W'.
    ELSE.
      PERFORM report_gl_gaps.
    ENDIF.
    RETURN.
  ENDIF.

*&---------------------------------------------------------------------*
*& RETURN above leaves START-OF-SELECTION but does NOT suppress
*& END-OF-SELECTION, so the empty-list case is guarded again here.
*& Without this guard the "no documents found" message would be followed
*& by an empty ALV, which reads as a broken report rather than an empty
*& selection. The empty case has already issued its message - generic or
*& diagnostic - in START-OF-SELECTION, so REPORT_GL_GAPS is not called
*& twice.
*&
*& REPORT_GL_GAPS runs before DISPLAY_ALV on purpose: DISPLAY( ) does not
*& return until the user leaves the list, so a message issued after it
*& would appear on the calling screen instead of on the list itself.
*&---------------------------------------------------------------------*
END-OF-SELECTION.

  IF gt_output IS INITIAL.
    RETURN.
  ENDIF.

  PERFORM report_gl_gaps.
  PERFORM display_alv.
