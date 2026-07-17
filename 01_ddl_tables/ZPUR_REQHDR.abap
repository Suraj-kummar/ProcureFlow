@EndUserText.label : 'Purchase Requisition Header'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zpur_reqhdr {
  key client            : abap.clnt not null;
  key prid              : sysuuid_x16 not null;
  prid_external         : abap.char(20);
  requester             : abap.char(12);
  department            : abap.char(10);
  cost_center           : abap.char(10);
  creation_date         : abap.dats;
  total_value           : abap.curr(15,2);
  currency              : abap.cuky;
  status                : abap.char(20);
  approver              : abap.char(12);
  priority              : abap.char(10);
  approval_level        : abap.int1;
  finance_approved_by   : abap.char(12);
  rejection_comment     : abap.char(500);
  submitted_at          : abap.dats;
  approved_at           : abap.dats;
  local_last_changed_at : abap.utclong;
  last_changed_by       : abap.char(12);
}
-- refactored: added MANDT client field documentation
