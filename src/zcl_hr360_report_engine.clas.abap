"! <p class="shorttext synchronized">HR360 report engine</p>
"!
"! Implements ZIF_HR360_REPORT_ENGINE. Every method is a single set-based read
"! from a ZI_HR360_* CDS view; the CDS DCL (P_ORGIN) filters rows in dialog and
"! background alike. No SELECT inside LOOP, no native SQL (Clean ABAP / §5).
CLASS zcl_hr360_report_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_hr360_report_engine.
    ALIASES:
      get_employee_master FOR zif_hr360_report_engine~get_employee_master,
      get_missing_data     FOR zif_hr360_report_engine~get_missing_data,
      get_audit_summary    FOR zif_hr360_report_engine~get_audit_summary,
      get_audit_detail     FOR zif_hr360_report_engine~get_audit_detail.
ENDCLASS.


CLASS zcl_hr360_report_engine IMPLEMENTATION.

  METHOD zif_hr360_report_engine~get_employee_master.

    SELECT FROM zi_hr360_employee     AS e
      LEFT OUTER JOIN zi_hr360_personal  AS p ON p~employeeid = e~employeeid
      LEFT OUTER JOIN zi_hr360_orgassign AS o ON o~employeeid = e~employeeid
      FIELDS
        e~employeeid           AS employee_id,
        e~formattedname        AS formatted_name,
        e~dateofbirth          AS date_of_birth,
        e~gender               AS gender,
        e~hiredate             AS hire_date,
        e~companycode          AS company_code,
        e~personnelarea        AS personnel_area,
        e~orgunit              AS org_unit,
        e~orgunitname          AS org_unit_name,
        o~positionname         AS position_name,
        e~costcenter           AS cost_center,
        p~emailaddress         AS email_address,
        p~mobilenumber         AS mobile_number,
        e~employmentstatus     AS employment_status,
        e~qualitystatus        AS quality_status,
        e~completenesspercent  AS completeness_percent
      WHERE e~employeeid    IN @is_scope-pernr
        AND e~companycode   IN @is_scope-bukrs
        AND e~personnelarea IN @is_scope-werks
        AND e~orgunit       IN @is_scope-orgeh
        AND ( @is_scope-active_only = @abap_false OR e~employmentstatus = '3' )
      ORDER BY e~employeeid
      INTO CORRESPONDING FIELDS OF TABLE @rt_data.

  ENDMETHOD.


  METHOD zif_hr360_report_engine~get_missing_data.

    SELECT FROM zi_hr360_issue        AS i
      INNER JOIN zi_hr360_emp_basic   AS b ON b~employeeid = i~employeeid
      FIELDS
        i~employeeid        AS employee_id,
        b~lastname          AS last_name,
        b~firstname         AS first_name,
        b~orgunit           AS org_unit,
        i~checkid           AS check_id,
        i~category          AS category,
        i~severity          AS severity,
        i~issuedescription  AS description,
        i~fieldname         AS field_name
      WHERE b~companycode   IN @is_scope-bukrs
        AND b~personnelarea IN @is_scope-werks
        AND b~orgunit       IN @is_scope-orgeh
        AND i~employeeid    IN @is_scope-pernr
      ORDER BY i~severity, i~employeeid, i~checkid
      INTO CORRESPONDING FIELDS OF TABLE @rt_data.

  ENDMETHOD.


  METHOD zif_hr360_report_engine~get_audit_summary.

    SELECT FROM zc_hr360_kpi_overview
      FIELDS
        SUM( totalemployees )          AS total_employees,
        SUM( employeeswithissues )     AS with_issues,
        SUM( employeeswithoutissues )  AS without_issues,
        SUM( criticalissuecount )      AS critical_count,
        SUM( warningissuecount )       AS warning_count,
        SUM( missingdatacount )        AS missing_data,
        AVG( avgcompletenesspercent AS DEC( 5, 1 ) ) AS avg_completeness
      WHERE companycode   IN @is_scope-bukrs
        AND personnelarea IN @is_scope-werks
        AND orgunit       IN @is_scope-orgeh
      INTO CORRESPONDING FIELDS OF @rs_summary.

  ENDMETHOD.


  METHOD zif_hr360_report_engine~get_audit_detail.

    SELECT FROM zc_hr360_kpi_overview
      FIELDS
        companycode                    AS company_code,
        personnelarea                  AS personnel_area,
        orgunit                        AS org_unit,
        orgunitname                    AS org_unit_name,
        qualitystatus                  AS quality_status,
        SUM( totalemployees )          AS employees,
        SUM( employeeswithissues )     AS with_issues,
        SUM( criticalissuecount )      AS critical_count,
        AVG( avgcompletenesspercent AS DEC( 5, 1 ) ) AS avg_completeness
      WHERE companycode   IN @is_scope-bukrs
        AND personnelarea IN @is_scope-werks
        AND orgunit       IN @is_scope-orgeh
      GROUP BY companycode, personnelarea, orgunit, orgunitname, qualitystatus
      ORDER BY companycode, personnelarea, orgunit
      INTO CORRESPONDING FIELDS OF TABLE @rt_data.

  ENDMETHOD.

ENDCLASS.
