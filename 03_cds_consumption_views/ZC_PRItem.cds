@EndUserText.label: 'PR Item - Consumption View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define view entity ZC_PRItem
  provider contract transactional_query
  as projection on ZI_PRItem
{
  key ItemUuid,
  key PrId,
      ItemNo,

      @Search.defaultSearchElement: true
      MaterialNo,
      Description,

      @Semantics.quantity.unitOfMeasure: 'UnitOfMeasure'
      Quantity,
      UnitOfMeasure,

      @Semantics.amount.currencyCode: 'Currency'
      UnitPrice,
      Currency,

      @Semantics.amount.currencyCode: 'Currency'
      LineTotal,

      PreferredVendor,
      MaterialGroup,
      LocalLastChangedAt,

      /* Redirect to parent */
      _Header : redirected to parent ZC_PurchaseRequisition,
      _Vendor  : redirected to ZC_Vendor
}
