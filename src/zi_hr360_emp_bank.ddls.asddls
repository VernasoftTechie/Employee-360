@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Employee Bank Details'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC

define view entity ZI_HR360_EMP_BANK
  as select from pa0009
{
  key pernr    as EmployeeID,
      bankl    as BankKey,
      bankn    as BankAccount,
      bkont    as BankControlKey,
      iban     as IBAN
}
where subty = '0'
  and begda <= $session.system_date
  and endda >= $session.system_date
