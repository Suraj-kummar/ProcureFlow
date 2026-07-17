@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PR Header - Interface View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #M,
  dataClass: #MIXED
}
define root view entity ZI_PurchaseRequisition
  as select from zpur_reqhdr
  composition [0..*] of ZI_PRItem         as _Items
  composition [0..*] of ZI_PRAuditLog     as _AuditLog
  association [0..1] to ZI_CostCenterBudget as _Budget
    on $projection.CostCenter = _Budget.CostCenter
{
  key prid                   as PrId,
      prid_external          as PrIdExternal,
      requester              as Requester,
      department             as Department,
      cost_center            as CostCenter,
      creation_date          as CreationDate,
      total_value            as TotalValue,
      currency               as Currency,
      status                 as Status,
      approver               as Approver,
      priority               as Priority,
      approval_level         as ApprovalLevel,
      finance_approved_by    as FinanceApprovedBy,
      rejection_comment      as RejectionComment,
      submitted_at           as SubmittedAt,
      approved_at            as ApprovedAt,
      local_last_changed_at  as LocalLastChangedAt,
      last_changed_by        as LastChangedBy,

      /* Associations */
      _Items,
      _AuditLog,
      _Budget
}
-- refactored: enhanced @ObjectModel annotations for semantic keys
