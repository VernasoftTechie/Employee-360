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
      Job,
      BirthPlace,
      MaritalStatus,
      Street,
      City,
      PostalCode,
      Country,
      EmailAddress,
      MobileNumber,
      IBAN,
      TotalIssueCount,
      CriticalIssueCount,
      WarningIssueCount,
      QualityStatus,
      QualityStatusCriticality,
      CompletenessPercent
}
