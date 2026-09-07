@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Employee DQ KPIs'
@Metadata.ignorePropagatedAnnotations: true

// Per-employee data-quality counts + derived status. Flat (EMP_BASIC left join
// ISSUE, grouped by employee). count(distinct) is required (BUILD_ISSUES_LOG A4).

define view entity ZI_HR360_EMP_KPI
  as select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_ISSUE  as Iss on Iss.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID as EmployeeID,

      cast( count( distinct Iss.CheckID ) as abap.int4 )                       as TotalIssueCount,
      cast( sum( case when Iss.Severity = 'C' then 1 else 0 end ) as abap.int4 ) as CriticalIssueCount,
      cast( sum( case when Iss.Severity = 'W' then 1 else 0 end ) as abap.int4 ) as WarningIssueCount,

      case
        when sum( case when Iss.Severity = 'C' then 1 else 0 end ) > 0 then cast( 'CRITICAL' as abap.char( 8 ) )
        when count( distinct Iss.CheckID ) > 0                        then cast( 'WARNING'  as abap.char( 8 ) )
        else cast( 'OK' as abap.char( 8 ) )
      end                                                                       as QualityStatus,

      case
        when sum( case when Iss.Severity = 'C' then 1 else 0 end ) > 0 then cast( 1 as abap.int4 )
        when count( distinct Iss.CheckID ) > 0                        then cast( 2 as abap.int4 )
        else cast( 3 as abap.int4 )
      end                                                                       as QualityStatusCriticality,

      // catalogue size (CAT_2026_09 increment B = 31 checks) - bump with ZI_HR360_ISSUE branch count
      cast( division( ( 31 - count( distinct Iss.CheckID ) ) * 100, 31, 2 ) as abap.dec( 6, 2 ) ) as CompletenessPercent,

      // Bitmask of failed checks - bit i = check i (2^i). The dashboard reads
      // ONLY this (via ZC_HR360_EMP_DQ) and decodes it client-side, instead of
      // paging the whole DataQualityIssue union (BUILD_ISSUES_LOG A35).
      // string_agg is not an aggregate on this release, so a bitmask it is.
      // THE ORDER BELOW MUST MATCH the checkCatalogue.json array order
      // (ui/dashboard/webapp/model/checkCatalogue.json) - bit i = 2^i.
      cast( sum( case Iss.CheckID
        when 'MAND_DOB'      then          1
        when 'INVALID_DOB'   then          2
        when 'MAND_GENDER'   then          4
        when 'STAT_NATION'   then          8
        when 'PERS_LASTNM'   then         16
        when 'PERS_FIRSTN'   then         32
        when 'PERS_MARITAL'  then         64
        when 'ORG_ORGUNIT'   then        128
        when 'ORG_POSITION'  then        256
        when 'ORG_COSTCTR'   then        512
        when 'ORG_EEGROUP'   then       1024
        when 'ORG_JOB'       then       2048
        when 'ORG_PSUBAREA'  then       4096
        when 'ORG_ADMIN'     then       8192
        when 'PAY_BASICPAY'  then      16384
        when 'PSCL_TYPE'     then      32768
        when 'PSCL_GRP'      then      65536
        when 'BANK_IBAN'     then     131072
        when 'BANK_PAYMETH'  then     262144
        when 'CONTACT_MAIL'  then     524288
        when 'COMM_MOBILE'   then    1048576
        when 'CONTACT_ADDR'  then    2097152
        when 'ADDR_STREET'   then    4194304
        when 'ADDR_CITY'     then    8388608
        when 'ADDR_POSTAL'   then   16777216
        when 'EDU_MISSING'   then   33554432
        when 'QUAL_MISSING'  then   67108864
        when 'QUAL_EXPIRED'  then  134217728
        when 'LEAVE_NOQUOTA' then  268435456
        when 'LEAVE_NEGBAL'  then  536870912
        when 'DOC_NONE'      then 1073741824
        else 0
      end ) as abap.int4 )                                                   as FailureBitmask
}
group by
  Emp.EmployeeID
