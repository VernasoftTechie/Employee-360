@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Timeline (proj)'
@Metadata.allowExtensions: true
define view entity ZC_HR360_TIMELINE
  as projection on ZI_HR360_TIMELINE
{
  key EmployeeID,
  key EventDate,
  key EventCategory,
  key EventKey,
      Title
}
