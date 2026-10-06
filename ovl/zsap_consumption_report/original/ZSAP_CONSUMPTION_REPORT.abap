REPORT zsap_consumption_report.


TYPE-POOLS: slis.

TABLES: zservice_element,
        zsap_timesheet.

*---------------------------------------------------------------------*
* Selection Screen
*---------------------------------------------------------------------*
PARAMETERS: p_ser   TYPE zservice_element-service_element.
PARAMETERS: p_datef TYPE datum OBLIGATORY,
            p_datet TYPE datum OBLIGATORY.

*---------------------------------------------------------------------*
* Output Structure
*---------------------------------------------------------------------*
TYPES: BEGIN OF ty_output,
         service_element     TYPE zser_ele,
         asis_scope_days     TYPE zscope_day,
         add_scope_days      TYPE zadscope_day,
         asis_consumed_days  TYPE p LENGTH 7 DECIMALS 2,
         add_consumed_days   TYPE zdaysz,
         asis_available_days TYPE p LENGTH 8 DECIMALS 2,
         add_available_days  TYPE p LENGTH 8 DECIMALS 2,
         asis_consumed_amt   TYPE zdaily_rate_with_gst,
         add_consumed_amt    TYPE zdaily_rate_with_gst,
         asis_available_amt  TYPE zdaily_rate_with_gst,
         add_available_amt   TYPE zdaily_rate_with_gst,
       END OF ty_output.

DATA: gt_output TYPE STANDARD TABLE OF ty_output,
      gs_output TYPE ty_output.

DATA: gt_master TYPE STANDARD TABLE OF zservice_element.

*---------------------------------------------------------------------*
* SUM Structure
*---------------------------------------------------------------------*
TYPES: BEGIN OF ty_sum,
         service_element TYPE zser_ele,
         scope           TYPE zscope,
         daysc           TYPE p LENGTH 7 DECIMALS 2,
       END OF ty_sum.

DATA: gt_sum TYPE STANDARD TABLE OF ty_sum,
      gs_sum TYPE ty_sum.

*---------------------------------------------------------------------*
* ALV
*---------------------------------------------------------------------*
DATA: gt_fieldcat TYPE slis_t_fieldcat_alv,
      gs_fieldcat TYPE slis_fieldcat_alv,
      gs_layout   TYPE slis_layout_alv.

*---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_ser.
  PERFORM get_service_element.

*---------------------------------------------------------------------*
* Start of Selection
*---------------------------------------------------------------------*
START-OF-SELECTION.

  CLEAR: gt_master, gt_sum.
  REFRESH: gt_master, gt_sum.

*---------------------------------------------------------------------*
* 1️⃣ Get Master Data
*---------------------------------------------------------------------*
  IF p_ser IS INITIAL.

    SELECT *
      INTO TABLE @gt_master
      FROM zservice_element.

  ELSE.

    SELECT *
      INTO TABLE @gt_master
      FROM zservice_element
      WHERE service_element = @p_ser.

  ENDIF.

*---------------------------------------------------------------------*
* 2️⃣ Get SUM of Days from Transaction
*---------------------------------------------------------------------*
  IF p_ser IS INITIAL.

    SELECT service_element,
           scope,
           SUM( daysc ) AS daysc
      INTO TABLE @gt_sum
      FROM zsap_timesheet
      WHERE datec BETWEEN @p_datef AND @p_datet
        AND head_it_approve = 'X'
      GROUP BY service_element, scope.

  ELSE.

    SELECT service_element,
           scope,
           SUM( daysc ) AS daysc
      INTO TABLE @gt_sum
      FROM zsap_timesheet
      WHERE service_element = @p_ser
        AND datec BETWEEN @p_datef AND @p_datet
        AND head_it_approve = 'X'
      GROUP BY service_element, scope.

  ENDIF.

*---------------------------------------------------------------------*
* 3️⃣ Build Report Data
*---------------------------------------------------------------------*
  DATA lv_asis TYPE p LENGTH 7 DECIMALS 2.
  DATA lv_add  TYPE p LENGTH 7 DECIMALS 2.

  LOOP AT gt_master INTO DATA(ls_master).

    CLEAR: gs_output, lv_asis, lv_add.

    gs_output-service_element = ls_master-service_element.
    gs_output-asis_scope_days = ls_master-as_is_scope_day.
    gs_output-add_scope_days  = ls_master-additional_scope_days.

