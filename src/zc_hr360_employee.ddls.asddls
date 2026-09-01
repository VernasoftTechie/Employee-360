@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Employee (proj)'
@Metadata.allowExtensions: true
@Search.searchable: true

define root view entity ZC_HR360_EMPLOYEE
  provider contract transactional_query
  as projection on ZI_HR360_EMPLOYEE
{
  key EmployeeID,
      @Search.defaultSearchElement: true
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
      PersonnelSubarea,
      EmployeeGroup,
      EmployeeSubgroup,
      @Search.defaultSearchElement: true
      OrgUnit,
      PositionId,
      CostCenter,
      TotalIssueCount,
      CriticalIssueCount,
      WarningIssueCount,
      QualityStatus,
      QualityStatusCriticality,
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
      _DataQuality   : redirected to ZC_HR360_ISSUE
}
