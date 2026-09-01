@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Attendance (query)'
@Metadata.allowExtensions: true
@UI.headerInfo: { typeName: 'Attendance', typeNamePlural: 'Attendance' }
define view entity ZC_HR360_ATTENDANCE
  as select from ZI_HR360_ATTENDANCE
{
      @UI.lineItem: [{ position: 10 }]
  key EmployeeID,
      @UI.lineItem: [{ position: 20 }]
  key AttendanceFrom,
      @UI.lineItem: [{ position: 30 }]
  key AttendanceTypeCode,
      @UI.lineItem: [{ position: 40 }]
      AttendanceTo,
      @UI.lineItem: [{ position: 50 }]
      AttendanceDays,
      @UI.lineItem: [{ position: 60 }]
      AttendanceHours,
      @UI.lineItem: [{ position: 70 }]
      StartTime,
      @UI.lineItem: [{ position: 80 }]
      EndTime
}
