@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Timeline (query)'
@Metadata.allowExtensions: true
@UI.headerInfo: { typeName: 'Event', typeNamePlural: 'Timeline' }
@UI.presentationVariant: [{ sortOrder: [{ by: 'EventDate', direction: #DESC }] }]
define view entity ZC_HR360_TIMELINE
  as select from ZI_HR360_TIMELINE
{
      @UI.lineItem:       [{ position: 10 }]
      @UI.identification: [{ position: 10 }]
  key EmployeeID,
      @UI.lineItem:       [{ position: 20 }]
      @UI.identification: [{ position: 20 }]
  key EventDate,
      @UI.lineItem:       [{ position: 30 }]
      @UI.identification: [{ position: 30 }]
  key EventCategory,
  key EventKey,
      @UI.lineItem:       [{ position: 40 }]
      @UI.identification: [{ position: 40 }]
      Title
}
