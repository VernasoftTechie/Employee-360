@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Line Manager'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC

// Phase 1 stub. Manager resolution over the OM position hierarchy is done in
// ZCL_HR360_ORG_READER. A pure-CDS manager view needs the client's confirmed
// chief-position relationship (HRP1001) - BUGS_AND_ISSUES.md #004. Until then
// ManagerID / ManagerName are empty.

define view entity ZI_HR360_MANAGER
  as select from pa0001 as Emp
{
  key Emp.pernr                        as EmployeeID,
      cast( 0 as abap.numc( 8 ) )      as ManagerID,
      cast( '' as abap.char( 80 ) )    as ManagerName
}
where Emp.begda <= $session.system_date
  and Emp.endda >= $session.system_date
