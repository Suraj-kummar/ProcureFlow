# Authorization Objects — ProcureFlow

Create the following authorization objects in ADT (transaction SU21 on S/4HANA on-premise,
or via the IAM "Authorization Object" app on BTP ABAP Environment).

---

## ZPURREQ_OBJ — Purchase Requisition Requester Object

| Field        | Description              | Values                    |
|--------------|--------------------------|---------------------------|
| ACTVT        | Activity                 | 01 (Create), 02 (Change), 06 (Delete) |
| ZZREQUESTER  | Requester user field     | * (own user checked in code) |
| ZZCOSTCTR    | Cost Center              | Restrict by cost center   |

Used in: `ZI_PurchaseRequisition.dcl`, `lhc_purchaserequisition→get_instance_authorizations`

---

## ZPURAPPR_OBJ — Purchase Requisition Approver Object

| Field           | Description              | Values                     |
|-----------------|--------------------------|----------------------------|
| ACTVT           | Activity                 | 01 (Read), 03 (Approve/Reject) |
| ZZAPPROVER      | Approver user field      | * (own user checked in code) |
| ZZPURLEVEL      | Approval Level           | 1 (Manager), 2 (Finance), * (All) |

Used in: `lhc_purchaserequisition→check_approver_role`,
         `lhc_purchaserequisition→get_instance_features`

---

## Notes for BTP ABAP Environment

> **BTP Trial Constraint**: SU21 is not available on BTP ABAP Environment.
> Create authorization objects using ADT:
> Right-click package → New → Authorization Object
> Alternatively, use IAM app: `Maintain Authorization Objects`

---

## Criticality Fields

Add the following computed field to ZI_PurchaseRequisition for Fiori criticality display:

```abap
case status
  when 'Approved'        then 3   -- #POSITIVE (green)
  when 'Rejected'        then 1   -- #NEGATIVE (red)
  when 'PendingApproval' then 2   -- #CRITICAL (yellow/orange)
  when 'Submitted'       then 2   -- #NEW
  else                        0   -- #NEUTRAL (grey)
end as StatusCriticality,
```

Add this CASE expression as an extra field in `ZI_PurchaseRequisition` CDS view
and reference it in `@UI.dataPoint.criticality` in the metadata extension.
