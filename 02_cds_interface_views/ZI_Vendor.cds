@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vendor Master - Interface View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MASTER
}
define view entity ZI_Vendor
  as select from zvendor_m
{
  key vendor_id      as VendorId,
      vendor_name    as VendorName,
      material_group as MaterialGroup,
      last_used_date as LastUsedDate,
      unit_price     as UnitPrice,
      currency       as Currency,
      country        as Country,
      contact_email  as ContactEmail,
      is_preferred   as IsPreferred
}
