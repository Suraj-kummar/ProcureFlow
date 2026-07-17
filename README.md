# ProcureFlow — SAP Purchase Requisition Approval System

**Tech Stack**: ABAP RAP (Managed Scenario) · CDS Views · OData V4 · Fiori Elements  
**Target**: S/4HANA 2023+ or SAP BTP ABAP Environment (trial compatible)

---

## Architecture Overview

```
Fiori Launchpad
    │
    │  OData V4 (ZPROCUREFLOW_UI_O4)
    ▼
Service Definition (ZPROCUREFLOW_SRV)
    │
    ├── ZC_PurchaseRequisition  ← Projection View (root, draft-enabled)
    ├── ZC_PRItem               ← Projection View (child: items)
    ├── ZC_PRAuditLog           ← Projection View (child: audit trail)
    ├── ZC_Vendor               ← Lookup / Value Help
    └── ZC_CostCenterBudget     ← Lookup / Budget Display
         │
         ├── ZI_PurchaseRequisition  ← Interface View (base, no auth)
         ├── ZI_PRItem               ← Interface Child View
         ├── ZI_PRAuditLog           ← Interface Child View
         ├── ZI_Vendor               ← Interface Lookup View
         └── ZI_CostCenterBudget     ← Interface Lookup View
              │
              ├── ZPUR_REQHDR    ← DB Table: PR Header
              ├── ZPUR_REQITM    ← DB Table: PR Items
              ├── ZPUR_AUDITLOG  ← DB Table: Audit Log
              ├── ZVENDOR_M      ← DB Table: Vendor Master
              └── ZCOSTCTR_B     ← DB Table: Cost Center Budgets
```

---

## Entity Relationships

```
ZC_PurchaseRequisition (root)
  │
  ├── [composition 0..*] ZC_PRItem
  │      └── [association 0..1] ZC_Vendor (value help for PreferredVendor)
  │
  ├── [composition 0..*] ZC_PRAuditLog  (immutable, written by actions)
  │
  └── [association 0..1] ZC_CostCenterBudget  (budget display on Object Page)
```

---

## File Structure

```
ProcureFlow/
├── 01_ddl_tables/           DDIC table definitions (5 tables)
├── 02_cds_interface_views/  ZI_ base views (no auth, internal)
├── 03_cds_consumption_views/ ZC_ projection views (auth check, OData)
├── 04_access_control/       DCL access control (3-way OR auth)
├── 05_behavior_definition/  BDEF (managed root + projection + action params)
├── 06_behavior_implementation/ ZBP class (all logic: actions/validations/determinations)
├── 07_service_definition/   ZPROCUREFLOW_SRV.srvd
├── 08_service_binding/      ZPROCUREFLOW_UI_O4.srvb (OData V4 - UI)
├── 09_metadata_extensions/  Fiori Elements annotations (List Report + Object Page)
├── 10_authorization/        PFCG roles + auth objects documentation
├── 11_test_data/            INSERT script for demo data
└── README.md                This file
```

---

## Activation Order (Important!)

Activate objects in this exact sequence to avoid dependency errors:

1. **DB Tables** (01_ddl_tables/) — ZPUR_REQHDR, ZPUR_REQITM, ZVENDOR_M, ZCOSTCTR_B, ZPUR_AUDITLOG
2. **Draft Tables** — Create mirror tables: ZPUR_REQHDR_D, ZPUR_REQITM_D, ZPUR_AUDITLOG_D  
   *(Structure identical to base tables plus standard draft columns: DRAFTENTITYOPERATIONCODE, LOCALLASTCHANGEDBY etc.)*
3. **Interface Views** (02_cds_interface_views/) — ZI_Vendor, ZI_CostCenterBudget, ZI_PRAuditLog, ZI_PRItem, ZI_PurchaseRequisition
4. **Consumption Views** (03_cds_consumption_views/) — same order as above (ZC_)
5. **Access Control** (04_access_control/) — ZI_ DCL first, then ZC_ DCL
6. **Behavior Definition** (05_behavior_definition/) — ZI_ BDEF first, then ZC_
7. **Behavior Implementation** (06_behavior_implementation/) — ZBP_PURCHASEREQUISITION class
8. **Service Definition** (07_service_definition/) — ZPROCUREFLOW_SRV
9. **Metadata Extensions** (09_metadata_extensions/) — all 3 MDE files
10. **Service Binding** (08_service_binding/) — ZPROCUREFLOW_UI_O4 → Publish Locally

---

## Business Logic Summary

### Approval Routing (on Submit action)

| PR Total Value         | Route                          | Status After Submit  |
|------------------------|--------------------------------|----------------------|
| < ₹50,000              | Auto-approved (no human needed)| **Approved**         |
| ₹50,000 – ₹5,00,000   | Manager approval required      | **PendingApproval** (Level 1) |
| > ₹5,00,000            | Manager + Finance approval     | **PendingApproval** (Level 2) |

### Budget Check (on Submit)
- Reads `ZCOSTCTR_B` for the cost center + current month/year period
- Blocks submission if `remaining_budget < PR total value`
- On **Approve** (final): deducts value from `consumed_budget` and `remaining_budget`

### Determinations (auto-triggered)
| Trigger               | Determination          | Effect                                          |
|-----------------------|------------------------|-------------------------------------------------|
| Item: Quantity/Price change | CalculateLineTotal | `LineTotal = Quantity × UnitPrice`            |
| Item: MaterialGroup change  | SuggestVendor      | Auto-fills `PreferredVendor` from ZVENDOR_M   |
| PR: Item change             | CalculatePRTotal   | Sums all `LineTotal` → updates `TotalValue`   |
| PR: Create                  | SetInitialStatus   | Sets `Status = 'Draft'`, `CreationDate`       |
| PR: Create                  | SetPrIdExternal    | Generates human-readable PR number            |

