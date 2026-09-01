@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Hire Date'
@Metadata.ignorePropagatedAnnotations: true

// Earliest start date of a hiring-type personnel action. '01' is the SAP
// default hiring action (T529A); adjust the predicate to the client's set.

define view entity ZI_HR360_HIREDATE
  as select from pa0000
{
  key pernr        as EmployeeID,
      min( begda ) as HireDate
}
where massn = '01'
group by pernr
