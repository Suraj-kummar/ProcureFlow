@EndUserText.label : 'Purchase Requisition Audit Log'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zpur_auditlog {
  key client      : abap.clnt not null;
  key prid        : sysuuid_x16 not null;
  key log_id      : sysuuid_x16 not null;
  log_timestamp   : abap.utclong;
  changed_by      : abap.char(12);
  old_status      : abap.char(20);
  new_status      : abap.char(20);
  comments        : abap.char(500);
  action_taken    : abap.char(30);   "Submit/Approve/Reject/Delegate/Withdraw
}
