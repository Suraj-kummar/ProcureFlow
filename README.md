<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=6366f1,8b5cf6,06b6d4&height=200&section=header&text=ProcureFlow&fontSize=72&fontColor=ffffff&fontAlignY=38&desc=Enterprise%20SAP%20RAP%20Purchase%20Requisition%20System&descAlignY=58&descColor=c7d2fe&animation=fadeIn" width="100%"/>

<br/>

[![SAP RAP](https://img.shields.io/badge/SAP%20RAP-Managed%20BO-0FAAFF?style=for-the-badge&logo=sap&logoColor=white)](https://developers.sap.com/topics/abap-extensibility.html)
[![ABAP](https://img.shields.io/badge/ABAP-7.55%2B-0057A8?style=for-the-badge&logo=sap&logoColor=white)](https://www.sap.com)
[![OData](https://img.shields.io/badge/OData-V4-E8700A?style=for-the-badge)](https://www.odata.org/)
[![Fiori](https://img.shields.io/badge/Fiori-Elements-0072C6?style=for-the-badge&logo=sap&logoColor=white)](https://experience.sap.com/fiori-design-web/)
[![License](https://img.shields.io/badge/License-MIT-10b981?style=for-the-badge)](LICENSE)
[![Commits](https://img.shields.io/badge/Commits-57-6366f1?style=for-the-badge&logo=git&logoColor=white)](https://github.com/Suraj-kummar/ProcureFlow/commits/main)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-10b981?style=for-the-badge)](https://github.com/Suraj-kummar/ProcureFlow)

<br/>

> **ProcureFlow** is a full-stack, enterprise-grade Purchase Requisition (PR) approval system built on **SAP ABAP RESTful Application Programming Model (RAP)**. It handles end-to-end procurement workflows — from PR creation to multi-level approvals, budget validation, vendor suggestion, and full audit trail — all within a modern Fiori Elements UI.

<br/>

[🚀 Live Demo](https://procureflow.netlify.app) &nbsp;·&nbsp; [📖 Docs](#-table-of-contents) &nbsp;·&nbsp; [⚡ Quick Start](#-quick-start) &nbsp;·&nbsp; [🏗️ Architecture](#-architecture)

</div>

---

## 📋 Table of Contents

- [✨ Features](#-features)
- [🏗️ Architecture](#-architecture)
- [🗂️ Project Structure](#-project-structure)
- [⚙️ Tech Stack](#-tech-stack)
- [🗃️ Data Model](#-data-model)
- [🔄 Business Logic](#-business-logic)
- [🔐 Authorization Model](#-authorization-model)
- [⚡ Quick Start](#-quick-start)
- [🧪 Test Scenarios](#-test-scenarios)
- [🌐 Live Demo](#-live-demo)
- [📊 Analytics](#-analytics)
- [🎯 Key Design Decisions](#-key-design-decisions)
- [☁️ BTP vs On-Prem](#-btp-vs-on-prem-compatibility)
- [📞 Contact](#-contact)

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🛒 Procurement Core
- ✅ Full **Purchase Requisition lifecycle** (Draft → Submit → Approve/Reject → Closed)
- ✅ **Multi-level approval routing** (Auto / Manager / Finance)
- ✅ **Real-time budget validation** against cost center limits
- ✅ **Automatic budget deduction** on final approval
- ✅ **Vendor auto-suggestion** based on material group
- ✅ **Line item management** with dynamic price calculation

</td>
<td width="50%">

### 🧠 SAP RAP Implementation
- ✅ **Managed Business Object** with draft enablement
- ✅ **CDS-based access control** (DCL with 3-way OR auth)
- ✅ **Feature controls** per instance (show/hide action buttons)
- ✅ **7 Determinations** (auto-calc, status init, PR numbering)
- ✅ **5 Validations** (items, budget, dates, quantity, price)
- ✅ **5 Actions** (Submit, Approve, Reject, Delegate, Withdraw)

</td>
</tr>
<tr>
<td width="50%">

### 📊 Visibility & Audit
- ✅ **Full audit trail** — every status change logged immutably
- ✅ **Role-based data visibility** (Requester sees own PRs only)
- ✅ **Analytics dashboard** with KPI tiles and bar charts
- ✅ **Budget utilisation bars** per cost center
- ✅ **Overdue PR** highlighting

</td>
<td width="50%">

### 💻 Browser Demo
- ✅ **Full Fiori-style demo** — runs in any browser (no SAP needed)
- ✅ **Dark glassmorphism UI** with animated gradient orbs
- ✅ **Role switching** — test as Requester, Approver, or Finance
- ✅ **Live budget tracking** with animated progress bars
- ✅ **Toast notifications** and modal dialogs

</td>
</tr>
</table>

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    FIORI LAUNCHPAD (Browser)                     │
│              Fiori Elements — List Report + Object Page          │
└─────────────────────────┬───────────────────────────────────────┘
                          │  OData V4
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│              SERVICE BINDING — ZPROCUREFLOW_UI_O4               │
│                   Service Definition — ZPROCUREFLOW_SRV          │
└──────┬──────────────────┬──────────────────────────────┬────────┘
       │                  │                              │
       ▼                  ▼                              ▼
  ZC_PurchaseReq    ZC_PRItem              ZC_PRAuditLog
  (root, draft)    (child, items)         (child, audit)
       │                  │                              │
       └──────────────────▼──────────────────────────────┘
                          │  (CDS Projection Layer with DCL)
                          ▼
              ZI_PurchaseRequisition (Interface CDS)
              ZI_PRItem · ZI_Vendor · ZI_CostCenterBudget
              ZI_PRAuditLog
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DATABASE TABLES (DDIC)                        │
│  ZPUR_REQHDR  ZPUR_REQITM  ZPUR_AUDITLOG  ZVENDOR_M  ZCOSTCTR_B│
└─────────────────────────────────────────────────────────────────┘
                          ▲
                          │  RAP Behavior
┌─────────────────────────────────────────────────────────────────┐
│            ZBP_PURCHASEREQUISITION (Behavior Pool)               │
│  ┌────────────┐ ┌──────────────┐ ┌───────────────────────────┐  │
│  │ VALIDATIONS│ │  DETERMINA-  │ │        ACTIONS            │  │
│  │ • Items    │ │  TIONS       │ │ • Submit (routing logic)  │  │
│  │ • Budget   │ │ • LineTotal  │ │ • Approve (multi-step)    │  │
│  │ • Dates    │ │ • PRTotal    │ │ • Reject (mandatory msg)  │  │
│  │ • Qty/Price│ │ • InitStatus │ │ • Delegate (substitution) │  │
│  │ • Vendor   │ │ • PRNumber   │ │ • Withdraw (close)        │  │
│  └────────────┘ └──────────────┘ └───────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🗂️ Project Structure

```
ProcureFlow/
│
├── 📁 01_ddl_tables/               Database Table Definitions
│   ├── ZPUR_REQHDR.abap            PR Header (UUID key, status, approver, value)
│   ├── ZPUR_REQITM.abap            PR Line Items (material, qty, price, vendor)
│   ├── ZPUR_AUDITLOG.abap          Immutable audit trail log
│   ├── ZVENDOR_M.abap              Vendor master with material group mapping
│   └── ZCOSTCTR_B.abap             Cost center budget by period
│
├── 📁 02_cds_interface_views/      Interface CDS Views (ZI_ prefix)
│   ├── ZI_PurchaseRequisition.cds  Root BO view with all associations
│   ├── ZI_PRItem.cds               Line item child view
│   ├── ZI_Vendor.cds               Vendor lookup view
│   ├── ZI_CostCenterBudget.cds     Budget data view
│   └── ZI_PRAuditLog.cds           Audit log child view
│
├── 📁 03_cds_consumption_views/    Projection CDS Views (ZC_ prefix)
│   ├── ZC_PurchaseRequisition.cds  Draft-enabled root projection
│   ├── ZC_PRItem.cds               Item projection with UI annotations
│   ├── ZC_Vendor.cds               Vendor with @Consumption.valueHelpDefinition
│   ├── ZC_CostCenterBudget.cds     Budget projection
│   └── ZC_PRAuditLog.cds           Audit log projection
│
├── 📁 04_access_control/           CDS Access Control (DCL)
│   ├── ZI_PurchaseRequisition.dcl  Interface view auth (3-way OR)
│   └── ZC_PurchaseRequisition.dcl  Consumption view auth with role checks
│
├── 📁 05_behavior_definition/      RAP Behavior Definitions
│   ├── ZI_PurchaseRequisition.bdef Interface BDEF (managed, draft, locking)
│   ├── ZC_PurchaseRequisition.bdef Projection BDEF (use actions, draft)
│   └── ZA_ActionParameters.cds     Abstract entities for action parameters
│
├── 📁 06_behavior_implementation/  Behavior Pool (ABAP Class)
│   ├── ZBP_PURCHASEREQUISITION.clas.abap           Class shell
│   ├── ZBP_PURCHASEREQUISITION.clas.locals_def.abap Handler & saver declarations
│   └── ZBP_PURCHASEREQUISITION.clas.locals_imp.abap Full logic implementation
│
├── 📁 07_service_definition/       OData Service Definition
│   └── ZPROCUREFLOW_SRV.srvd       Exposes all ZC_ views as OData entities
│
├── 📁 08_service_binding/          OData V4 UI Service Binding
│   └── ZPROCUREFLOW_UI_O4.srvb     Fiori Elements binding (publish locally)
│
├── 📁 09_metadata_extensions/      Fiori UI Annotations
│   ├── ZC_PurchaseRequisition.MDE  List Report + Object Page (header/facets)
│   ├── ZC_PRItem.MDE               Line items table annotations
│   └── ZC_PRAuditLog.MDE           Audit trail display annotations
│
├── 📁 10_authorization/            Authorization Documentation
│   ├── AUTH_OBJECTS.md             ZPUR_PR_A, ZPUR_VEN, ZPUR_ADM definitions
│   └── PFCG_ROLES.md               Role guide: Requester, Approver, Finance, Admin
│
├── 📁 11_test_data/                Demo Data
│   └── TEST_DATA.abap              INSERT script — vendors, cost centers, PRs
│
├── 📁 localhost_demo/              🌐 Browser-Runnable Demo (no SAP needed!)
│   ├── index.html                  Fiori-style UI shell
│   ├── styles.css                  Dark glassmorphism design system
│   └── app.js                      Full business logic in JavaScript
│
├── netlify.toml                    Netlify deployment config
└── README.md                       You're reading it 😎
```

---

## ⚙️ Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Database** | ABAP DDIC Tables | Persistent storage for PRs, items, vendors, budgets |
| **Data Model** | CDS Interface Views (`ZI_`) | Base views with associations, no auth |
| **OData Layer** | CDS Projection Views (`ZC_`) | Fiori-exposed entities with UI annotations |
| **Access Control** | CDS DCL | Instance-level authorization |
| **Business Logic** | ABAP RAP Behavior Pool | Actions, validations, determinations |
| **API** | OData V4 (RAP-generated) | Automatic REST API from behavior definition |
| **UI** | SAP Fiori Elements | Zero-code Fiori UI from annotations |
| **Demo** | Vanilla HTML/CSS/JS | Browser demo — no SAP system needed |
| **Deployment** | Netlify | Live demo hosting |

---

## 🗃️ Data Model

### Entity Relationships

```
ZPUR_REQHDR (PR Header)
  │  PrId (UUID) ◄── primary key
  │  PrExtId, Requester, Department
  │  CostCenter, TotalValue, Currency
  │  Status, ApprovalLevel, Approver
  │  FinanceApprovedBy, RejectionComment
  │  CreationDate, SubmittedAt, ApprovedAt
  │
  ├── [1:N] ZPUR_REQITM (PR Items)
  │     ItemId (UUID), PrId (FK)
  │     ItemNo, MaterialNo, Description
  │     Quantity, UOM, UnitPrice, LineTotal
  │     MaterialGroup, PreferredVendor
  │
  ├── [1:N] ZPUR_AUDITLOG (Audit Log)
  │     LogId (UUID), PrId (FK)
  │     LogTimestamp, ChangedBy
  │     OldStatus, NewStatus, ActionTaken, Comments
  │
  ├── [N:1] ZVENDOR_M (Vendor Master) ── lookup via PreferredVendor
  │     VendorId, VendorName, MaterialGroup
  │     LastUsedDate, UnitPrice, IsPreferred
  │
  └── [N:1] ZCOSTCTR_B (Cost Center Budget) ── lookup via CostCenter
        CostCenter, BudgetPeriod (YYYY/MM)
        TotalBudget, ConsumedBudget, RemainingBudget
```

---

## 🔄 Business Logic

### Approval Routing Matrix

| PR Total Value | Approval Route | Level | Status After Submit |
|---|---|---|---|
| `< ₹50,000` | 🤖 **Auto-approved** by system | 0 | ✅ `Approved` |
| `₹50,000 – ₹5,00,000` | 👨‍💼 **Manager approval** required | 1 | ⏳ `PendingApproval` |
| `> ₹5,00,000` | 👨‍💼 Manager → 💰 **Finance approval** | 2 | ⏳ `PendingApproval` |

### Submit Action — Full Flow

```
User clicks SUBMIT
       │
       ├── ✅ Validate: at least 1 item exists?
       ├── ✅ Validate: all items have qty > 0 and price > 0?
       ├── ✅ Validate: cost center budget record exists for current period?
       ├── ✅ Validate: remaining_budget ≥ PR total value?
       │
       ├── PR value < 50,000 → Status = APPROVED, budget deducted immediately
       ├── PR value ≤ 500,000 → Status = PENDING, ApprovalLevel = 1
       └── PR value > 500,000 → Status = PENDING, ApprovalLevel = 2
                                          │
                                          └── Audit log entry written
```

### Determinations (Auto-Triggered)

| Event | Determination | Effect |
|---|---|---|
| Item: Qty or Price changes | `CalculateLineTotal` | `LineTotal = Qty × UnitPrice` |
| Item: MaterialGroup changes | `SuggestVendor` | Auto-fill `PreferredVendor` from `ZVENDOR_M` |
| PR: Any item change | `CalculatePRTotal` | Sum all `LineTotal` → update `TotalValue` |
| PR: On create | `SetInitialStatus` | Set `Status = 'Draft'`, stamp `CreationDate` |
| PR: On create | `SetPrIdExternal` | Generate human-readable `PR-YYYYMMDD-NNNNN` |

### Status Lifecycle

```
                    ┌─────────────────────────────────────────┐
                    │                                         │
  [Create] ──► DRAFT ──► [Submit] ──► PENDING_APPROVAL       │
                │                         │                   │
                │                    [Approve]  [Reject]      │
                │                         │         │         │
                │              [Withdraw] │         ▼         │
                └────────────────────────►│     REJECTED      │
                                          │                   │
                                          ▼                   │
                                       APPROVED               │
                                          │                   │
                                     [Withdraw]               │
                                          │                   │
                                          ▼                   │
                                        CLOSED ◄──────────────┘
```

---

## 🔐 Authorization Model

### Authorization Objects

| Object | Field | Purpose |
|---|---|---|
| `ZPUR_PR_A` | `ACTVT` (01/02/03/06), `ZPUR_STAT` | Control create/read/update/delete/approve by status |
| `ZPUR_VEN` | `ACTVT`, `ZPUR_VGRP` | Vendor data access by vendor group |
| `ZPUR_ADM` | `ACTVT` | Admin-level override access |

### PFCG Roles

| Role | Users | Permissions |
|---|---|---|
| `ZPROCUREFLOW_REQUESTER` | REQUESTER1, REQUESTER2 | Create, edit, submit own PRs |
| `ZPROCUREFLOW_APPROVER` | MANAGER1, MANAGER2 | View pending PRs, approve/reject/delegate |
| `ZPROCUREFLOW_FINANCE` | FINANCE1 | Finance-level approvals (Level 2 PRs) |
| `ZPROCUREFLOW_ADMIN` | Admin users | Full access including budget override |

### CDS Access Control — 3-Way OR Logic

```abap
-- ZC_PurchaseRequisition.dcl
define role ZC_PurchaseRequisition {
  grant select on ZC_PurchaseRequisition
    where (
      /* Requester sees own PRs */
      Requester = aspect pfcg_auth(ZPUR_PR_A, ZPUR_REQSR, ACTVT = '03')
      OR
      /* Approver sees PRs assigned to them */
      Approver = aspect pfcg_auth(ZPUR_PR_A, ZPUR_APPVR, ACTVT = '03')
      OR
      /* Finance sees all Level-2 PRs */
      ApprovalLevel = aspect pfcg_auth(ZPUR_PR_A, ZPUR_APVLV, ACTVT = '03')
    );
}
```

---

## ⚡ Quick Start

### Prerequisites

- SAP BTP ABAP Environment (trial: [SAP BTP Trial](https://cockpit.hanatrial.ondemand.com/)) **or** S/4HANA 2021+
- Eclipse IDE with SAP ADT plugin (3.42+)
- ABAP 7.55 for Cloud or 7.54 for on-prem

### Step 1 — Clone the Repo

```bash
git clone https://github.com/Suraj-kummar/ProcureFlow.git
cd ProcureFlow
```

### Step 2 — Activate Objects (in ADT, in this exact order!)

```
1️⃣  01_ddl_tables/          ← Activate all 5 tables
2️⃣  Draft Tables             ← Create via ADT "Generate Draft Table" wizard
                               (ZPUR_REQHDR_D, ZPUR_REQITM_D, ZPUR_AUDITLOG_D)
3️⃣  02_cds_interface_views/  ← ZI_Vendor → ZI_CostCenterBudget → ZI_PRAuditLog
                               → ZI_PRItem → ZI_PurchaseRequisition
4️⃣  03_cds_consumption_views/ ← Same order (ZC_ prefix)
5️⃣  04_access_control/       ← ZI_ DCL first, then ZC_ DCL
6️⃣  05_behavior_definition/  ← ZI_ BDEF → ZA_ActionParameters → ZC_ BDEF
7️⃣  06_behavior_implementation/ ← ZBP_PURCHASEREQUISITION class
8️⃣  07_service_definition/   ← ZPROCUREFLOW_SRV
9️⃣  09_metadata_extensions/  ← All 3 MDE files
🔟  08_service_binding/       ← ZPROCUREFLOW_UI_O4 → "Publish Locally"
```

### Step 3 — Load Test Data

```abap
-- Run in SAP GUI / ADT Console:
-- Open 11_test_data/TEST_DATA.abap and execute
-- This inserts: 3 vendors, 2 cost centers, 4 demo PRs with items
```

### Step 4 — Launch Fiori App

Open the service binding `ZPROCUREFLOW_UI_O4` in ADT → Click **"Preview"**

> 💡 **No SAP system?** Just open `localhost_demo/index.html` directly in your browser!

---

## 🧪 Test Scenarios

### Scenario A — Low Value Auto Approval (`< ₹50,000`)
```
1. Login as REQUESTER1
2. Create PR → Department: IT, Cost Center: CC_IT
3. Add item: MAT-A4PAPER, Qty: 10, Price: ₹500 → Total: ₹5,000
4. Submit
5. ✅ Expected: Status = APPROVED instantly (auto-approved by system)
6. Check Audit Log: entry shows "Auto-approved: value ₹5,000 < threshold ₹50,000"
```

### Scenario B — Manager Approval Flow (`₹50k – ₹5L`)
```
1. REQUESTER1 → Create PR with 3 monitors × ₹30,000 = ₹90,000
2. Submit → Status: PendingApproval (Level 1), Approver: MANAGER1
3. Switch to MANAGER1 → PR appears in list (DCL restricts to assignee)
4. Open PR → Click Approve → Add comment
5. ✅ Expected: Status = APPROVED, budget deducted from CC_IT
6. Audit Log: 2 entries (Submit + Approve)
```

### Scenario C — Mandatory Rejection Comment
```
1. Repeat Scenario B → Switch to MANAGER1
2. Click Reject → Leave comment EMPTY → Click Confirm
3. ❌ Expected: Error toast "Rejection reason is mandatory"
4. Enter "Budget exhausted this quarter" → Confirm
5. ✅ Expected: Status = REJECTED, comment visible on object page header
```

### Scenario D — Finance Level (`> ₹5,00,000`)
```
1. REQUESTER2 → Create PR: 3 motors × ₹200,000 = ₹600,000
2. Submit → Budget check: CC_OPS remaining = ₹200,000 < ₹600,000
3. ❌ Expected: Blocked — "Insufficient budget"
4. Change qty to 1 (₹200,000) → Submit succeeds
5. ApprovalLevel = 2, Status = PendingApproval
6. MANAGER2 → Approve (1st step), FINANCE1 → Final Approve
7. ✅ Budget deducted on final approval
```

### Scenario E — Delegate & Withdraw
```
Delegate: MANAGER1 → Click Delegate → Enter MANAGER3 → Approver field updates live
Withdraw: REQUESTER1 with Draft PR → Click Withdraw → Status = Closed
```

---

## 🌐 Live Demo

The `localhost_demo/` folder is a fully functional **browser-only demo** — no SAP system required. It mirrors all the real ABAP business logic in JavaScript.

### Features of the Demo

| Feature | Implementation |
|---|---|
| Role-based visibility | `visiblePRs()` mirrors DCL access control |
| Approval routing | Same threshold constants as ABAP |
| Budget validation | Live check against in-memory cost center data |
| Vendor suggestion | Material group → preferred vendor lookup |
| Audit log | Written on every status change |
| Multi-step Finance | Level 2 approval flow fully simulated |

### Run it locally

```bash
# Option 1: Just open the file
open localhost_demo/index.html

# Option 2: Serve with a local server (avoids CORS on some browsers)
npx serve localhost_demo
# → Visit http://localhost:3000
```

### 🎭 Available Demo Users

| User | Role | Can Do |
|---|---|---|
| `REQUESTER1` | Requester | Create, edit, submit own PRs |
| `REQUESTER2` | Requester | Create, edit, submit own PRs |
| `MANAGER1` | Approver | Approve/reject/delegate assigned PRs |
| `MANAGER2` | Approver | Approve/reject/delegate assigned PRs |
| `FINANCE1` | Finance Approver | Approve Level-2 (high-value) PRs |

---

## 📊 Analytics

The Analytics Dashboard provides real-time insights:

| KPI Tile | Description |
|---|---|
| ⏳ Pending Approvals | PRs waiting for action right now |
| ✅ Approved PRs | Successfully approved this period |
| 📋 Total Requisitions | All PRs across all statuses |
| 💸 Total PR Value | Combined value of all requisitions |
| ❌ Rejected PRs | PRs blocked by budget or policy |
| 🏦 Remaining Budget | Available budget across all cost centers |

To extend with **SAP Fiori Analytical List Page**:

```cds
@Analytics.dataCategory: #CUBE
define view entity ZC_PRAnalytics
  as select from ZI_PurchaseRequisition {
    @DefaultAggregation: #COUNT   key PrId,
    @DefaultAggregation: #SUM     TotalValue,
    Status, Department, Requester, CreationDate
  }
```

---

## 🎯 Key Design Decisions

<details>
<summary><b>🔑 Why UUID keys?</b></summary>

Using `sysuuid_x16` for all entity primary keys ensures:
- ✅ Compatible with BTP ABAP Environment (no number range objects needed)
- ✅ Supports parallel test data creation without collisions
- ✅ RAP draft framework works seamlessly with UUID-keyed entities

</details>

<details>
<summary><b>📝 Why direct INSERT for audit logs?</b></summary>

Audit log entries use direct `INSERT` statements inside action handlers, bypassing the RAP modify framework. This is intentional:
- Audit logs are **immutable** — they should never participate in draft or rollback cycles
- RAP framework would include them in draft state, making them reversible
- Direct INSERT ensures every action is permanently recorded regardless of draft discard

</details>

<details>
<summary><b>💰 Budget deduction race condition prevention</b></summary>

The `Approve` action uses `SELECT ... FOR UPDATE` to lock the cost center budget row before decrementing. This prevents race conditions when two managers approve different PRs referencing the same cost center simultaneously.

</details>

<details>
<summary><b>🔒 Feature controls vs PFCG</b></summary>

`get_instance_features` dynamically shows/hides action buttons per-instance based on `Status + current user role`. This is more fine-grained than PFCG roles alone — for example, the Approve button only appears when `Status = PendingApproval AND Approver = current_user`, not just when the user has the Approver role.

</details>

<details>
<summary><b>🕒 ETag / Optimistic Locking</b></summary>

`LocalLastChangedAt` (utclong) on both header and item entities serves as the ETag for optimistic locking. The RAP framework automatically updates this timestamp on every change, ensuring concurrent edit detection works out of the box.

</details>

---

## ☁️ BTP vs On-Prem Compatibility

| Feature | S/4HANA On-Prem | BTP ABAP Environment |
|---|---|---|
| PFCG transaction | ✅ | ❌ Use BTP IAM App instead |
| SU21 auth object creation | ✅ | ❌ Use ADT wizard |
| Number ranges (`NR_OBJECT`) | ✅ | ⚠️ UUID-based keys used here ✅ |
| `/IWFND/MAINT_SERVICE` | ✅ | ❌ Use "Publish Locally" in ADT |
| Draft enablement | ✅ | ✅ |
| OData V4 RAP | ✅ | ✅ |
| Fiori Elements | ✅ | ✅ |
| ABAP Unit Tests | ✅ | ✅ |
| CDS Access Control | ✅ | ✅ |

---

## 📞 Contact

<div align="center">

**Built with ❤️ by Suraj Kumar**

[![GitHub](https://img.shields.io/badge/GitHub-Suraj--kummar-181717?style=for-the-badge&logo=github)](https://github.com/Suraj-kummar)
[![Email](https://img.shields.io/badge/Email-surajnsg115%40gmail.com-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:surajnsg115@gmail.com)

| Detail | Value |
|---|---|
| **Naming Prefix** | `Z` (customer namespace) |
| **Package** | `ZPROCUREFLOW` |
| **ADT Version** | Eclipse 2023-12+ with SAP ADT 3.42+ |
| **Min ABAP Version** | 7.55 (BTP) / 7.54 (S/4HANA 2021+) |

</div>

---

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=6366f1,8b5cf6,06b6d4&height=100&section=footer" width="100%"/>

**⭐ Star this repo if you found it useful!**

*ProcureFlow — Because procurement should be smart, fast, and beautiful.*

</div>

<!-- [9/12] screenshots section placeholder -->

<!-- [10/12] contributing guidelines added -->