---

## End-to-End Test Flow

### Scenario A: Low-Value Auto-Approval (< ₹50,000)

1. Log in as **REQUESTER1**
2. Open Fiori app → **Create** new PR
3. Fill: Department = IT, Cost Center = CC_IT, Priority = Low
4. Add item: Material = MAT-A4PAPER, Qty = 10, Price = 500 → LineTotal auto-calculates to 5,000
5. Click **Submit** → Budget check passes (₹5,000 < ₹1,650,000 remaining)
6. Status changes directly to **Approved** (value < ₹50,000 threshold)
7. Check Audit Log tab — see auto-approve entry
8. Check cost center CC_IT budget → consumed_budget NOT deducted (auto-approve runs deduction inline)

### Scenario B: Manager Approval Flow (₹50k – ₹500k)

1. Log in as **REQUESTER1** → Create PR with 3 monitors × ₹30,000 = ₹90,000
2. Submit → Status: **PendingApproval** (Level 1), Approver: MANAGER1
3. Log out → Log in as **MANAGER1**
4. List Report shows PR in queue (DCL: Approver = current user)
5. Open PR → Object Page shows Approve / Reject / Delegate buttons (feature control)
6. Click **Approve** → Status: **Approved**
7. Budget: CC_IT consumed_budget +₹90,000, remaining_budget -₹90,000
8. Audit Log: 2 entries (Submit + Approve)

### Scenario C: Rejection with Mandatory Comment

1. Repeat Scenario B steps 1–4
2. Click **Reject** → Dialog asks for comment
3. Leave comment empty → Error: "Rejection comment is mandatory"
4. Enter comment "Budget not available this quarter" → Confirm
5. Status: **Rejected**, Rejection comment visible on header
6. Audit Log: Submit + Reject entries

### Scenario D: Finance-Level PR (> ₹500k)

1. As REQUESTER2 → Create PR: 3 motors × ₹200,000 = ₹600,000
2. Submit → Check budget CC_OPS: remaining = ₹200,000 < ₹600,000
3. **Expected**: Submission blocked with error "Insufficient budget"
4. Adjust quantity to 1 motor (₹200,000) → Submit succeeds
5. ApprovalLevel = 2, Status = PendingApproval
6. Log in as MANAGER2 → Approve (1st approval)
7. Log in as FINANCE_USER (role ZPROCUREFLOW_FINANCE) → Approve (final)
8. Budget deducted from CC_OPS on final approval

### Scenario E: Delegate and Withdraw

**Delegate**: As MANAGER1 with pending PR → Click Delegate → Enter substitute MANAGER3 → Approver field updates  
**Withdraw**: As REQUESTER1 with Draft PR → Click Withdraw → Status = Closed

---

## BTP ABAP Environment Constraints

| Feature                    | S/4HANA On-Prem | BTP ABAP Environment |
|----------------------------|-----------------|----------------------|
| PFCG transaction           | ✅ Available    | ❌ Use BTP IAM App   |
| SU21 auth object creation  | ✅ Available    | ❌ Use ADT wizard    |
| Number ranges (NR_OBJECT)  | ✅ Available    | ⚠️ Use UUID-based keys (already done) |
| `/IWFND/MAINT_SERVICE`     | ✅ Available    | ❌ Use "Publish Locally" in ADT |
| ABAP Unit Tests            | ✅              | ✅                   |
| Draft enablement           | ✅              | ✅                   |
| OData V4 RAP               | ✅              | ✅                   |
| Fiori Elements             | ✅              | ✅                   |

---

## Key Design Decisions

1. **UUID keys** — Using `sysuuid_x16` for all entity keys ensures compatibility with BTP (no number range dependency) and supports parallel test data creation.

2. **Draft tables** — Must be created manually in ADT with the same structure as base tables plus RAP draft administrative fields. ADT provides a "Generate Draft Table" wizard from the BDEF editor.

3. **LocalLastChangedAt as ETag** — The `utclong` timestamp field on both header and item serves as the optimistic lock/ETag. Framework updates it automatically on every change.

4. **Budget deduction in Approve action** — Uses `SELECT ... FOR UPDATE` to lock the budget row before decrementing, preventing race conditions when two concurrent approvals reference the same cost center.

5. **Audit log written directly to DB** — Audit entries bypass the RAP modify framework and use direct `INSERT` statements inside action handlers. This is intentional — the log is immutable and should not participate in draft or rollback cycles.

6. **Feature controls** — `get_instance_features` hides/disables action buttons per PR instance based on status + user role. This is more fine-grained than PFCG alone and avoids exposing irrelevant actions.

---

## Analytics (Stretch Goal)

To implement the KPI tile / Analytical List Page:

1. Create a new CDS view `ZC_PRAnalytics` as an analytical view:
   ```
   @Analytics.dataCategory: #CUBE
   define view entity ZC_PRAnalytics ...
   ```
2. Add measures: `TotalValue`, `CountOfPR` (with `@DefaultAggregation`)
3. Add dimensions: `Status`, `Department`, `Requester`, `CreationDate`
4. Create a separate service binding of type **OData V4 - Analytics**
5. Add a Fiori Launchpad KPI tile pointing to this service

---

## Contact / Development Notes

- **Naming prefix**: `Z` (customer namespace)  
- **Package**: Create package `ZPROCUREFLOW` with transport request  
- **ADT version**: Use Eclipse 2023-12+ with SAP ADT plugin 3.42+  
- **ABAP version**: Minimum ABAP for Cloud (REL 7.55 for BTP, 7.54 for S/4HANA 2021+)

## Architecture
RAP stack: DDL -> Interface CDS -> Consumption CDS -> BDEF -> Behavior Pool -> OData V4 Service
