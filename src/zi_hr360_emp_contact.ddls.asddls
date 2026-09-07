@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Employee Contact'
@Metadata.ignorePropagatedAnnotations: true

// One row per employee. max() + GROUP BY collapses the case where an employee
// has more than one current PA0006 (address) or PA0105 (comm.) record - which
// would otherwise multiply rows and break OData V4 key uniqueness downstream
// (BUILD_ISSUES_LOG A34). max() of a set of values returns the populated one
// if any current record has it, which is the right semantic for the
// "is this field maintained" checks.

define view entity ZI_HR360_EMP_CONTACT
  as select from pa0002 as P
    left outer join pa0105 as Email  on  Email.pernr = P.pernr and Email.subty = '0010'
                                     and Email.begda <= $session.system_date and Email.endda >= $session.system_date
    left outer join pa0105 as Mobile on  Mobile.pernr = P.pernr and Mobile.subty = '0020'
                                     and Mobile.begda <= $session.system_date and Mobile.endda >= $session.system_date
    left outer join pa0006 as Addr   on  Addr.pernr = P.pernr and Addr.subty = '1'
                                     and Addr.begda <= $session.system_date and Addr.endda >= $session.system_date
{
  key P.pernr                as EmployeeID,
      max( Email.usrid_long )  as EmailAddress,
      max( Mobile.usrid_long ) as MobileNumber,
      max( Addr.stras )        as Street,
      max( Addr.ort01 )        as City,
      max( Addr.pstlz )        as PostalCode,
      max( Addr.land1 )        as Country
}
where P.begda <= $session.system_date
  and P.endda >= $session.system_date
group by P.pernr
