@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Employee (root)'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #CONSUMPTION

define root view entity ZI_HR360_EMPLOYEE
  as select from ZI_HR360_EMP_BASIC as Emp

    left outer join ZI_HR360_EMP_KPI  as Kpi on Kpi.EmployeeID = Emp.EmployeeID
    left outer join ZI_HR360_MANAGER  as Mgr on Mgr.EmployeeID = Emp.EmployeeID
    left outer join ZI_HR360_HIREDATE as Hd  on Hd.EmployeeID  = Emp.EmployeeID

  composition [1..1] of ZI_HR360_PERSONAL   as _Personal
  composition [1..1] of ZI_HR360_ORGASSIGN  as _OrgAssignment
  composition [0..*] of ZI_HR360_EDUCATION  as _Education
  composition [0..*] of ZI_HR360_QUALIF     as _Qualification
  composition [0..*] of ZI_HR360_LEAVE      as _LeaveBalance
  composition [0..*] of ZI_HR360_ATTENDANCE as _Attendance
  composition [0..*] of ZI_HR360_PAYROLL    as _Payroll
  composition [0..*] of ZI_HR360_DOCUMENT   as _Document

  association [0..*] to ZI_HR360_TIMELINE   as _Timeline     on  _Timeline.EmployeeID    = $projection.EmployeeID
  association [0..*] to ZI_HR360_ISSUE      as _DataQuality  on  _DataQuality.EmployeeID = $projection.EmployeeID
  association [0..1] to ZI_HR360_EMPLOYEE   as _Manager      on  _Manager.EmployeeID     = $projection.ManagerID
  association [0..*] to ZI_HR360_EMPLOYEE   as _DirectReport on  _DirectReport.ManagerID = $projection.EmployeeID

{
  key Emp.EmployeeID                                       as EmployeeID,

      Emp.LastName                                         as LastName,
      Emp.FirstName                                        as FirstName,
      concat(concat(Emp.FirstName, ' '), Emp.LastName)     as FormattedName,
      Emp.DateOfBirth                                      as DateOfBirth,
      Emp.Gender                                           as Gender,
      Emp.Nationality                                      as Nationality,
      Emp.EmploymentStatus                                 as EmploymentStatus,
      Hd.HireDate                                          as HireDate,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelAreaName                                as PersonnelAreaName,
      Emp.PersonnelSubarea                                 as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.EmployeeGroupName                                as EmployeeGroupName,
      Emp.EmployeeSubgroup                                 as EmployeeSubgroup,
      Emp.EmployeeSubgroupName                             as EmployeeSubgroupName,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.OrgUnitName                                      as OrgUnitName,
      Emp.Position                                         as Position,
      Emp.CostCenter                                       as CostCenter,
      Mgr.ManagerID                                        as ManagerID,
      Mgr.ManagerName                                      as ManagerName,

      cast( coalesce( Kpi.TotalIssueCount,    0 ) as abap.int4 )  as TotalIssueCount,
      cast( coalesce( Kpi.CriticalIssueCount, 0 ) as abap.int4 )  as CriticalIssueCount,
      cast( coalesce( Kpi.WarningIssueCount,  0 ) as abap.int4 )  as WarningIssueCount,

      case
        when coalesce( Kpi.CriticalIssueCount, 0 ) > 0 then cast( 'CRITICAL' as abap.char( 8 ) )
        when coalesce( Kpi.TotalIssueCount,    0 ) > 0 then cast( 'WARNING'  as abap.char( 8 ) )
        else cast( 'OK' as abap.char( 8 ) )
      end                                                          as QualityStatus,

      cast( ( 12 - coalesce( Kpi.TotalIssueCount, 0 ) ) * 100 / 12 as abap.dec( 5, 1 ) ) as CompletenessPercent,

      _Personal,
      _OrgAssignment,
      _Education,
      _Qualification,
      _LeaveBalance,
      _Attendance,
      _Payroll,
      _Document,
      _Timeline,
      _DataQuality,
      _Manager,
      _DirectReport
}
