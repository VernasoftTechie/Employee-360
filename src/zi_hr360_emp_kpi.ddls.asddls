@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Employee DQ KPIs'
@Metadata.ignorePropagatedAnnotations: true

// Per-employee data-quality issue counts. Separate view so the root is not
// aggregating. count(distinct ...) is required here (docs/BUILD_ISSUES_LOG.md A4).

define view entity ZI_HR360_EMP_KPI
  as select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_ISSUE  as Iss on Iss.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID as EmployeeID,
      cast( count( distinct Iss.CheckID ) as abap.int4 ) as TotalIssueCount,
      cast( sum( case when Iss.Severity = 'C' then 1 else 0 end ) as abap.int4 ) as CriticalIssueCount,
      cast( sum( case when Iss.Severity = 'W' then 1 else 0 end ) as abap.int4 ) as WarningIssueCount
}
group by
  Emp.EmployeeID
