@EndUserText.label: 'Purchase Requisition - Consumption View'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true

@Search.searchable: true
@ObjectModel.query.implementedBy: 'ABAP:ZCL_PURREQ_QUERY'

define root view entity ZC_PurchaseRequisition
  provider contract transactional_query
  as projection on ZI_PurchaseRequisition
{
      @Search.defaultSearchElement: true
  key PrId,

      @Search.defaultSearchElement: true
      PrIdExternal,

      @Search.defaultSearchElement: true
      Requester,
      Department,
      CostCenter,
      CreationDate,

      @Semantics.amount.currencyCode: 'Currency'
      TotalValue,
      Currency,

      Status,
      Approver,
      Priority,
      ApprovalLevel,
      FinanceApprovedBy,
      RejectionComment,
      SubmittedAt,
      ApprovedAt,
      LocalLastChangedAt,
      LastChangedBy,

      /* Expose compositions */
      _Items    : redirected to composition child ZC_PRItem,
      _AuditLog : redirected to composition child ZC_PRAuditLog,
      _Budget
}

-- @Search.searchable: true added for Fiori smart search support
