@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Attendance'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #COMPOSITE

define view entity ZI_HR360_ATTENDANCE
  as select from pa2002 as A

    left outer join t554t as AT on  AT.sprsl = $session.system_language
                                and AT.moabw = A.moabw
                                and AT.awart = A.awart

  association to parent ZI_HR360_EMPLOYEE as _Employee
    on $projection.EmployeeID = _Employee.EmployeeID

{
  key A.pernr    as EmployeeID,
  key A.begda    as AttendanceFrom,
  key A.awart    as AttendanceType,
      A.endda    as AttendanceTo,
      AT.atext   as AttendanceTypeName,
      A.abwtg    as AttendanceDays,
      A.stdaz    as AttendanceHours,
      A.beguz    as StartTime,
      A.enduz    as EndTime,

      _Employee
}
