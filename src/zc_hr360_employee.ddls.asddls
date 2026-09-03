@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Employee (query)'
@Metadata.allowExtensions: true
@Search.searchable: true
@UI.headerInfo: {
  typeName: 'Employee',
  typeNamePlural: 'Employees',
  title:       { type: #STANDARD, value: 'FormattedName' },
  description: { type: #STANDARD, value: 'EmployeeID' }
}

// Read-only query view. Minimal, well-known-good @UI annotation set so the
// Fiori Elements preview renders. Advanced touches (completeness gauge,
// header KPI datapoints) are for the UI team to add in a metadata extension.
// See BUILD_ISSUES_LOG.md A32.

define view entity ZC_HR360_EMPLOYEE
  as select from ZI_HR360_EMPLOYEE

  association [0..*] to ZC_HR360_EDUCATION  as _Education     on _Education.EmployeeID     = $projection.EmployeeID
  association [0..*] to ZC_HR360_QUALIF     as _Qualification on _Qualification.EmployeeID = $projection.EmployeeID
  association [0..*] to ZC_HR360_LEAVE      as _LeaveBalance  on _LeaveBalance.EmployeeID  = $projection.EmployeeID
  association [0..*] to ZC_HR360_ATTENDANCE as _Attendance    on _Attendance.EmployeeID    = $projection.EmployeeID
  association [0..*] to ZC_HR360_PAYROLL    as _Payroll       on _Payroll.EmployeeID       = $projection.EmployeeID
  association [0..*] to ZC_HR360_DOCUMENT   as _Document      on _Document.EmployeeID      = $projection.EmployeeID
  association [0..*] to ZC_HR360_TIMELINE   as _Timeline      on _Timeline.EmployeeID      = $projection.EmployeeID
  association [0..*] to ZC_HR360_ISSUE      as _DataQuality   on _DataQuality.EmployeeID   = $projection.EmployeeID

{
      @UI.facet: [
        { id: 'Header',      purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE,                             label: 'Employee',       position: 10 },
        { id: 'Education',   purpose: #STANDARD, type: #LINEITEM_REFERENCE, targetElement: '_Education',     label: 'Education',       position: 20 },
        { id: 'Skills',      purpose: #STANDARD, type: #LINEITEM_REFERENCE, targetElement: '_Qualification', label: 'Skills & Certs', position: 30 },
        { id: 'Leave',       purpose: #STANDARD, type: #LINEITEM_REFERENCE, targetElement: '_LeaveBalance',  label: 'Leave & Quotas', position: 40 },
        { id: 'Attendance',  purpose: #STANDARD, type: #LINEITEM_REFERENCE, targetElement: '_Attendance',    label: 'Attendance',     position: 50 },
        { id: 'Payroll',     purpose: #STANDARD, type: #LINEITEM_REFERENCE, targetElement: '_Payroll',       label: 'Pay History',    position: 60 },
        { id: 'Documents',   purpose: #STANDARD, type: #LINEITEM_REFERENCE, targetElement: '_Document',      label: 'Documents',      position: 70 },
        { id: 'Timeline',    purpose: #STANDARD, type: #LINEITEM_REFERENCE, targetElement: '_Timeline',      label: 'Timeline',       position: 80 },
        { id: 'DataQuality', purpose: #STANDARD, type: #LINEITEM_REFERENCE, targetElement: '_DataQuality',   label: 'Data Quality',   position: 90 }
      ]

      @UI.lineItem:       [{ position: 10 }]
      @UI.identification: [{ position: 10 }]
  key EmployeeID,

      @Search.defaultSearchElement: true
      @UI.lineItem:       [{ position: 20 }]
      @UI.identification: [{ position: 20 }]
      LastName,

      @Search.defaultSearchElement: true
      @UI.identification: [{ position: 30 }]
      FirstName,

      @UI.lineItem:       [{ position: 30 }]
      @UI.identification: [{ position: 40 }]
      FormattedName,

      @UI.identification: [{ position: 50 }]
      DateOfBirth,
      @UI.identification: [{ position: 60 }]
      Gender,
      @UI.identification: [{ position: 70 }]
      Nationality,
      @UI.identification: [{ position: 80 }]
      HireDate,

      @UI.lineItem:       [{ position: 40 }]
      @UI.selectionField: [{ position: 10 }]
      @UI.identification: [{ position: 90 }]
      CompanyCode,

      @UI.lineItem:       [{ position: 50 }]
      @UI.selectionField: [{ position: 20 }]
      @UI.identification: [{ position: 100 }]
      PersonnelArea,

      @UI.identification: [{ position: 110 }]
      PersonnelSubarea,

      @UI.selectionField: [{ position: 30 }]
      @UI.identification: [{ position: 120 }]
      EmployeeGroup,

      @UI.identification: [{ position: 130 }]
      EmployeeSubgroup,

      @Search.defaultSearchElement: true
      @UI.lineItem:       [{ position: 60 }]
      @UI.selectionField: [{ position: 40 }]
      @UI.identification: [{ position: 140 }]
      OrgUnit,

      @UI.identification: [{ position: 150 }]
      PositionId,
      @UI.identification: [{ position: 160 }]
      CostCenter,
      @UI.identification: [{ position: 170 }]
      Job,
      @UI.identification: [{ position: 180 }]
      BirthPlace,
      @UI.identification: [{ position: 190 }]
      MaritalStatus,
      @UI.identification: [{ position: 200 }]
      Street,
      @UI.identification: [{ position: 210 }]
      City,
      @UI.identification: [{ position: 220 }]
      PostalCode,
      @UI.identification: [{ position: 230 }]
      Country,
      @UI.identification: [{ position: 240 }]
      EmailAddress,
      @UI.identification: [{ position: 250 }]
      MobileNumber,
      @UI.identification: [{ position: 260 }]
      IBAN,

      @UI.lineItem:       [{ position: 70 }]
      @UI.identification: [{ position: 270 }]
      TotalIssueCount,

      @UI.lineItem:       [{ position: 80 }]
      @UI.identification: [{ position: 280 }]
      CriticalIssueCount,

      @UI.lineItem:       [{ position: 85 }]
      WarningIssueCount,

      @UI.lineItem:       [{ position: 90, criticality: 'QualityStatusCriticality' }]
      @UI.selectionField: [{ position: 50 }]
      @UI.identification: [{ position: 290, criticality: 'QualityStatusCriticality' }]
      QualityStatus,

      QualityStatusCriticality,

      @UI.lineItem:       [{ position: 100 }]
      @UI.identification: [{ position: 300 }]
      CompletenessPercent,

      _Education,
      _Qualification,
      _LeaveBalance,
      _Attendance,
      _Payroll,
      _Document,
      _Timeline,
      _DataQuality
}
