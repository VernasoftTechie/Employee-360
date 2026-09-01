"! <p class="shorttext synchronized">HR360 report engine - contract</p>
"!
"! Data retrieval for the three executable reports. All access is set-based
"! through the ZI_HR360_* CDS views (no SELECT in LOOP, no native SQL).
"! Implemented by ZCL_HR360_REPORT_ENGINE.
INTERFACE zif_hr360_report_engine
  PUBLIC.

  TYPES ty_pernr_range TYPE RANGE OF pernr_d.
  TYPES ty_bukrs_range TYPE RANGE OF bukrs.
  TYPES ty_werks_range TYPE RANGE OF persa.
  TYPES ty_orgeh_range TYPE RANGE OF orgeh.

  TYPES: BEGIN OF ty_scope,
           pernr       TYPE ty_pernr_range,
           bukrs       TYPE ty_bukrs_range,
           werks       TYPE ty_werks_range,
           orgeh       TYPE ty_orgeh_range,
           key_date    TYPE d,
           active_only TYPE abap_bool,
         END OF ty_scope.

  TYPES: BEGIN OF ty_master_row,
           employee_id          TYPE pernr_d,
           formatted_name       TYPE c LENGTH 80,
           date_of_birth        TYPE d,
           gender               TYPE c LENGTH 1,
           hire_date            TYPE d,
           company_code         TYPE bukrs,
           personnel_area       TYPE persa,
           org_unit             TYPE orgeh,
           org_unit_name        TYPE c LENGTH 40,
           position_name        TYPE c LENGTH 40,
           cost_center          TYPE kostl,
           email_address        TYPE c LENGTH 241,
           mobile_number        TYPE c LENGTH 241,
           employment_status    TYPE c LENGTH 1,
           quality_status       TYPE c LENGTH 8,
           completeness_percent TYPE p LENGTH 4 DECIMALS 1,
         END OF ty_master_row,
         ty_master_tab TYPE STANDARD TABLE OF ty_master_row WITH EMPTY KEY.

  TYPES: BEGIN OF ty_issue_row,
           employee_id TYPE pernr_d,
           last_name   TYPE c LENGTH 40,
           first_name  TYPE c LENGTH 40,
           org_unit    TYPE orgeh,
           check_id    TYPE c LENGTH 12,
           category    TYPE c LENGTH 20,
           severity    TYPE c LENGTH 1,
           description TYPE c LENGTH 60,
           field_name  TYPE c LENGTH 30,
         END OF ty_issue_row,
         ty_issue_tab TYPE STANDARD TABLE OF ty_issue_row WITH EMPTY KEY.

  TYPES: BEGIN OF ty_audit_summary,
           total_employees  TYPE i,
           with_issues      TYPE i,
           without_issues   TYPE i,
           critical_count   TYPE i,
           warning_count    TYPE i,
           missing_data     TYPE i,
           avg_completeness TYPE p LENGTH 5 DECIMALS 1,
         END OF ty_audit_summary.

  TYPES: BEGIN OF ty_audit_row,
           company_code     TYPE bukrs,
           personnel_area   TYPE persa,
           org_unit         TYPE orgeh,
           org_unit_name    TYPE c LENGTH 40,
           quality_status   TYPE c LENGTH 8,
           employees        TYPE i,
           with_issues      TYPE i,
           critical_count   TYPE i,
           avg_completeness TYPE p LENGTH 5 DECIMALS 1,
         END OF ty_audit_row,
         ty_audit_tab TYPE STANDARD TABLE OF ty_audit_row WITH EMPTY KEY.

  METHODS get_employee_master
    IMPORTING is_scope       TYPE ty_scope
    RETURNING VALUE(rt_data)  TYPE ty_master_tab.

  METHODS get_missing_data
    IMPORTING is_scope       TYPE ty_scope
    RETURNING VALUE(rt_data)  TYPE ty_issue_tab.

  METHODS get_audit_summary
    IMPORTING is_scope         TYPE ty_scope
    RETURNING VALUE(rs_summary) TYPE ty_audit_summary.

  METHODS get_audit_detail
    IMPORTING is_scope       TYPE ty_scope
    RETURNING VALUE(rt_data)  TYPE ty_audit_tab.

ENDINTERFACE.
