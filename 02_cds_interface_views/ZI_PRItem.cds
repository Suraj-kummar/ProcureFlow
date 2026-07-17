@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PR Item - Interface View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #M,
  dataClass: #MIXED
}
define view entity ZI_PRItem
  as select from zpur_reqitm
  association to parent ZI_PurchaseRequisition as _Header
    on $projection.PrId = _Header.PrId
  association [0..1] to ZI_Vendor as _Vendor
    on $projection.PreferredVendor = _Vendor.VendorId
{
  key item_uuid             as ItemUuid,
  key prid                  as PrId,
      item_no               as ItemNo,
      material_no           as MaterialNo,
      description           as Description,
      quantity              as Quantity,
      unit_of_measure       as UnitOfMeasure,
      unit_price            as UnitPrice,
      currency              as Currency,
      line_total            as LineTotal,
      preferred_vendor      as PreferredVendor,
      material_group        as MaterialGroup,
      local_last_changed_at as LocalLastChangedAt,

      /* Associations */
      _Header,
      _Vendor
}
