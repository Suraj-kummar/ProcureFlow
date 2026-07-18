@EndUserText.label : 'Purchase Requisition Item'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zpur_reqitm {
  key client       : abap.clnt not null;
  key prid         : sysuuid_x16 not null;
  key item_uuid    : sysuuid_x16 not null;
  item_no          : abap.numc(5);
  material_no      : abap.char(18);
  description      : abap.char(100);
  quantity         : abap.quan(13,3);
  unit_of_measure  : abap.unit(3);
  unit_price       : abap.curr(13,2);
  currency         : abap.cuky;
  line_total       : abap.curr(15,2);
  preferred_vendor : abap.char(10);
  material_group   : abap.char(9);
  local_last_changed_at : abap.utclong;
}

  -- Added currency key reference CURRENCY -> WAERS for amount fields
