@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Employee Contact and Address'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_HR360_EMP_CONTACT
  as select from pa0002 as PersonalData

    left outer join pa0105 as Email   on  Email.pernr = PersonalData.pernr
                                      and Email.subty = '0010'
                                      and Email.begda <= $session.system_date
                                      and Email.endda >= $session.system_date

    left outer join pa0105 as Mobile  on  Mobile.pernr = PersonalData.pernr
                                      and Mobile.subty = '0020'
                                      and Mobile.begda <= $session.system_date
                                      and Mobile.endda >= $session.system_date

    left outer join pa0006 as Address on  Address.pernr = PersonalData.pernr
                                      and Address.subty = '1'
                                      and Address.begda <= $session.system_date
                                      and Address.endda >= $session.system_date
{
  key PersonalData.pernr    as EmployeeID,
      Email.usrid_long      as EmailAddress,
      Mobile.usrid_long     as MobileNumber,
      Address.stras         as Street,
      Address.ort01         as City,
      Address.pstlz         as PostalCode,
      Address.state         as Region,
      Address.land1         as Country
}
where PersonalData.begda <= $session.system_date
  and PersonalData.endda >= $session.system_date