* AS IS consumed
    READ TABLE gt_sum INTO gs_sum
      WITH KEY service_element = ls_master-service_element
               scope = 'AS IS'.

    IF sy-subrc = 0.
      lv_asis = gs_sum-daysc.
    ENDIF.

* Additional consumed
    READ TABLE gt_sum INTO gs_sum
      WITH KEY service_element = ls_master-service_element
               scope = 'ADDITIONAL'.

    IF sy-subrc = 0.
      lv_add = gs_sum-daysc.
    ENDIF.

    gs_output-asis_consumed_days = lv_asis.
    gs_output-add_consumed_days  = lv_add.

* Available Days
    gs_output-asis_available_days =
      ls_master-as_is_scope_day - lv_asis.

    gs_output-add_available_days =
      ls_master-additional_scope_days - lv_add.

* Amount Calculations
    gs_output-asis_consumed_amt =
      lv_asis * ls_master-daily_rate_gst.

    gs_output-add_consumed_amt =
      lv_add * ls_master-daily_rate_gst.

    gs_output-asis_available_amt =
      gs_output-asis_available_days *
      ls_master-daily_rate_gst.

    gs_output-add_available_amt =
      gs_output-add_available_days *
      ls_master-daily_rate_gst.

    APPEND gs_output TO gt_output.

  ENDLOOP.

*---------------------------------------------------------------------*
* 4️⃣ ALV Field Catalog
*---------------------------------------------------------------------*
  PERFORM build_fieldcat.
  PERFORM display_alv.

*---------------------------------------------------------------------*
FORM build_fieldcat.

  CLEAR gs_layout.
  gs_layout-colwidth_optimize = 'X'.

  DEFINE m_field.
    CLEAR gs_fieldcat.
    gs_fieldcat-fieldname = &1.
    gs_fieldcat-seltext_l = &2.
    gs_fieldcat-outputlen = 18.
    APPEND gs_fieldcat TO gt_fieldcat.
  END-OF-DEFINITION.

  m_field 'SERVICE_ELEMENT' 'Service Element'.
  m_field 'ASIS_SCOPE_DAYS' 'AS IS Scope days'.
  m_field 'ADD_SCOPE_DAYS'  'Additional Scope days'.
  m_field 'ASIS_CONSUMED_DAYS' 'AS IS Consumed days'.
  m_field 'ADD_CONSUMED_DAYS'  'Additional Consumed days'.
  m_field 'ASIS_AVAILABLE_DAYS' 'AS IS Available days'.
  m_field 'ADD_AVAILABLE_DAYS'  'Additional Available days'.
  m_field 'ASIS_CONSUMED_AMT' 'AS IS Consumed Amount'.
  m_field 'ADD_CONSUMED_AMT'  'Additional Consumed Amount'.
  m_field 'ASIS_AVAILABLE_AMT' 'AS IS Available Amount'.
  m_field 'ADD_AVAILABLE_AMT'  'Additional Available Amount'.

ENDFORM.

*---------------------------------------------------------------------*
FORM display_alv.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      is_layout              = gs_layout
      it_fieldcat            = gt_fieldcat
      i_callback_top_of_page = 'TOP_OF_PAGE'
      i_callback_program     = sy-repid
      i_save                 = 'A'
    TABLES
      t_outtab               = gt_output.

ENDFORM.

*---------------------------------------------------------------------*
FORM top_of_page.

  DATA: lt_header TYPE slis_t_listheader,
        ls_header TYPE slis_listheader,
        lv_datef  TYPE char10,
        lv_datet  TYPE char10.

  WRITE p_datef TO lv_datef DD/MM/YYYY.
  WRITE p_datet TO lv_datet DD/MM/YYYY.

* Title
  ls_header-typ  = 'H'.
  ls_header-info = 'Consumption Report'.
  APPEND ls_header TO lt_header.

* From Date
  CLEAR ls_header.
  ls_header-typ  = 'S'.
  ls_header-key  = 'From Date'.
  ls_header-info = lv_datef.
  APPEND ls_header TO lt_header.

* To Date
  CLEAR ls_header.
  ls_header-typ  = 'S'.
  ls_header-key  = 'To Date'.
  ls_header-info = lv_datet.
  APPEND ls_header TO lt_header.

* Service Element
  IF p_ser IS NOT INITIAL.
    CLEAR ls_header.
    ls_header-typ  = 'S'.
    ls_header-key  = 'Service Element'.
    ls_header-info = p_ser.
    APPEND ls_header TO lt_header.
  ENDIF.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.

ENDFORM.

INCLUDE zsap_consumption_report_getf01.
