@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Dimension Text'
@Metadata.ignorePropagatedAnnotations: true

// Code -> business name for the dashboard drill dimensions. Single-table,
// non-validity-dependent lookups only: company code (T001) and personnel area
// (T500P). Org units (HRP1000, plan-version / validity dependent) stay as IDs
// for now. A view over raw DB tables must be an interface view (ZI_) with a
// thin ZC_ projection on top.

define view entity ZI_HR360_DIM_TEXT
  as select from t001
{
  key cast( 'COMPANY' as abap.char( 12 ) )  as DimType,
  key cast( bukrs as abap.char( 4 ) )       as DimCode,
      cast( butxt as abap.char( 40 ) )      as DimText
}

union all
  select from t500p
{
  key cast( 'PERSAREA' as abap.char( 12 ) ) as DimType,
  key cast( persa as abap.char( 4 ) )       as DimCode,
      cast( name1 as abap.char( 40 ) )      as DimText
}
