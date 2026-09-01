@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Employee (query)'
@Metadata.allowExtensions: true
@Search.searchable: true
@UI.headerInfo: {
  typeName: 'Employee',
  typeNamePlural: 'Employees',
  title: { type: #STANDARD, value: 'FormattedName' },
  description: { type: #STANDARD, value: 'EmployeeID' }
}

// Read-only query view. UI annotations are inline for now (rulebook wants a
// Metadata Extension - moves there once abapGit DDLX format is confirmed;
// BUILD_ISSUES_LOG.md A25).

define view entity ZC_HR360_EMPLOYEE
  as select from ZI_HR360_EMPLOYEE

  association [0..*] to ZC_HR360_EDUCATION as _Education
    on _Education.EmployeeID = $projection.EmployeeID

{
      @UI.facet: [
        { id: 'Header',    purpose: #HEADER,   type: #IDENTIFICATION_REFERENCE, label: 'Employee',        position: 10 },
        { id: 'Education',  purpose: #STANDARD, type: #LINEITEM_REFERENCE, targetElement: '_Education', label: 'Education', position: 20 }
      ]

      @UI.lineItem:      [{ position: 10 }]
      @UI.identification: [{ position: 10 }]
  key EmployeeID,

      @Search.defaultSearchElement: true
      @UI.lineItem:      [{ position: 20 }]
      @UI.identification: [{ position: 20 }]
      LastName,

      @Search.defaultSearchElement: true
      @UI.identification: [{ position: 30 }]
      FirstName,

      @UI.lineItem: [{ position: 25 }]
      FormattedName,

      @UI.identification: [{ position: 40 }]
      DateOfBirth,
      @UI.identification: [{ position: 50 }]
      Gender,
      @UI.identification: [{ position: 60 }]
      Nationality,
      @UI.identification: [{ position: 70 }]
      HireDate,

      @UI.lineItem:      [{ position: 30 }]
      @UI.selectionField: [{ position: 10 }]
      @UI.identification: [{ position: 80 }]
      CompanyCode,

      @UI.lineItem:      [{ position: 40 }]
      @UI.selectionField: [{ position: 20 }]
      @UI.identification: [{ position: 90 }]
      PersonnelArea,

      PersonnelSubarea,

      @UI.selectionField: [{ position: 30 }]
      @UI.identification: [{ position: 100 }]
      EmployeeGroup,

      EmployeeSubgroup,

      @Search.defaultSearchElement: true
      @UI.lineItem:      [{ position: 50 }]
      @UI.selectionField: [{ position: 40 }]
      @UI.identification: [{ position: 110 }]
      OrgUnit,

      @UI.identification: [{ position: 120 }]
      PositionId,
      @UI.identification: [{ position: 130 }]
      CostCenter,
      Job,
      BirthPlace,
      MaritalStatus,
      @UI.identification: [{ position: 140 }]
      Street,
      @UI.identification: [{ position: 150 }]
      City,
      PostalCode,
      Country,
      @UI.identification: [{ position: 160 }]
      EmailAddress,
      @UI.identification: [{ position: 170 }]
      MobileNumber,
      IBAN,

      @UI.lineItem:      [{ position: 60 }]
      @UI.identification: [{ position: 180 }]
      TotalIssueCount,

      @UI.lineItem: [{ position: 70 }]
      CriticalIssueCount,

      WarningIssueCount,

      @UI.lineItem:      [{ position: 80, criticality: 'QualityStatusCriticality' }]
      @UI.selectionField: [{ position: 50 }]
      @UI.identification: [{ position: 190, criticality: 'QualityStatusCriticality' }]
      QualityStatus,

      QualityStatusCriticality,

      @UI.lineItem:      [{ position: 90 }]
      @UI.identification: [{ position: 200 }]
      CompletenessPercent,

      _Education
}
