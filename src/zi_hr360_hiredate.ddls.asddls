@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Hire Date'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC

// Earliest action start date for a hiring-type action.
// Hiring action codes are client customizing (T529A). '01' is the SAP default
// "Hiring"; extend the IN list if the client uses additional hiring actions.

define view entity ZI_HR360_HIREDATE
  as select from pa0000

  where massn in ( '01' )

{
  key pernr        as EmployeeID,
      min( begda ) as HireDate
}
group by
  pernr
