@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Leave (query)'
@Metadata.allowExtensions: true
@UI.headerInfo: { typeName: 'Leave Quota', typeNamePlural: 'Leave and Quotas' }
define view entity ZC_HR360_LEAVE
  as select from ZI_HR360_LEAVE
{
      @UI.lineItem:       [{ position: 10 }]
      @UI.identification: [{ position: 10 }]
  key EmployeeID,
      @UI.lineItem:       [{ position: 20 }]
      @UI.identification: [{ position: 20 }]
  key QuotaType,
      @UI.lineItem:       [{ position: 30 }]
      @UI.identification: [{ position: 30 }]
  key DeductionFrom,
      @UI.lineItem:       [{ position: 40 }]
      @UI.identification: [{ position: 40 }]
      DeductionTo,
      @UI.lineItem:       [{ position: 50 }]
      @UI.identification: [{ position: 50 }]
      Entitlement,
      @UI.lineItem:       [{ position: 60 }]
      @UI.identification: [{ position: 60 }]
      Deducted,
      @UI.lineItem:       [{ position: 70 }]
      @UI.identification: [{ position: 70 }]
      Remaining
}
