@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Dimension Text (query)'
@Metadata.allowExtensions: true
@UI.headerInfo: { typeName: 'Dimension Text', typeNamePlural: 'Dimension Texts' }

define view entity ZC_HR360_DIM_TEXT
  as select from ZI_HR360_DIM_TEXT
{
      @UI.lineItem: [{ position: 10 }]
  key DimType,
      @UI.lineItem: [{ position: 20 }]
  key DimCode,
      @UI.lineItem: [{ position: 30 }]
      DimText
}
