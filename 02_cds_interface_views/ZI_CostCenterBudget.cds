@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Cost Center Budget - Interface View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MASTER
}
define view entity ZI_CostCenterBudget
  as select from zcostctr_b
{
  key cost_center      as CostCenter,
  key budget_period    as BudgetPeriod,
      total_budget     as TotalBudget,
      consumed_budget  as ConsumedBudget,
      remaining_budget as RemainingBudget,
      currency         as Currency,
      department       as Department,
      last_changed_at  as LastChangedAt
}
