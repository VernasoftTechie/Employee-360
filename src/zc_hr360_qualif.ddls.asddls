@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Skills (query)'
@Metadata.allowExtensions: true
@UI.headerInfo: { typeName: 'Qualification', typeNamePlural: 'Skills and Certifications' }
define view entity ZC_HR360_QUALIF
  as select from ZI_HR360_QUALIF
{
      @UI.lineItem: [{ position: 10 }]
  key EmployeeID,
      @UI.lineItem: [{ position: 20 }]
  key QualificationID,
      @UI.lineItem: [{ position: 30 }]
  key ValidFrom,
      @UI.lineItem: [{ position: 40 }]
      ValidTo,
      @UI.lineItem: [{ position: 50 }]
      QualificationTypeCode,
      @UI.lineItem: [{ position: 60 }]
      Proficiency,
      @UI.lineItem: [{ position: 70 }]
      IsExpired
}
