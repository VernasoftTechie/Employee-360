@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Attendance'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_HR360_ATTENDANCE
  as select from pa2002 as A
{
  key A.pernr as EmployeeID,
  key A.begda as AttendanceFrom,
  key A.awart as AttendanceType,
      A.endda as AttendanceTo,
      A.abwtg as AttendanceDays,
      A.stdaz as AttendanceHours,
      A.beguz as StartTime,
      A.enduz as EndTime
}
