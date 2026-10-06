break abapuser02.
*BOC By SAP_ABAP on 06/10/26
*select DATEC
*  ACTIVITY
*  DAYSC
*  STAGES
*  LOCATION
*  REMARKS  from zsap_timesheet into TABLE lt_data
*   where doc_no = doc_no.
* Lines of the chosen Scope only. IV_SCOPE (form interface, optional)
* is the Scope picked on the print screen, blank = all lines.
* (IV_SCOPE must be listed under Input Parameters of this node.)
IF iv_scope IS INITIAL.
  select DATEC
    ACTIVITY
    DAYSC
    STAGES
    LOCATION
    REMARKS  from zsap_timesheet into TABLE lt_data
     where doc_no = doc_no.
ELSE.
  select DATEC
    ACTIVITY
    DAYSC
    STAGES
    LOCATION
    REMARKS  from zsap_timesheet into TABLE lt_data
     where doc_no = doc_no
       and scope  = iv_scope.
ENDIF.
*EOC By SAP_ABAP on 06/10/26
"Code Remediation changes S4 2025_1_A Conversion **BEGIN OF CHANGE BY SAP_ABAP 08.06.2026  FOR ATC
*  select SINGLE * from ZSAP_TIMESHEET  into temp
*    where doc_no = doc_no.
  select * from ZSAP_TIMESHEET  into temp UP TO 1 ROWS
    where doc_no = doc_no ORDER BY PRIMARY KEY. ENDSELECT.
"Code Remediation changes S4 2025_1_A Conversion **END OF CHANGE BY SAP_ABAP 08.06.2026  FOR ATC
SELECT SINGLE a~name_text
  INTO SAP_PM
  FROM usr21 AS u
  INNER JOIN adrp AS a
  ON u~persnumber = a~persnumber
  WHERE u~bname = temp-sap_pm_approve_by.


  SELECT SINGLE a~name_text
  INTO CORE_TEAM
  FROM usr21 AS u
  INNER JOIN adrp AS a
  ON u~persnumber = a~persnumber
  WHERE u~bname = temp-core_team_approve_by.


    SELECT SINGLE a~name_text
  INTO OVL_PM
  FROM usr21 AS u
  INNER JOIN adrp AS a
  ON u~persnumber = a~persnumber
  WHERE u~bname = temp-ovl_pm_approve_by.

   SELECT SINGLE a~name_text
  INTO HEAD_IT
  FROM usr21 AS u
  INNER JOIN adrp AS a
  ON u~persnumber = a~persnumber
  WHERE u~bname = temp-head_it_approve_by.
