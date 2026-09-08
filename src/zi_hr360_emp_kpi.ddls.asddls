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
      // Built as sum( max( per-check flag ) * bit ) - max() is 0/1 so a
      // duplicate ISSUE row can never double a bit (A36).
      // THE ORDER BELOW MUST MATCH the checkCatalogue.json array order
      // (ui/dashboard/webapp/model/checkCatalogue.json) - bit i = 2^i.
      cast(
          max( case when Iss.CheckID = 'MAND_DOB'      then 1 else 0 end ) *          1
        + max( case when Iss.CheckID = 'INVALID_DOB'   then 1 else 0 end ) *          2
        + max( case when Iss.CheckID = 'MAND_GENDER'   then 1 else 0 end ) *          4
        + max( case when Iss.CheckID = 'STAT_NATION'   then 1 else 0 end ) *          8
        + max( case when Iss.CheckID = 'PERS_LASTNM'   then 1 else 0 end ) *         16
        + max( case when Iss.CheckID = 'PERS_FIRSTN'   then 1 else 0 end ) *         32
        + max( case when Iss.CheckID = 'PERS_MARITAL'  then 1 else 0 end ) *         64
        + max( case when Iss.CheckID = 'ORG_ORGUNIT'   then 1 else 0 end ) *        128
        + max( case when Iss.CheckID = 'ORG_POSITION'  then 1 else 0 end ) *        256
        + max( case when Iss.CheckID = 'ORG_COSTCTR'   then 1 else 0 end ) *        512
        + max( case when Iss.CheckID = 'ORG_EEGROUP'   then 1 else 0 end ) *       1024
        + max( case when Iss.CheckID = 'ORG_JOB'       then 1 else 0 end ) *       2048
        + max( case when Iss.CheckID = 'ORG_PSUBAREA'  then 1 else 0 end ) *       4096
        + max( case when Iss.CheckID = 'ORG_ADMIN'     then 1 else 0 end ) *       8192
        + max( case when Iss.CheckID = 'PAY_BASICPAY'  then 1 else 0 end ) *      16384
        + max( case when Iss.CheckID = 'PSCL_TYPE'     then 1 else 0 end ) *      32768
        + max( case when Iss.CheckID = 'PSCL_GRP'      then 1 else 0 end ) *      65536
        + max( case when Iss.CheckID = 'BANK_IBAN'     then 1 else 0 end ) *     131072
        + max( case when Iss.CheckID = 'BANK_PAYMETH'  then 1 else 0 end ) *     262144
        + max( case when Iss.CheckID = 'CONTACT_MAIL'  then 1 else 0 end ) *     524288
        + max( case when Iss.CheckID = 'COMM_MOBILE'   then 1 else 0 end ) *    1048576
        + max( case when Iss.CheckID = 'CONTACT_ADDR'  then 1 else 0 end ) *    2097152
        + max( case when Iss.CheckID = 'ADDR_STREET'   then 1 else 0 end ) *    4194304
        + max( case when Iss.CheckID = 'ADDR_CITY'     then 1 else 0 end ) *    8388608
        + max( case when Iss.CheckID = 'ADDR_POSTAL'   then 1 else 0 end ) *   16777216
        + max( case when Iss.CheckID = 'EDU_MISSING'   then 1 else 0 end ) *   33554432
        + max( case when Iss.CheckID = 'QUAL_MISSING'  then 1 else 0 end ) *   67108864
        + max( case when Iss.CheckID = 'QUAL_EXPIRED'  then 1 else 0 end ) *  134217728
        + max( case when Iss.CheckID = 'LEAVE_NOQUOTA' then 1 else 0 end ) *  268435456
        + max( case when Iss.CheckID = 'LEAVE_NEGBAL'  then 1 else 0 end ) *  536870912
        + max( case when Iss.CheckID = 'DOC_NONE'      then 1 else 0 end ) * 1073741824
      as abap.int4 )                                                           as FailureBitmask
}
group by
  Emp.EmployeeID
