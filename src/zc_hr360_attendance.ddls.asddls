@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Attendance (projection)'
@Metadata.allowExtensions: true

define view entity ZC_HR360_ATTENDANCE
  as projection on ZI_HR360_ATTENDANCE
{
  key EmployeeID,
  key AttendanceFrom,
  key AttendanceType,
      AttendanceTo,
      AttendanceTypeName,
      AttendanceDays,
      AttendanceHours,
      StartTime,
      EndTime
}
