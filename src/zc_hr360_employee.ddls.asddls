@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Employee (query)'
@Metadata.allowExtensions: true
@Search.searchable: true

// Read-only query view over the flattened employee. Exposed directly in the
// service. The transactional RAP BO wrapper is deferred (BUILD_ISSUES_LOG.md A19).

define view entity ZC_HR360_EMPLOYEE
  as select from ZI_HR360_EMPLOYEE
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
