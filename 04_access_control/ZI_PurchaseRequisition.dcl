@EndUserText.label: 'Access Control for PR Root Interface View'
@MappingRole: true

/*
  Three-way OR:
  1. Requester can see their own PRs
  2. Approver can see PRs assigned to them
  3. Finance Approver can see PRs with ApprovalLevel = 2
  The behavior implementation enforces further write restrictions.
*/
define role ZI_PurchaseRequisition {

  grant select on ZI_PurchaseRequisition
  where (
    Requester = aspect user                   -- Requesters see own PRs
  ) or (
    Approver  = aspect user                   -- Approvers see their queue
  ) or (
    ApprovalLevel = '2'                        -- Finance sees high-value PRs
    and aspect user has (ZPURAPPR_OBJ, ZPURREQ_FINANCE, '')
  );

}
