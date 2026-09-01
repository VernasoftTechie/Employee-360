@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Employee Contact'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_HR360_EMP_CONTACT
  as select from pa0002 as P
    left outer join pa0105 as Email  on  Email.pernr = P.pernr and Email.subty = '0010'
                                     and Email.begda <= $session.system_date and Email.endda >= $session.system_date
    left outer join pa0105 as Mobile on  Mobile.pernr = P.pernr and Mobile.subty = '0020'
                                     and Mobile.begda <= $session.system_date and Mobile.endda >= $session.system_date
    left outer join pa0006 as Addr   on  Addr.pernr = P.pernr and Addr.subty = '1'
                                     and Addr.begda <= $session.system_date and Addr.endda >= $session.system_date
{
  key P.pernr           as EmployeeID,
      Email.usrid_long  as EmailAddress,
      Mobile.usrid_long as MobileNumber,
      Addr.stras        as Street,
      Addr.ort01        as City,
      Addr.pstlz        as PostalCode,
      Addr.land1        as Country
}
where P.begda <= $session.system_date
  and P.endda >= $session.system_date
