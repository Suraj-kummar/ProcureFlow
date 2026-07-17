@EndUserText.label: 'Access Control for Purchase Requisition'
@MappingRole: true

/*
  Authorization strategy:
  - Requesters: see only their own PRs (Requester = current user)
  - Approvers: see PRs routed to them (Approver = current user)
  - Finance Approvers: see high-value PRs requiring finance sign-off (ApprovalLevel = 2)
  - Users with ZPROCUREFLOW_ADMIN privilege see all PRs

  PFCG roles (see 10_authorization/PFCG_ROLES.md):
    ZPROCUREFLOW_REQUESTER   → ZPURREQ_OBJ, Activity 01/02/06
    ZPROCUREFLOW_APPROVER    → ZPURAPPR_OBJ, Activity 01/03
    ZPROCUREFLOW_FINANCE     → ZPURAPPR_OBJ, Activity 01/03, field FinanceOnly = 'X'
    ZPROCUREFLOW_ADMIN       → Both objects with * activity
*/
define role ZC_PurchaseRequisition {

  grant select on ZC_PurchaseRequisition
    where inheriting conditions from entity ZI_PurchaseRequisition;

}
