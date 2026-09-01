@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Documents (query)'
@Metadata.allowExtensions: true
@UI.headerInfo: { typeName: 'Document', typeNamePlural: 'Documents' }
define view entity ZC_HR360_DOCUMENT
  as select from ZI_HR360_DOCUMENT
{
      @UI.lineItem: [{ position: 10 }]
  key EmployeeID,
      @UI.lineItem: [{ position: 20 }]
  key ArchivDocID,
      @UI.lineItem: [{ position: 30 }]
      DocumentTypeCode,
      @UI.lineItem: [{ position: 40 }]
      ArchiveDate,
      @UI.lineItem: [{ position: 50 }]
      ArchiveID
}
