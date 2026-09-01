"! <p class="shorttext synchronized">HR360 report engine</p>
"!
"! Implements ZIF_HR360_REPORT_ENGINE. Every method is a single set-based read
"! from a ZI_HR360_* CDS view; the CDS DCL (P_ORGIN) filters rows. No SELECT in
"! LOOP, no native SQL (Clean ABAP / Rulebook 5).
CLASS zcl_hr360_report_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hr360_report_engine.
ENDCLASS.


CLASS zcl_hr360_report_engine IMPLEMENTATION.

  METHOD zif_hr360_report_engine~get_employee_master.

    SELECT FROM zi_hr360_employee AS e
      LEFT OUTER JOIN zi_hr360_personal AS p ON p~EmployeeID = e~EmployeeID
      FIELDS
        e~EmployeeID          AS employee_id,
        e~FormattedName       AS formatted_name,
        e~DateOfBirth         AS date_of_birth,
        e~Gender              AS gender,
        e~HireDate            AS hire_date,
        e~CompanyCode         AS company_code,
        e~PersonnelArea       AS personnel_area,
        e~OrgUnit             AS org_unit,
        e~PositionId            AS position_name,
        e~CostCenter          AS cost_center,
        p~EmailAddress        AS email_address,
        p~MobileNumber        AS mobile_number,
        e~EmploymentStatus    AS employment_status,
        e~QualityStatus       AS quality_status,
        e~CompletenessPercent AS completeness_percent
      WHERE e~EmployeeID    IN @is_scope-pernr
        AND e~CompanyCode   IN @is_scope-bukrs
        AND e~PersonnelArea IN @is_scope-werks
        AND e~OrgUnit       IN @is_scope-orgeh
      ORDER BY e~EmployeeID
      INTO CORRESPONDING FIELDS OF TABLE @rt_data.

  ENDMETHOD.


  METHOD zif_hr360_report_engine~get_missing_data.

    SELECT FROM zi_hr360_issue      AS i
      INNER JOIN zi_hr360_emp_basic AS b ON b~EmployeeID = i~EmployeeID
      FIELDS
        i~EmployeeID       AS employee_id,
        b~LastName         AS last_name,
        b~FirstName        AS first_name,
        b~OrgUnit          AS org_unit,
        i~CheckID          AS check_id,
        i~Category         AS category,
        i~Severity         AS severity,
        i~IssueDescription AS description,
        i~FieldName        AS field_name
      WHERE b~CompanyCode   IN @is_scope-bukrs
        AND b~PersonnelArea IN @is_scope-werks
        AND b~OrgUnit       IN @is_scope-orgeh
        AND i~EmployeeID    IN @is_scope-pernr
      ORDER BY i~Severity, i~EmployeeID, i~CheckID
      INTO CORRESPONDING FIELDS OF TABLE @rt_data.

  ENDMETHOD.


  METHOD zif_hr360_report_engine~get_audit_summary.

    SELECT FROM zi_hr360_emp_basic AS b
      INNER JOIN zi_hr360_emp_kpi  AS k ON k~EmployeeID = b~EmployeeID
      FIELDS
        COUNT( * )                                                AS total_employees,
        SUM( CASE WHEN k~TotalIssueCount > 0 THEN 1 ELSE 0 END )  AS with_issues,
        SUM( CASE WHEN k~TotalIssueCount = 0 THEN 1 ELSE 0 END )  AS without_issues,
        SUM( k~CriticalIssueCount )                               AS critical_count,
        SUM( k~WarningIssueCount )                                AS warning_count,
        SUM( k~TotalIssueCount )                                  AS missing_data
      WHERE b~CompanyCode   IN @is_scope-bukrs
        AND b~PersonnelArea IN @is_scope-werks
        AND b~OrgUnit       IN @is_scope-orgeh
      INTO CORRESPONDING FIELDS OF @rs_summary.

  ENDMETHOD.


  METHOD zif_hr360_report_engine~get_audit_detail.

    SELECT FROM zi_hr360_emp_basic AS b
      INNER JOIN zi_hr360_emp_kpi  AS k ON k~EmployeeID = b~EmployeeID
      FIELDS
        b~CompanyCode                                            AS company_code,
        b~PersonnelArea                                          AS personnel_area,
        b~OrgUnit                                                AS org_unit,
        COUNT( * )                                               AS employees,
        SUM( CASE WHEN k~TotalIssueCount > 0 THEN 1 ELSE 0 END ) AS with_issues,
        SUM( k~CriticalIssueCount )                              AS critical_count
      WHERE b~CompanyCode   IN @is_scope-bukrs
        AND b~PersonnelArea IN @is_scope-werks
        AND b~OrgUnit       IN @is_scope-orgeh
      GROUP BY b~CompanyCode, b~PersonnelArea, b~OrgUnit
      ORDER BY b~CompanyCode, b~PersonnelArea, b~OrgUnit
      INTO CORRESPONDING FIELDS OF TABLE @rt_data.

  ENDMETHOD.

ENDCLASS.
