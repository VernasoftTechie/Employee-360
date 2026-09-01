@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Hire Date'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_HR360_HIREDATE
  as select from pa0000
{
  key pernr        as EmployeeID,
      min( cast( begda as abap.dats ) ) as HireDate
}
where massn = '01'
group by pernr
