@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Attendance (proj)'
@Metadata.allowExtensions: true
define view entity ZC_HR360_ATTENDANCE as projection on ZI_HR360_ATTENDANCE
{
  key EmployeeID, key AttendanceFrom, key AttendanceType,
      AttendanceTo, AttendanceDays, AttendanceHours, StartTime, EndTime
}
