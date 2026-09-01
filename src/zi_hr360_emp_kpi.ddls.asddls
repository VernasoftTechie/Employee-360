@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Employee Data Quality KPIs'
@Metadata.ignorePropagatedAnnotations: true

// Per-employee data-quality issue counts, aggregated over ZI_HR360_ISSUE.
// Kept separate so the root ZI_HR360_EMPLOYEE is not an aggregating view.

define view entity ZI_HR360_EMP_KPI
  as select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_ISSUE  as Iss on Iss.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                                        as EmployeeID,
      cast( count( Iss.CheckID ) as abap.int4 )                             as TotalIssueCount,
      cast( sum( case when Iss.Severity = 'C' then 1 else 0 end ) as abap.int4 ) as CriticalIssueCount,
      cast( sum( case when Iss.Severity = 'W' then 1 else 0 end ) as abap.int4 ) as WarningIssueCount
}
group by
  Emp.EmployeeID
