@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Employee (root)'
@Metadata.ignorePropagatedAnnotations: true

define root view entity ZI_HR360_EMPLOYEE
  as select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_KPI  as Kpi on Kpi.EmployeeID = Emp.EmployeeID
    left outer join ZI_HR360_HIREDATE as Hd  on Hd.EmployeeID  = Emp.EmployeeID

  association [0..1] to ZI_HR360_PERSONAL   as _Personal      on _Personal.EmployeeID      = $projection.EmployeeID
  association [0..1] to ZI_HR360_ORGASSIGN  as _OrgAssignment on _OrgAssignment.EmployeeID = $projection.EmployeeID
  association [0..*] to ZI_HR360_EDUCATION  as _Education      on _Education.EmployeeID     = $projection.EmployeeID
  association [0..*] to ZI_HR360_QUALIF     as _Qualification  on _Qualification.EmployeeID = $projection.EmployeeID
  association [0..*] to ZI_HR360_LEAVE      as _LeaveBalance   on _LeaveBalance.EmployeeID  = $projection.EmployeeID
  association [0..*] to ZI_HR360_ATTENDANCE as _Attendance     on _Attendance.EmployeeID    = $projection.EmployeeID
  association [0..*] to ZI_HR360_PAYROLL    as _Payroll        on _Payroll.EmployeeID       = $projection.EmployeeID
  association [0..*] to ZI_HR360_DOCUMENT   as _Document       on _Document.EmployeeID      = $projection.EmployeeID
  association [0..*] to ZI_HR360_TIMELINE   as _Timeline       on _Timeline.EmployeeID      = $projection.EmployeeID
  association [0..*] to ZI_HR360_ISSUE      as _DataQuality    on _DataQuality.EmployeeID   = $projection.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
      Emp.LastName                                         as LastName,
      Emp.FirstName                                        as FirstName,
      concat( concat( Emp.FirstName, ' ' ), Emp.LastName ) as FormattedName,
      Emp.DateOfBirth                                      as DateOfBirth,
      Emp.Gender                                           as Gender,
      Emp.Nationality                                      as Nationality,
      Emp.EmploymentStatus                                 as EmploymentStatus,
      Hd.HireDate                                          as HireDate,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                                 as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.EmployeeSubgroup                                 as EmployeeSubgroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.Position                                         as Position,
      Emp.CostCenter                                       as CostCenter,

      cast( coalesce( Kpi.TotalIssueCount,    0 ) as abap.int4 ) as TotalIssueCount,
      cast( coalesce( Kpi.CriticalIssueCount, 0 ) as abap.int4 ) as CriticalIssueCount,
      cast( coalesce( Kpi.WarningIssueCount,  0 ) as abap.int4 ) as WarningIssueCount,

      case
        when coalesce( Kpi.CriticalIssueCount, 0 ) > 0 then cast( 'CRITICAL' as abap.char( 8 ) )
        when coalesce( Kpi.TotalIssueCount,    0 ) > 0 then cast( 'WARNING'  as abap.char( 8 ) )
        else cast( 'OK' as abap.char( 8 ) )
      end                                                       as QualityStatus,

      division( ( 12 - coalesce( Kpi.TotalIssueCount, 0 ) ) * 100, 12, 1 ) as CompletenessPercent,

      _Personal,
      _OrgAssignment,
      _Education,
      _Qualification,
      _LeaveBalance,
      _Attendance,
      _Payroll,
      _Document,
      _Timeline,
      _DataQuality
}
