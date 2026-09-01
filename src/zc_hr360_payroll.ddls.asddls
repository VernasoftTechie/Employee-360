@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Pay History (query)'
@Metadata.allowExtensions: true
@UI.headerInfo: { typeName: 'Pay Record', typeNamePlural: 'Pay History' }
define view entity ZC_HR360_PAYROLL
  as select from ZI_HR360_PAYROLL
{
      @UI.lineItem: [{ position: 10 }]
  key EmployeeID,
      @UI.lineItem: [{ position: 20 }]
  key ValidFrom,
      @UI.lineItem: [{ position: 30 }]
      ValidTo,
      @UI.lineItem: [{ position: 40 }]
      PayScaleType,
      @UI.lineItem: [{ position: 50 }]
      PayScaleArea,
      @UI.lineItem: [{ position: 60 }]
      PayScaleGroup,
      @UI.lineItem: [{ position: 70 }]
      PayScaleLevel,
      @UI.lineItem: [{ position: 80 }]
      AnnualSalary,
      @UI.lineItem: [{ position: 90 }]
      Currency,
      CapacityUtilLevel,
      WeeklyHours
}
