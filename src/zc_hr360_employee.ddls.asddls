@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Employee (projection)'
@Metadata.allowExtensions: true
@Search.searchable: true

define root view entity ZC_HR360_EMPLOYEE
  provider contract transactional_query
  as projection on ZI_HR360_EMPLOYEE
{
  key EmployeeID,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      LastName,
      @Search.defaultSearchElement: true
      FirstName,
      FormattedName,
      DateOfBirth,
      Gender,
      Nationality,
      EmploymentStatus,
      HireDate,
      CompanyCode,
      PersonnelArea,
      PersonnelAreaName,
      PersonnelSubarea,
      EmployeeGroup,
      EmployeeGroupName,
      EmployeeSubgroup,
      EmployeeSubgroupName,
      @Search.defaultSearchElement: true
      OrgUnit,
      OrgUnitName,
      Position,
      CostCenter,
      ManagerID,
      ManagerName,

      TotalIssueCount,
      CriticalIssueCount,
      WarningIssueCount,
      QualityStatus,
      case QualityStatus
        when 'OK'       then 3
        when 'WARNING'  then 2
        when 'CRITICAL' then 1
        else 0
      end                as QualityStatusCriticality,
      CompletenessPercent,

      _Personal      : redirected to ZC_HR360_PERSONAL,
      _OrgAssignment : redirected to ZC_HR360_ORGASSIGN,
      _Education     : redirected to ZC_HR360_EDUCATION,
      _Qualification : redirected to ZC_HR360_QUALIF,
      _LeaveBalance  : redirected to ZC_HR360_LEAVE,
      _Attendance    : redirected to ZC_HR360_ATTENDANCE,
      _Payroll       : redirected to ZC_HR360_PAYROLL,
      _Document      : redirected to ZC_HR360_DOCUMENT,
      _Timeline      : redirected to ZC_HR360_TIMELINE,
      _DataQuality   : redirected to ZC_HR360_ISSUE,
      _Manager       : redirected to ZC_HR360_EMPLOYEE,
      _DirectReport  : redirected to ZC_HR360_EMPLOYEE
}
