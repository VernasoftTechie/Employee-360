"! <p class="shorttext synchronized">HR360 report engine - contract</p>
"!
"! Data retrieval + output-row building for the three executable reports.
"! All access is set-based through the ZI_HR360_* CDS views (no SELECT in LOOP,
"! no native SQL). Implemented by ZCL_HR360_REPORT_ENGINE; a test double can be
"! injected for ABAP Unit.
INTERFACE zif_hr360_report_engine
  PUBLIC.

  TYPES:
    "! Selection scope shared by all three reports.
    BEGIN OF ty_scope,
      pernr       TYPE RANGE OF pernr_d,
      bukrs       TYPE RANGE OF bukrs,
      werks       TYPE RANGE OF persa,
      orgeh       TYPE RANGE OF orgeh,
      key_date    TYPE dats,
      active_only TYPE abap_bool,
    END OF ty_scope.

  TYPES:
    BEGIN OF ty_master_row,
      employee_id          TYPE pernr_d,
      formatted_name       TYPE string,
      date_of_birth        TYPE dats,
      gender               TYPE char1,
      hire_date            TYPE dats,
      company_code         TYPE bukrs,
      personnel_area       TYPE persa,
      org_unit             TYPE orgeh,
      org_unit_name        TYPE string,
      position_name        TYPE string,
      cost_center          TYPE kostl,
      email_address        TYPE string,
      mobile_number        TYPE string,
      employment_status    TYPE char1,
      quality_status       TYPE char8,
      completeness_percent TYPE p LENGTH 4 DECIMALS 1,
    END OF ty_master_row,
    ty_master_tab TYPE STANDARD TABLE OF ty_master_row WITH EMPTY KEY.

  TYPES:
    BEGIN OF ty_issue_row,
      employee_id  TYPE pernr_d,
      last_name    TYPE char40,
      first_name   TYPE char40,
      org_unit     TYPE orgeh,
      check_id     TYPE char12,
      category     TYPE char20,
      severity     TYPE char1,
      description  TYPE char60,
      field_name   TYPE char30,
    END OF ty_issue_row,
    ty_issue_tab TYPE STANDARD TABLE OF ty_issue_row WITH EMPTY KEY.

  TYPES:
    BEGIN OF ty_audit_summary,
      total_employees  TYPE i,
      with_issues      TYPE i,
      without_issues   TYPE i,
      critical_count   TYPE i,
      warning_count    TYPE i,
      missing_data     TYPE i,
      avg_completeness TYPE p LENGTH 5 DECIMALS 1,
    END OF ty_audit_summary.

  TYPES:
    BEGIN OF ty_audit_row,
      company_code     TYPE bukrs,
      personnel_area   TYPE persa,
      org_unit         TYPE orgeh,
      org_unit_name    TYPE string,
      quality_status   TYPE char8,
      employees        TYPE i,
      with_issues      TYPE i,
      critical_count   TYPE i,
      avg_completeness TYPE p LENGTH 5 DECIMALS 1,
    END OF ty_audit_row,
    ty_audit_tab TYPE STANDARD TABLE OF ty_audit_row WITH EMPTY KEY.

  METHODS get_employee_master
    IMPORTING is_scope      TYPE ty_scope
    RETURNING VALUE(rt_data) TYPE ty_master_tab.

  METHODS get_missing_data
    IMPORTING is_scope      TYPE ty_scope
    RETURNING VALUE(rt_data) TYPE ty_issue_tab.

  METHODS get_audit_summary
    IMPORTING is_scope         TYPE ty_scope
    RETURNING VALUE(rs_summary) TYPE ty_audit_summary.

  METHODS get_audit_detail
    IMPORTING is_scope      TYPE ty_scope
    RETURNING VALUE(rt_data) TYPE ty_audit_tab.

ENDINTERFACE.
