@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Personnel Documents'
@Metadata.ignorePropagatedAnnotations: true

// ArchiveLink link entries for HR object 'PREL'. Metadata only. No TOAAT join
// (avoiding unverified field names - BUILD_ISSUES_LOG.md A10). EmployeeID =
// leading 8 chars of OBJECT_ID (default HR ArchiveLink key layout).

define view entity ZI_HR360_DOCUMENT
  as select from toa01 as L
{
  key cast( substring( L.object_id, 1, 8 ) as abap.numc( 8 ) ) as EmployeeID,
  key L.arc_doc_id as ArchivDocID,
      L.archiv_id  as ArchiveID,
      L.ar_object  as DocumentType,
      L.ar_date    as ArchiveDate
}
where L.sap_object = 'PREL'
