@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Attendance'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_HR360_ATTENDANCE
  as select from pa2002 as A
{
  key A.pernr as EmployeeID,
  key cast( A.begda as abap.dats ) as AttendanceFrom,
  key A.awart as AttendanceTypeCode,
      cast( A.endda as abap.dats ) as AttendanceTo,
      cast( A.abwtg as abap.dec( 7, 2 ) ) as AttendanceDays,
      cast( A.stdaz as abap.dec( 7, 2 ) ) as AttendanceHours,
      cast( A.beguz as abap.tims ) as StartTime,
      cast( A.enduz as abap.tims ) as EndTime
}
