@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Personal Details'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #COMPOSITE

define view entity ZI_HR360_PERSONAL
  as select from pa0002 as P

    left outer join pa0006 as Addr    on  Addr.pernr = P.pernr
                                      and Addr.subty = '1'
                                      and Addr.begda <= $session.system_date
                                      and Addr.endda >= $session.system_date

    left outer join pa0105 as Mail    on  Mail.pernr = P.pernr
                                      and Mail.subty = '0010'
                                      and Mail.begda <= $session.system_date
                                      and Mail.endda >= $session.system_date

    left outer join pa0105 as Cell    on  Cell.pernr = P.pernr
                                      and Cell.subty = '0020'
                                      and Cell.begda <= $session.system_date
                                      and Cell.endda >= $session.system_date

    left outer join pa0009 as Bank    on  Bank.pernr = P.pernr
                                      and Bank.subty = '0'
                                      and Bank.begda <= $session.system_date
                                      and Bank.endda >= $session.system_date

    left outer join t502t  as MarStat on  MarStat.sprsl = $session.system_language
                                      and MarStat.famst = P.famst

  association to parent ZI_HR360_EMPLOYEE as _Employee
    on $projection.EmployeeID = _Employee.EmployeeID

  where P.begda <= $session.system_date
    and P.endda >= $session.system_date

{
  key P.pernr                                as EmployeeID,
      P.vorna                                as FirstName,
      P.nachn                                as LastName,
      P.name2                                as SecondName,
      concat(concat(P.vorna, ' '), P.nachn)  as FormattedName,
      P.gbdat                                as DateOfBirth,
      P.gbort                                as BirthPlace,
      P.gesch                                as Gender,
      P.natio                                as Nationality,
      P.famst                                as MaritalStatus,
      MarStat.ftext                          as MaritalStatusName,
      Addr.stras                             as Street,
      Addr.ort01                             as City,
      Addr.pstlz                             as PostalCode,
      Addr.state                             as Region,
      Addr.land1                             as Country,
      Mail.usrid_long                        as EmailAddress,
      Cell.usrid_long                        as MobileNumber,
      Bank.bankl                             as BankKey,
      Bank.bankn                             as BankAccount,
      Bank.iban                              as IBAN,
      Bank.bkont                             as BankControlKey,

      _Employee
}
