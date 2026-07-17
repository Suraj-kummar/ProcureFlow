@EndUserText.label : 'Vendor Master'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #ALLOWED
define table zvendor_m {
  key client         : abap.clnt not null;
  key vendor_id      : abap.char(10) not null;
  vendor_name        : abap.char(80);
  material_group     : abap.char(9);
  last_used_date     : abap.dats;
  unit_price         : abap.curr(13,2);
  currency           : abap.cuky;
  country            : abap.char(3);
  contact_email      : abap.char(60);
  is_preferred       : abap_boolean;
}
