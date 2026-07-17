@EndUserText.label: 'PR Audit Log - Consumption View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define view entity ZC_PRAuditLog
  provider contract transactional_query
  as projection on ZI_PRAuditLog
{
  key LogId,
  key PrId,
      LogTimestamp,
      ChangedBy,
      OldStatus,
      NewStatus,
      Comments,
      ActionTaken,

      _Header : redirected to parent ZC_PurchaseRequisition
}
