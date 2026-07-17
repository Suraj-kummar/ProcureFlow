@EndUserText.label: 'Vendor - Consumption View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@ObjectModel.resultSet.sizeCategory: #XS

define view entity ZC_Vendor
  provider contract transactional_query
  as projection on ZI_Vendor
{
  key VendorId,
      VendorName,
      MaterialGroup,
      LastUsedDate,
      @Semantics.amount.currencyCode: 'Currency'
      UnitPrice,
      Currency,
      Country,
      ContactEmail,
      IsPreferred
}
