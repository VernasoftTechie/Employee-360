@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Employee Data Quality KPIs'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC

// Per-employee data-quality issue counts, aggregated over ZI_HR360_ISSUE.
// Kept separate so the root ZI_HR360_EMPLOYEE is not an aggregating view.
// QualityStatus / CompletenessPercent are derived from these counts in the root
// (plain columns there, not aggregates).

define view entity ZI_HR360_EMP_KPI
  as select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_ISSUE  as Iss on Iss.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                              as EmployeeID,
      count( Iss.CheckID )                                        as TotalIssueCount,
      sum( case when Iss.Severity = 'C' then 1 else 0 end )       as CriticalIssueCount,
      sum( case when Iss.Severity = 'W' then 1 else 0 end )       as WarningIssueCount
}
group by
  Emp.EmployeeID
