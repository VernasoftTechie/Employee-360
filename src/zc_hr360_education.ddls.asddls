@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Education (query)'
@Metadata.allowExtensions: true
@UI.headerInfo: { typeName: 'Education', typeNamePlural: 'Education' }

define view entity ZC_HR360_EDUCATION
  as select from ZI_HR360_EDUCATION
{
      @UI.lineItem:       [{ position: 10 }]
      @UI.identification: [{ position: 10 }]
  key EmployeeID,
      @UI.lineItem:       [{ position: 20 }]
      @UI.identification: [{ position: 20 }]
  key EducationTypeCode,
      @UI.lineItem:       [{ position: 30 }]
      @UI.identification: [{ position: 30 }]
  key ValidFrom,
      @UI.lineItem:       [{ position: 40 }]
      @UI.identification: [{ position: 40 }]
      ValidTo,
      @UI.lineItem:       [{ position: 50 }]
      @UI.identification: [{ position: 50 }]
      EducationCategory,
      @UI.lineItem:       [{ position: 60 }]
      @UI.identification: [{ position: 60 }]
      Establishment,
      @UI.lineItem:       [{ position: 70 }]
      @UI.identification: [{ position: 70 }]
      InstituteName,
      EducationSeqNr
}
