# PFCG Role Definitions — ProcureFlow

Create these roles in PFCG (S/4HANA on-premise) or the BTP IAM app.

---

## Role 1: ZPROCUREFLOW_REQUESTER

**Purpose**: Employees who create and submit Purchase Requisitions.

| Setting           | Value                                          |
|-------------------|------------------------------------------------|
| Role Name         | ZPROCUREFLOW_REQUESTER                         |
| Description       | ProcureFlow - PR Requester                     |
| Menu              | Add OData service ZPROCUREFLOW_UI_O4 → PR List |

### Authorization Objects

| Object         | Field        | Value     | Description                |
|----------------|--------------|-----------|----------------------------|
| ZPURREQ_OBJ    | ACTVT        | 01 02 06  | Create, Change, Delete      |
| ZPURREQ_OBJ    | ZZREQUESTER  | *         | Own user checked in ABAP   |
| S_SERVICE      | SRV_NAME     | ZPROCUREFLOW_UI_O4 | OData service access |
| S_SERVICE      | SRV_TYPE     | HTTP      |                            |

### Business Restrictions (enforced in code, not PFCG)
- Can only edit PRs where `Requester = current user`
- Can only Submit/Withdraw own PRs
- Cannot Approve or Reject

---

## Role 2: ZPROCUREFLOW_APPROVER

**Purpose**: Managers who review and approve/reject mid-value PRs (₹50k–₹500k).

| Setting           | Value                                            |
|-------------------|--------------------------------------------------|
| Role Name         | ZPROCUREFLOW_APPROVER                            |
| Description       | ProcureFlow - PR Approver (Manager Level)        |

### Authorization Objects

| Object         | Field        | Value   | Description                  |
|----------------|--------------|---------|------------------------------|
| ZPURAPPR_OBJ   | ACTVT        | 01 03   | Read, Approve/Reject          |
| ZPURAPPR_OBJ   | ZZPURLEVEL   | 1       | Manager level only            |
| S_SERVICE      | SRV_NAME     | ZPROCUREFLOW_UI_O4 |                    |
| S_SERVICE      | SRV_TYPE     | HTTP    |                              |

### Business Restrictions
- Can only see PRs where `Approver = current user`
- Can Approve, Reject, Delegate
- Cannot create or edit PR content

---

## Role 3: ZPROCUREFLOW_FINANCE

**Purpose**: Finance team who give final sign-off on high-value PRs (> ₹500k).

| Setting           | Value                                            |
|-------------------|--------------------------------------------------|
| Role Name         | ZPROCUREFLOW_FINANCE                             |
| Description       | ProcureFlow - Finance Approver (High Value PRs)  |

### Authorization Objects

| Object         | Field        | Value   | Description                  |
|----------------|--------------|---------|------------------------------|
| ZPURAPPR_OBJ   | ACTVT        | 01 03   | Read, Approve/Reject          |
| ZPURAPPR_OBJ   | ZZPURLEVEL   | 2       | Finance level only            |
| ZPURREQ_FINANCE| ACTVT        | 01      | Finance flag authorization    |
| S_SERVICE      | SRV_NAME     | ZPROCUREFLOW_UI_O4 |                    |
| S_SERVICE      | SRV_TYPE     | HTTP    |                              |

### Business Restrictions
- Can only see PRs with `ApprovalLevel = 2`
- Same approve/reject/delegate privileges as APPROVER role for their queue

---

## Role 4: ZPROCUREFLOW_ADMIN (optional)

**Purpose**: System admin / developers — full read/write access.

| Object       | Field  | Value |
|--------------|--------|-------|
| ZPURREQ_OBJ  | ACTVT  | *     |
| ZPURAPPR_OBJ | ACTVT  | *     |

---

## BTP ABAP Environment Notes

> On BTP ABAP Environment trial:
> - Use **Business Role** (not PFCG role) in the BTP Cockpit
> - Create a Business Role template: `ZPROCUREFLOW_REQUESTER`
> - Assign to Business Users via IAM → User Management
> - Map to the authorization objects defined above
> - The `AUTHORITY-CHECK` ABAP statement works identically on BTP

## ZPROCUREFLOW_ADMIN role: full access including delete and budget override
