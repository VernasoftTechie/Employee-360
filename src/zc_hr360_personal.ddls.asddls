@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Personal (projection)'
@Metadata.allowExtensions: true

define view entity ZC_HR360_PERSONAL
  as projection on ZI_HR360_PERSONAL
{
  key EmployeeID,
      FirstName,
      LastName,
      SecondName,
      FormattedName,
      DateOfBirth,
      BirthPlace,
      Gender,
      Nationality,
      MaritalStatus,
      MaritalStatusName,
      Street,
      City,
      PostalCode,
      Region,
      Country,
      EmailAddress,
      MobileNumber,
      BankKey,
      BankAccount,
      IBAN,
      BankControlKey
}
