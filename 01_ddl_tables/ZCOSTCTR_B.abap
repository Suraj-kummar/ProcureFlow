@EndUserText.label : 'Cost Center Budget'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #ALLOWED
define table zcostctr_b {
  key client         : abap.clnt not null;
  key cost_center    : abap.char(10) not null;
  key budget_period  : abap.char(7) not null;   "YYYY/MM or YYYY for annual
  total_budget       : abap.curr(15,2);
  consumed_budget    : abap.curr(15,2);
  remaining_budget   : abap.curr(15,2);
  currency           : abap.cuky;
  department         : abap.char(10);
  last_changed_at    : abap.utclong;
}
