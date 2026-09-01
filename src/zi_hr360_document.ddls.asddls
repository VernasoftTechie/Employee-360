@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Personnel Documents'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_HR360_DOCUMENT
  as select from toa01 as L
    left outer join toaat as A on A.arc_doc_id = L.arc_doc_id
{
  key cast( substring( L.object_id, 1, 8 ) as abap.numc( 8 ) ) as EmployeeID,
  key L.arc_doc_id as ArchivDocID,
      L.archiv_id  as ArchiveID,
      L.ar_object  as DocumentType,
      L.ar_date    as ArchiveDate,
      A.descr      as Title
}
where L.sap_object = 'PREL'
