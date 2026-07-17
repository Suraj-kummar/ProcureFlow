@EndUserText.label: 'Cost Center Budget - Consumption View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define view entity ZC_CostCenterBudget
  provider contract transactional_query
  as projection on ZI_CostCenterBudget
{
  key CostCenter,
  key BudgetPeriod,
      @Semantics.amount.currencyCode: 'Currency'
      TotalBudget,
      @Semantics.amount.currencyCode: 'Currency'
      ConsumedBudget,
      @Semantics.amount.currencyCode: 'Currency'
      RemainingBudget,
      Currency,
      Department,
      LastChangedAt
}
