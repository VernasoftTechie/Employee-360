@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Documents (proj)'
@Metadata.allowExtensions: true
define view entity ZC_HR360_DOCUMENT as projection on ZI_HR360_DOCUMENT
{
  key EmployeeID, key ArchivDocID,
      ArchiveID, DocumentType, ArchiveDate, Title
}
