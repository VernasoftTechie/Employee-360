@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Leave (proj)'
@Metadata.allowExtensions: true
define view entity ZC_HR360_LEAVE as projection on ZI_HR360_LEAVE
{
  key EmployeeID, key QuotaType, key DeductionFrom,
      DeductionTo, Entitlement, Deducted, Remaining
}
