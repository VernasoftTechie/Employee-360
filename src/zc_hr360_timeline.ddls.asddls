@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Timeline (projection)'
@Metadata.allowExtensions: true

define view entity ZC_HR360_TIMELINE
  as projection on ZI_HR360_TIMELINE
{
  key EmployeeID,
  key EventDate,
  key EventCategory,
  key EventSeqNr,
      EventType,
      Title,
      Detail,
      SortDate
}
