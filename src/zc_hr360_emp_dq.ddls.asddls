@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Employee DQ Roster'
@Metadata.allowExtensions: true
@UI.headerInfo: {
  typeName: 'Employee',
  typeNamePlural: 'Employees'
}

// One row per employee: org assignment + how many catalogue checks the employee
// fails. The dashboard pages ALL rows of this + DataQualityIssue and does every
// aggregation client-side (docs/16 section 3). EMP_BASIC inner join EMP_KPI;
// GROUP BY every column (all functionally determined by the employee) so a
// duplicate PA0002 slice cannot produce a duplicate EmployeeID key in OData V4
// (BUILD_ISSUES_LOG A34). No real aggregate -> no A28 dump risk.
// DCL of ZI_HR360_EMP_BASIC applies.

define view entity ZC_HR360_EMP_DQ
  as select from ZI_HR360_EMP_BASIC as b
    inner join ZI_HR360_EMP_KPI as k on k.EmployeeID = b.EmployeeID
{
      @UI.lineItem:       [{ position: 10 }]
      @UI.selectionField: [{ position: 10 }]
  key b.EmployeeID         as EmployeeID,

      @UI.lineItem:       [{ position: 20 }]
      @UI.selectionField: [{ position: 20 }]
      b.CompanyCode        as CompanyCode,

      @UI.lineItem:       [{ position: 30 }]
      @UI.selectionField: [{ position: 30 }]
      b.PersonnelArea      as PersonnelArea,

      @UI.lineItem:       [{ position: 40 }]
      b.PersonnelSubarea   as PersonnelSubarea,

      @UI.lineItem:       [{ position: 50 }]
      @UI.selectionField: [{ position: 40 }]
      b.EmployeeGroup      as EmployeeGroup,

      @UI.lineItem:       [{ position: 60 }]
      b.EmployeeSubgroup   as EmployeeSubgroup,

      @UI.lineItem:       [{ position: 70 }]
      @UI.selectionField: [{ position: 50 }]
      b.OrgUnit            as OrgUnit,

      @UI.lineItem:       [{ position: 80 }]
      b.CostCenter         as CostCenter,

      @UI.lineItem:       [{ position: 90 }]
      k.TotalIssueCount    as FailedCheckCount
}
group by
  b.EmployeeID,
  b.CompanyCode,
  b.PersonnelArea,
  b.PersonnelSubarea,
  b.EmployeeGroup,
  b.EmployeeSubgroup,
  b.OrgUnit,
  b.CostCenter,
  k.TotalIssueCount
