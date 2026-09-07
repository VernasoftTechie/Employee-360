@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Employee Bank'
@Metadata.ignorePropagatedAnnotations: true

// One row per employee. max() + GROUP BY guards against more than one current
// PA0009 subtype-0 (main bank) record (BUILD_ISSUES_LOG A34). For the
// "bank details maintained" check this returns a populated value if any
// current main-bank record has it.

define view entity ZI_HR360_EMP_BANK
  as select from pa0009
{
  key pernr           as EmployeeID,
      max( bankl )     as BankKey,
      max( bankn )     as BankAccount,
      max( bkont )     as BankControlKey,
      max( iban )      as IBAN,
      max( zlsch )     as PaymentMethod
}
where subty = '0'
  and begda <= $session.system_date
  and endda >= $session.system_date
group by pernr
