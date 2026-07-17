@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PR Audit Log - Interface View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #M,
  dataClass: #TRANSACTIONAL
}
define view entity ZI_PRAuditLog
  as select from zpur_auditlog
  association to parent ZI_PurchaseRequisition as _Header
    on $projection.PrId = _Header.PrId
{
  key log_id        as LogId,
  key prid          as PrId,
      log_timestamp as LogTimestamp,
      changed_by    as ChangedBy,
      old_status    as OldStatus,
      new_status    as NewStatus,
      comments      as Comments,
      action_taken  as ActionTaken,

      /* Association */
      _Header
}
