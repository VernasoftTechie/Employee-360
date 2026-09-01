@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Personal (proj)'
@Metadata.allowExtensions: true
define view entity ZC_HR360_PERSONAL as projection on ZI_HR360_PERSONAL
{
  key EmployeeID, FirstName, LastName, SecondName, FormattedName, DateOfBirth,
      BirthPlace, Gender, Nationality, MaritalStatus, Street, City, PostalCode,
      Country, EmailAddress, MobileNumber, BankKey, BankAccount, IBAN, BankControlKey
}
