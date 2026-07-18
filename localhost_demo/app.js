'use strict';
// =============================================================================
// ProcureFlow — Business Logic & UI Engine
// All SAP RAP business rules implemented in JavaScript
// =============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS (mirrors lcl_constants from ABAP)
// ─────────────────────────────────────────────────────────────────────────────
const STATUS = {
  DRAFT:    'Draft',
  SUBMITTED:'Submitted',
  PENDING:  'PendingApproval',
  APPROVED: 'Approved',
  REJECTED: 'Rejected',
  CLOSED:   'Closed'
};
const THRESHOLD_AUTO    = 50000;    // Auto-approve below this
const THRESHOLD_FINANCE = 500000;   // Finance approval above this

// ─────────────────────────────────────────────────────────────────────────────
// DATA STORE — initialised from seed data, persisted in memory
// ─────────────────────────────────────────────────────────────────────────────
let DB = {
  vendors: [],
  costCenters: [],
  prs: [],
  items: [],
  auditLog: []
};

function seedData() {
  DB.vendors = [
    { vendorId:'VND001', vendorName:'TechSupply India Pvt Ltd',  materialGroup:'ELECTRONICS', lastUsedDate:'2025-06-01', unitPrice:1500,  currency:'INR', isPreferred:true },
    { vendorId:'VND002', vendorName:'Office Essentials Co.',      materialGroup:'STATIONERY',  lastUsedDate:'2025-05-15', unitPrice:50,    currency:'INR', isPreferred:true },
    { vendorId:'VND003', vendorName:'Industrial Parts Ltd',       materialGroup:'MACHINERY',   lastUsedDate:'2025-04-01', unitPrice:25000, currency:'INR', isPreferred:false}
  ];

  const period = currentPeriod();
  DB.costCenters = [
    { costCenter:'CC_IT',  budgetPeriod:period, totalBudget:2000000, consumedBudget:350000,  remainingBudget:1650000, currency:'INR', department:'IT' },
    { costCenter:'CC_OPS', budgetPeriod:period, totalBudget:1000000, consumedBudget:800000,  remainingBudget:200000,  currency:'INR', department:'Operations' }
  ];

  const pr1 = uid(), pr2 = uid(), pr3 = uid(), pr4 = uid();

  DB.prs = [
    { prId:pr1, prExt:'PR-20250701-10001', requester:'REQUESTER1', department:'IT',          costCenter:'CC_IT',  creationDate:'2025-07-01', totalValue:30000,  currency:'INR', status:STATUS.DRAFT,    approver:'MANAGER1', priority:'Medium',   approvalLevel:0, financeApprovedBy:'', rejectionComment:'', submittedAt:'', approvedAt:'' },
    { prId:pr2, prExt:'PR-20250702-10002', requester:'REQUESTER1', department:'IT',          costCenter:'CC_IT',  creationDate:'2025-06-29', totalValue:120000, currency:'INR', status:STATUS.PENDING,  approver:'MANAGER1', priority:'High',     approvalLevel:1, financeApprovedBy:'', rejectionComment:'', submittedAt:'2025-06-30', approvedAt:'' },
    { prId:pr3, prExt:'PR-20250703-10003', requester:'REQUESTER2', department:'Operations',  costCenter:'CC_OPS', creationDate:'2025-06-25', totalValue:27000,  currency:'INR', status:STATUS.APPROVED, approver:'SYSTEM',   priority:'Low',      approvalLevel:0, financeApprovedBy:'', rejectionComment:'', submittedAt:'2025-06-26', approvedAt:'2025-06-26' },
    { prId:pr4, prExt:'PR-20250704-10004', requester:'REQUESTER2', department:'Operations',  costCenter:'CC_OPS', creationDate:'2025-06-20', totalValue:600000, currency:'INR', status:STATUS.REJECTED, approver:'MANAGER2', priority:'Critical', approvalLevel:2, financeApprovedBy:'', rejectionComment:'Budget overrun: Operations already at 80% consumption.', submittedAt:'2025-06-21', approvedAt:'' }
  ];

  DB.items = [
    { itemId:uid(), prId:pr1, itemNo:'00010', materialNo:'MAT-LAPTOP',   description:'Laptop — Dell XPS 15',     qty:2,  uom:'EA', unitPrice:15000, currency:'INR', lineTotal:30000,  materialGroup:'ELECTRONICS', preferredVendor:'VND001' },
    { itemId:uid(), prId:pr2, itemNo:'00010', materialNo:'MAT-MONITOR',  description:'27" 4K Monitor',            qty:3,  uom:'EA', unitPrice:25000, currency:'INR', lineTotal:75000,  materialGroup:'ELECTRONICS', preferredVendor:'VND001' },
    { itemId:uid(), prId:pr2, itemNo:'00020', materialNo:'MAT-KEYBOARD', description:'Mechanical Keyboard',       qty:5,  uom:'EA', unitPrice:9000,  currency:'INR', lineTotal:45000,  materialGroup:'ELECTRONICS', preferredVendor:'VND001' },
    { itemId:uid(), prId:pr3, itemNo:'00010', materialNo:'MAT-A4PAPER',  description:'A4 Printer Paper (Ream)',   qty:50, uom:'EA', unitPrice:500,   currency:'INR', lineTotal:25000,  materialGroup:'STATIONERY',  preferredVendor:'VND002' },
    { itemId:uid(), prId:pr3, itemNo:'00020', materialNo:'MAT-PEN',      description:'Ballpoint Pens (Box x12)', qty:20, uom:'EA', unitPrice:100,   currency:'INR', lineTotal:2000,   materialGroup:'STATIONERY',  preferredVendor:'VND002' },
    { itemId:uid(), prId:pr4, itemNo:'00010', materialNo:'MAT-CONVEYOR', description:'Conveyor Belt Motor',      qty:3,  uom:'EA', unitPrice:200000,currency:'INR', lineTotal:600000, materialGroup:'MACHINERY',   preferredVendor:'VND003' }
  ];

  DB.auditLog = [
    { logId:uid(), prId:pr2, logTimestamp:'2025-06-30T09:00:00', changedBy:'REQUESTER1', oldStatus:STATUS.DRAFT,   newStatus:STATUS.PENDING,  actionTaken:'Submit',  comments:'Routed to approval level 1 (Manager)' },
    { logId:uid(), prId:pr3, logTimestamp:'2025-06-26T10:00:00', changedBy:'SYSTEM',     oldStatus:STATUS.DRAFT,   newStatus:STATUS.APPROVED, actionTaken:'Submit',  comments:'Auto-approved: value ₹27,000 < threshold ₹50,000' },
    { logId:uid(), prId:pr4, logTimestamp:'2025-06-21T08:00:00', changedBy:'REQUESTER2', oldStatus:STATUS.DRAFT,   newStatus:STATUS.PENDING,  actionTaken:'Submit',  comments:'Routed to approval level 2 (Finance)' },
    { logId:uid(), prId:pr4, logTimestamp:'2025-06-22T14:30:00', changedBy:'MANAGER2',   oldStatus:STATUS.PENDING, newStatus:STATUS.REJECTED, actionTaken:'Reject',  comments:'Budget overrun: Operations already at 80% consumption.' }
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// SESSION / USER
// ─────────────────────────────────────────────────────────────────────────────
let currentUser  = 'REQUESTER1';
let currentRole  = 'Requester';

function switchUser(user, role) {
  currentUser = user;
  currentRole = role;
  document.getElementById('userName').textContent  = user;
  document.getElementById('userRole').textContent  = role;
  document.getElementById('userAvatar').textContent = user.substring(0,2).toUpperCase();
  document.getElementById('userPill').classList.remove('open');
  toast(`Switched to ${user} (${role})`, 'info');
  router();
}

// ─────────────────────────────────────────────────────────────────────────────
// ROUTER — hash-based SPA navigation
// ─────────────────────────────────────────────────────────────────────────────
let currentView = 'list';
let currentPrId = null;

function router() {
  const hash = location.hash || '#list';
  if (hash === '#list')        renderListReport();
  else if (hash === '#new')    renderCreatePR();
  else if (hash === '#analytics') renderAnalytics();
  else if (hash.startsWith('#pr/')) {
    currentPrId = hash.split('/')[1];
    renderObjectPage(currentPrId);
  }
  updateNav();
}

function navigate(path) { location.hash = path; }
function updateNav() {
  const hash = location.hash || '#list';
  document.getElementById('headerNav').innerHTML = `
    <button class="nav-btn ${hash==='#list'?'active':''}"        onclick="navigate('#list')">📋 My PRs</button>
    <button class="nav-btn ${hash==='#analytics'?'active':''}"   onclick="navigate('#analytics')">📊 Analytics</button>
    ${currentRole==='Requester' ? `<button class="nav-btn" onclick="navigate('#new')">＋ New PR</button>` : ''}
  `;
}

// ─────────────────────────────────────────────────────────────────────────────
// VISIBLE PRs (access control — mirrors DCL logic)
// ─────────────────────────────────────────────────────────────────────────────
function visiblePRs() {
  return DB.prs.filter(pr => {
    if (currentRole === 'Requester')       return pr.requester === currentUser;
    if (currentRole === 'Approver')        return pr.approver  === currentUser && pr.status === STATUS.PENDING;
    if (currentRole === 'Finance Approver') return pr.approvalLevel === 2;
    return true;
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// LIST REPORT
// ─────────────────────────────────────────────────────────────────────────────
function renderListReport() {
  const prs = visiblePRs();

  const html = `
    <div class="page-header">
      <div>
        <div class="page-title">Purchase Requisitions</div>
        <div class="page-subtitle">${prs.length} record${prs.length!==1?'s':''} visible for ${currentUser}</div>
      </div>
      ${currentRole==='Requester' ? `<button class="btn btn-primary" onclick="navigate('#new')">＋ Create PR</button>` : ''}
    </div>

    <div class="filter-bar">
      <div class="filter-group">
        <label class="filter-label">Status</label>
        <select class="filter-select" id="fStatus" onchange="applyFilters()">
          <option value="">All</option>
          ${Object.values(STATUS).map(s=>`<option>${s}</option>`).join('')}
        </select>
      </div>
      <div class="filter-group">
        <label class="filter-label">Department</label>
        <select class="filter-select" id="fDept" onchange="applyFilters()">
          <option value="">All</option>
          <option>IT</option><option>Operations</option><option>Finance</option><option>HR</option>
        </select>
      </div>
      <div class="filter-group">
        <label class="filter-label">Priority</label>
        <select class="filter-select" id="fPriority" onchange="applyFilters()">
          <option value="">All</option>
          <option>Low</option><option>Medium</option><option>High</option><option>Critical</option>
        </select>
      </div>
      <div class="filter-group">
        <label class="filter-label">Search</label>
        <input class="filter-input" id="fSearch" placeholder="PR number or requester…" oninput="applyFilters()" />
      </div>
      <button class="btn btn-secondary btn-sm" onclick="clearFilters()">Clear</button>
    </div>

    <div class="card">
      <div class="card-header">
        <span class="card-title">Requisition List</span>
        <span class="text-sm text-muted" id="filteredCount">${prs.length} records</span>
      </div>
      <div class="table-wrap">
        <table id="prTable">
          <thead>
            <tr>
              <th>PR Number</th><th>Requester</th><th>Department</th>
              <th>Total Value</th><th>Status</th><th>Priority</th>
              <th>Approver</th><th>Created</th>
            </tr>
          </thead>
          <tbody id="prTableBody">
            ${renderTableRows(prs)}
          </tbody>
        </table>
        ${prs.length===0 ? `<div class="empty-state"><div class="empty-icon">📄</div><div class="empty-text">No requisitions found</div><div class="empty-sub">Create your first PR to get started</div></div>` : ''}
      </div>
    </div>
  `;
  document.getElementById('mainContent').innerHTML = html;
}

function renderTableRows(prs) {
  return prs.map(pr => `
    <tr onclick="navigate('#pr/${pr.prId}')">
      <td><span style="font-weight:600;color:var(--brand-primary)">${pr.prExt}</span></td>
      <td>${pr.requester}</td>
      <td>${pr.department}</td>
      <td class="amount">₹${fmt(pr.totalValue)}</td>
      <td>${statusBadge(pr.status)}</td>
      <td><span class="priority-chip priority-${pr.priority}">${pr.priority}</span></td>
      <td>${pr.approver}</td>
      <td>${pr.creationDate}</td>
    </tr>
  `).join('');
}

function applyFilters() {
  let prs = visiblePRs();
  const st  = document.getElementById('fStatus')?.value;
  const dep = document.getElementById('fDept')?.value;
  const pri = document.getElementById('fPriority')?.value;
  const q   = (document.getElementById('fSearch')?.value||'').toLowerCase();
  if (st)  prs = prs.filter(p => p.status === st);
  if (dep) prs = prs.filter(p => p.department === dep);
  if (pri) prs = prs.filter(p => p.priority === pri);
  if (q)   prs = prs.filter(p => p.prExt.toLowerCase().includes(q) || p.requester.toLowerCase().includes(q));
  document.getElementById('prTableBody').innerHTML = renderTableRows(prs);
  document.getElementById('filteredCount').textContent = `${prs.length} records`;
}

function clearFilters() {
  ['fStatus','fDept','fPriority','fSearch'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.value = '';
  });
  applyFilters();
}

// ─────────────────────────────────────────────────────────────────────────────
// OBJECT PAGE
// ─────────────────────────────────────────────────────────────────────────────
function renderObjectPage(prId) {
  const pr = DB.prs.find(p => p.prId === prId);
  if (!pr) { navigate('#list'); return; }

  const prItems   = DB.items.filter(i => i.prId === prId);
  const prLogs    = DB.auditLog.filter(l => l.prId === prId).sort((a,b) => b.logTimestamp.localeCompare(a.logTimestamp));
  const cc        = getCostCenter(pr.costCenter);
  const isOwner   = pr.requester === currentUser;
  const isApprover= pr.approver  === currentUser;

  // Feature control (mirrors get_instance_features)
  const canSubmit   = pr.status === STATUS.DRAFT && isOwner;
  const canApprove  = pr.status === STATUS.PENDING && (isApprover || currentRole === 'Finance Approver');
  const canReject   = canApprove;
  const canDelegate = canApprove;
  const canWithdraw = [STATUS.DRAFT, STATUS.SUBMITTED].includes(pr.status) && isOwner;
  const canEdit     = pr.status === STATUS.DRAFT && isOwner;

  document.getElementById('mainContent').innerHTML = `
    <div class="object-page">
      <!-- Header -->
      <div class="op-header">
        <div class="op-breadcrumb">
          <a onclick="navigate('#list')">← Purchase Requisitions</a>
          <span>/</span>
          <span>${pr.prExt}</span>
        </div>
        <div class="op-title">${pr.prExt}</div>
        <div class="op-subtitle">${pr.requester} · ${pr.department} · ${pr.creationDate}</div>
        <div class="op-kpis">
          <div class="kpi-card"><div class="kpi-label">Total Value</div><div class="kpi-value">₹${fmt(pr.totalValue)}</div></div>
          <div class="kpi-card"><div class="kpi-label">Status</div><div class="kpi-value" style="font-size:14px">${statusBadge(pr.status)}</div></div>
          <div class="kpi-card"><div class="kpi-label">Priority</div><div class="kpi-value" style="font-size:14px"><span class="priority-chip priority-${pr.priority}">${pr.priority}</span></div></div>
          <div class="kpi-card"><div class="kpi-label">Approver</div><div class="kpi-value" style="font-size:14px">${pr.approver}</div></div>
          ${pr.approvalLevel > 0 ? `<div class="kpi-card"><div class="kpi-label">Approval Level</div><div class="kpi-value"><span class="badge badge-level">Level ${pr.approvalLevel}</span></div></div>` : ''}
        </div>
        <div class="op-actions">
          ${canSubmit   ? `<button class="btn btn-primary btn-lg" onclick="actionSubmit('${prId}')">🚀 Submit</button>` : ''}
          ${canApprove  ? `<button class="btn btn-success btn-lg" onclick="actionApprove('${prId}')">✅ Approve</button>` : ''}
          ${canReject   ? `<button class="btn btn-danger  btn-lg" onclick="actionReject('${prId}')">❌ Reject</button>` : ''}
          ${canDelegate ? `<button class="btn btn-warning btn-lg" onclick="actionDelegate('${prId}')">🔄 Delegate</button>` : ''}
          ${canWithdraw ? `<button class="btn btn-secondary btn-lg" onclick="actionWithdraw('${prId}')">↩ Withdraw</button>` : ''}
          ${canEdit     ? `<button class="btn btn-ghost btn-lg" onclick="renderAddItemForm('${prId}')">＋ Add Item</button>` : ''}
        </div>
        ${pr.rejectionComment ? `<div style="margin-top:14px;background:rgba(255,0,0,0.12);border:1px solid rgba(255,100,100,0.3);border-radius:8px;padding:10px 14px;font-size:13px;color:#fff">❌ Rejection reason: <em>${pr.rejectionComment}</em></div>` : ''}
      </div>

      <!-- Section Tabs -->
      <div class="section-tabs">
        <button class="section-tab active" id="tab-items"  onclick="switchTab('items')">📦 Line Items (${prItems.length})</button>
        <button class="section-tab"        id="tab-audit"  onclick="switchTab('audit')">📋 Approval History (${prLogs.length})</button>
        <button class="section-tab"        id="tab-budget" onclick="switchTab('budget')">💰 Budget Summary</button>
        <button class="section-tab"        id="tab-info"   onclick="switchTab('info')">ℹ️ General Info</button>
      </div>

      <!-- Section: Items -->
      <div class="section-panel active" id="panel-items">
        <div class="card">
          <div class="card-header">
            <span class="card-title">📦 Purchase Requisition Items</span>
            <span class="text-sm text-muted">${prItems.length} item${prItems.length!==1?'s':''} · Total: ₹${fmt(pr.totalValue)}</span>
          </div>
          <div class="table-wrap">
            <table>
              <thead><tr>
                <th>Item No.</th><th>Material</th><th>Description</th>
                <th>Qty</th><th>UOM</th><th>Unit Price</th><th>Line Total</th>
                <th>Mat. Group</th><th>Preferred Vendor</th>
                ${canEdit ? '<th>Actions</th>' : ''}
              </tr></thead>
              <tbody>
                ${prItems.length === 0 ? `<tr><td colspan="10" style="text-align:center;padding:32px;color:var(--text-muted)">No items yet. Click "+ Add Item" to begin.</td></tr>` :
                  prItems.map(it => `
                  <tr>
                    <td>${it.itemNo}</td>
                    <td><code style="font-size:11px;background:var(--surface-2);padding:2px 6px;border-radius:4px">${it.materialNo}</code></td>
                    <td style="font-weight:500">${it.description}</td>
                    <td>${it.qty}</td><td>${it.uom}</td>
                    <td class="amount">₹${fmt(it.unitPrice)}</td>
                    <td class="amount" style="color:var(--brand-primary);font-weight:700">₹${fmt(it.lineTotal)}</td>
                    <td>${it.materialGroup}</td>
                    <td>${vendorName(it.preferredVendor)}</td>
                    ${canEdit ? `<td><button class="btn btn-secondary btn-sm" onclick="removeItem('${it.itemId}','${prId}')">✕</button></td>` : ''}
                  </tr>`).join('')}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Section: Audit Log -->
      <div class="section-panel" id="panel-audit">
        <div class="card">
          <div class="card-header"><span class="card-title">📋 Approval History & Audit Trail</span></div>
          <div class="table-wrap">
            <table>
              <thead><tr><th>Timestamp</th><th>Action</th><th>Changed By</th><th>From</th><th>To</th><th>Comments</th></tr></thead>
              <tbody>
                ${prLogs.length === 0 ? `<tr><td colspan="6" style="text-align:center;padding:32px;color:var(--text-muted)">No audit entries yet.</td></tr>` :
                  prLogs.map(l => `<tr>
                    <td style="font-size:12px;color:var(--text-muted)">${fmtDate(l.logTimestamp)}</td>
                    <td><span style="font-weight:600;color:var(--brand-primary)">${l.actionTaken}</span></td>
                    <td>${l.changedBy}</td>
                    <td>${statusBadge(l.oldStatus)}</td>
                    <td>${statusBadge(l.newStatus)}</td>
                    <td style="max-width:260px;font-size:12px;color:var(--text-secondary)">${l.comments||'—'}</td>
                  </tr>`).join('')}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Section: Budget -->
      <div class="section-panel" id="panel-budget">
        ${renderBudgetSection(pr, cc)}
      </div>

      <!-- Section: General Info -->
      <div class="section-panel" id="panel-info">
        <div class="card"><div class="card-body">
          <div class="form-grid">
            ${infoRow('PR Number', pr.prExt)}
            ${infoRow('Requester', pr.requester)}
            ${infoRow('Department', pr.department)}
            ${infoRow('Cost Center', pr.costCenter)}
            ${infoRow('Currency', pr.currency)}
            ${infoRow('Priority', `<span class="priority-chip priority-${pr.priority}">${pr.priority}</span>`)}
            ${infoRow('Approver', pr.approver)}
            ${infoRow('Approval Level', pr.approvalLevel === 0 ? 'Auto' : `Level ${pr.approvalLevel}`)}
            ${infoRow('Created', pr.creationDate)}
            ${infoRow('Submitted', pr.submittedAt||'—')}
            ${infoRow('Approved', pr.approvedAt||'—')}
            ${pr.financeApprovedBy ? infoRow('Finance Approved By', pr.financeApprovedBy) : ''}
          </div>
        </div></div>
      </div>
    </div>

    <!-- Add Item Inline Form (hidden by default) -->
    <div id="addItemSection" class="card mt-4" style="display:none">
      <div class="card-header"><span class="card-title">＋ New Line Item</span></div>
      <div class="card-body">
        <div class="form-grid">
          <div class="form-group">
            <label class="form-label required">Material No.</label>
            <input class="form-input" id="ni_matNo" placeholder="e.g. MAT-LAPTOP" />
          </div>
          <div class="form-group">
            <label class="form-label required">Description</label>
            <input class="form-input" id="ni_desc" placeholder="Item description" />
          </div>
          <div class="form-group">
            <label class="form-label required">Quantity</label>
            <input class="form-input" id="ni_qty" type="number" min="0.001" step="any" placeholder="0" oninput="calcLT()" />
          </div>
          <div class="form-group">
            <label class="form-label">UOM</label>
            <select class="form-select" id="ni_uom"><option>EA</option><option>KG</option><option>L</option><option>M</option></select>
          </div>
          <div class="form-group">
            <label class="form-label required">Unit Price (₹)</label>
            <input class="form-input" id="ni_price" type="number" min="0.01" step="any" placeholder="0.00" oninput="calcLT()" />
          </div>
          <div class="form-group">
            <label class="form-label">Line Total (auto)</label>
            <input class="form-input" id="ni_lt" readonly placeholder="0.00" />
          </div>
          <div class="form-group">
            <label class="form-label">Material Group</label>
            <select class="form-select" id="ni_mg" onchange="autoSuggestVendor()">
              <option value="">Select…</option>
              <option>ELECTRONICS</option><option>STATIONERY</option><option>MACHINERY</option><option>SERVICES</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Preferred Vendor (auto-suggested)</label>
            <input class="form-input" id="ni_vendor" placeholder="Auto-filled from material group" />
          </div>
        </div>
        <div class="flex gap-2 mt-4">
          <button class="btn btn-primary" onclick="saveNewItem('${prId}')">Save Item</button>
          <button class="btn btn-secondary" onclick="document.getElementById('addItemSection').style.display='none'">Cancel</button>
        </div>
      </div>
    </div>
  `;
}

function infoRow(label, value) {
  return `<div class="form-group"><label class="form-label">${label}</label><div style="padding:9px 12px;background:var(--surface-2);border-radius:var(--radius-sm);font-size:13px">${value}</div></div>`;
}

function renderBudgetSection(pr, cc) {
  if (!cc) return `<div class="card"><div class="card-body"><p style="color:var(--text-muted)">No budget record found for cost center ${pr.costCenter}.</p></div></div>`;
  const pct     = (cc.consumedBudget / cc.totalBudget * 100).toFixed(1);
  const canAfford = cc.remainingBudget >= pr.totalValue;
  const cls     = pct > 90 ? 'bad' : pct > 70 ? 'warn' : '';

  return `
    <div class="budget-section">
      <div class="budget-card card">
        <div class="budget-header">
          <span class="budget-label">Cost Center: ${cc.costCenter} — ${cc.department}</span>
          <span class="text-sm text-muted">Period: ${cc.budgetPeriod}</span>
        </div>
        <div class="budget-amounts">
          <div class="budget-item"><div class="budget-item-label">Total Budget</div><div class="budget-item-value">₹${fmt(cc.totalBudget)}</div></div>
          <div class="budget-item"><div class="budget-item-label">Consumed</div><div class="budget-item-value ${cls}">₹${fmt(cc.consumedBudget)}</div></div>
          <div class="budget-item"><div class="budget-item-label">Remaining</div><div class="budget-item-value ${canAfford?'ok':'bad'}">₹${fmt(cc.remainingBudget)}</div></div>
        </div>
        <div class="budget-bar-wrap">
          <div class="budget-bar-fill ${cls}" style="width:${Math.min(pct,100)}%"></div>
        </div>
        <div style="margin-top:6px;font-size:11px;color:var(--text-muted)">${pct}% consumed</div>
        <div class="pr-vs-budget ${canAfford?'ok':'bad'}">
          ${canAfford ? '✅' : '❌'}
          This PR (₹${fmt(pr.totalValue)}) is ${canAfford ? 'within' : 'OVER'} the remaining budget of ₹${fmt(cc.remainingBudget)}.
          ${!canAfford ? ' <strong>Submission will be blocked.</strong>' : ''}
        </div>
      </div>
    </div>`;
}

function switchTab(name) {
  ['items','audit','budget','info'].forEach(t => {
    document.getElementById(`tab-${t}`)?.classList.toggle('active', t===name);
    document.getElementById(`panel-${t}`)?.classList.toggle('active', t===name);
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE PR
// ─────────────────────────────────────────────────────────────────────────────
function renderCreatePR() {
  document.getElementById('mainContent').innerHTML = `
    <div class="page-header">
      <div>
        <div class="page-title">Create Purchase Requisition</div>
        <div class="page-subtitle">Fill in header details, then add items</div>
      </div>
      <button class="btn btn-secondary" onclick="navigate('#list')">← Cancel</button>
    </div>
    <div class="card">
      <div class="card-header"><span class="card-title">PR Header</span></div>
      <div class="card-body">
        <div class="form-grid">
          <div class="form-group">
            <label class="form-label required">Department</label>
            <select class="form-select" id="c_dept">
              <option>IT</option><option>Operations</option><option>Finance</option><option>HR</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label required">Cost Center</label>
            <select class="form-select" id="c_cc">
              ${DB.costCenters.map(cc => `<option value="${cc.costCenter}">${cc.costCenter} — ${cc.department}</option>`).join('')}
            </select>
          </div>
          <div class="form-group">
            <label class="form-label required">Priority</label>
            <select class="form-select" id="c_priority">
              <option>Low</option><option selected>Medium</option><option>High</option><option>Critical</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Approver (username)</label>
            <input class="form-input" id="c_approver" placeholder="e.g. MANAGER1" value="MANAGER1" />
          </div>
        </div>
        <div class="flex gap-2 mt-4">
          <button class="btn btn-primary" onclick="saveDraftPR()">Save as Draft</button>
        </div>
      </div>
    </div>`;
}

function saveDraftPR() {
  const dept     = document.getElementById('c_dept').value;
  const cc       = document.getElementById('c_cc').value;
  const priority = document.getElementById('c_priority').value;
  const approver = document.getElementById('c_approver').value.trim();
  if (!approver) { toast('Please enter an approver username', 'error'); return; }

  const today = new Date().toISOString().slice(0,10);
  const prId  = uid();
  const prExt = `PR-${today.replace(/-/g,'')}-${Math.floor(10000+Math.random()*90000)}`;

  DB.prs.push({
    prId, prExt, requester: currentUser, department: dept, costCenter: cc,
    creationDate: today, totalValue: 0, currency:'INR',
    status: STATUS.DRAFT, approver, priority,
    approvalLevel: 0, financeApprovedBy:'', rejectionComment:'',
    submittedAt:'', approvedAt:''
  });

  toast(`PR ${prExt} created as Draft`, 'success');
  navigate(`#pr/${prId}`);
}

// ─────────────────────────────────────────────────────────────────────────────
// ITEM MANAGEMENT
// ─────────────────────────────────────────────────────────────────────────────
function renderAddItemForm(prId) {
  document.getElementById('addItemSection').style.display = 'block';
  document.getElementById('addItemSection').scrollIntoView({ behavior:'smooth' });
}

function calcLT() {
  const q = parseFloat(document.getElementById('ni_qty')?.value) || 0;
  const p = parseFloat(document.getElementById('ni_price')?.value) || 0;
  const el = document.getElementById('ni_lt');
  if (el) el.value = fmt(q * p);
}

function autoSuggestVendor() {
  const mg = document.getElementById('ni_mg')?.value;
  const v  = DB.vendors.find(v => v.materialGroup === mg && v.isPreferred);
  const el = document.getElementById('ni_vendor');
  if (el && v) el.value = `${v.vendorId} — ${v.vendorName}`;
  else if (el) el.value = '';
}

function saveNewItem(prId) {
  const matNo  = document.getElementById('ni_matNo').value.trim();
  const desc   = document.getElementById('ni_desc').value.trim();
  const qty    = parseFloat(document.getElementById('ni_qty').value);
  const uom    = document.getElementById('ni_uom').value;
  const price  = parseFloat(document.getElementById('ni_price').value);
  const mg     = document.getElementById('ni_mg').value;
  const vInput = document.getElementById('ni_vendor').value;
  const vendor = vInput.split('—')[0].trim();

  // Validation (mirrors ValidateQuantityPrice)
  if (!matNo) { toast('Material No. is mandatory', 'error'); return; }
  if (!desc)  { toast('Description is mandatory', 'error'); return; }
  if (isNaN(qty) || qty <= 0) { toast('Quantity must be > 0', 'error'); return; }
  if (isNaN(price) || price <= 0) { toast('Unit Price must be > 0', 'error'); return; }

  const lineTotal = qty * price;
  const pr = DB.prs.find(p => p.prId === prId);
  const existItems = DB.items.filter(i => i.prId === prId);
  const itemNo = String(10 * (existItems.length + 1)).padStart(5,'0');

  DB.items.push({
    itemId: uid(), prId, itemNo, materialNo: matNo, description: desc,
    qty, uom, unitPrice: price, currency:'INR', lineTotal,
    materialGroup: mg, preferredVendor: vendor
  });

  // Determination: recalculate PR total
  recalcPRTotal(prId);

  document.getElementById('addItemSection').style.display = 'none';
  toast(`Item "${desc}" added — Line Total: ₹${fmt(lineTotal)}`, 'success');
  renderObjectPage(prId);  // re-render
}

function removeItem(itemId, prId) {
  DB.items = DB.items.filter(i => i.itemId !== itemId);
  recalcPRTotal(prId);
  toast('Item removed', 'info');
  renderObjectPage(prId);
}

function recalcPRTotal(prId) {
  const total = DB.items.filter(i => i.prId === prId).reduce((s,i) => s + i.lineTotal, 0);
  const pr = DB.prs.find(p => p.prId === prId);
  if (pr) pr.totalValue = total;
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIONS — mirrors the ABAP behavior implementation
// ─────────────────────────────────────────────────────────────────────────────

// ── Submit ──────────────────────────────────────────────────────────────────
function actionSubmit(prId) {
  const pr    = DB.prs.find(p => p.prId === prId);
  const items = DB.items.filter(i => i.prId === prId);

  // Validation: at least one item (ValidateItems)
  if (items.length === 0) {
    toast('❌ A PR must have at least one item before submitting.', 'error'); return;
  }

  // Validation: budget check
  const period = currentPeriod();
  const cc = DB.costCenters.find(c => c.costCenter === pr.costCenter && c.budgetPeriod === period);
  if (!cc) {
    toast(`❌ No budget record found for ${pr.costCenter} / ${period}`, 'error'); return;
  }
  if (cc.remainingBudget < pr.totalValue) {
    toast(`❌ Budget insufficient! Remaining: ₹${fmt(cc.remainingBudget)} | PR Total: ₹${fmt(pr.totalValue)}`, 'error'); return;
  }

  // Approval routing logic
  const oldStatus = pr.status;
  let newStatus, level;
  if (pr.totalValue < THRESHOLD_AUTO) {
    newStatus = STATUS.APPROVED; level = 0;
    pr.approvedAt = today();
    // Auto-approve deducts budget immediately
    cc.consumedBudget  += pr.totalValue;
    cc.remainingBudget -= pr.totalValue;
  } else if (pr.totalValue <= THRESHOLD_FINANCE) {
    newStatus = STATUS.PENDING; level = 1;
  } else {
    newStatus = STATUS.PENDING; level = 2;
  }

  pr.status        = newStatus;
  pr.approvalLevel = level;
  pr.submittedAt   = today();

  writeAuditLog(prId, oldStatus, newStatus, 'Submit',
    level === 0 ? `Auto-approved: ₹${fmt(pr.totalValue)} < threshold ₹${fmt(THRESHOLD_AUTO)}`
                : `Routed to approval level ${level}`);

  toast(level === 0 ? '✅ PR auto-approved! (value below ₹50,000)' : `🚀 PR submitted — routed to Level ${level} approval`, 'success');
  renderObjectPage(prId);
}

// ── Approve ──────────────────────────────────────────────────────────────────
function actionApprove(prId) {
  openModal('Approve Purchase Requisition',
    `<div class="form-group">
      <label class="form-label">Approval Comment (optional)</label>
      <textarea class="form-textarea" id="m_comment" placeholder="Add a comment…"></textarea>
    </div>`,
    [
      { label:'Confirm Approve', cls:'btn-success', action: () => {
        const pr  = DB.prs.find(p => p.prId === prId);
        const cc  = getCostCenter(pr.costCenter);
        const comment = document.getElementById('m_comment').value || `Approved by ${currentUser}`;
        const oldStatus = pr.status;

        if (pr.approvalLevel === 2 && !pr.financeApprovedBy) {
          // Multi-step: first approval (manager), now needs finance
          pr.financeApprovedBy = currentUser;
          writeAuditLog(prId, oldStatus, STATUS.PENDING, 'Approve', `Manager approved. Awaiting Finance. ${comment}`);
          toast('✅ Manager approval recorded. Awaiting Finance Approver.', 'success');
        } else {
          // Final approval
          pr.status    = STATUS.APPROVED;
          pr.approvedAt = today();
          if (pr.financeApprovedBy === '' && pr.approvalLevel === 2) pr.financeApprovedBy = currentUser;
          // Deduct budget
          if (cc) {
            cc.consumedBudget  += pr.totalValue;
            cc.remainingBudget -= pr.totalValue;
          }
          writeAuditLog(prId, oldStatus, STATUS.APPROVED, 'Approve', comment);
          toast(`✅ PR Approved! Budget deducted: ₹${fmt(pr.totalValue)} from ${pr.costCenter}`, 'success');
        }
        closeModal(); renderObjectPage(prId);
      }},
      { label:'Cancel', cls:'btn-secondary', action: closeModal }
    ]
  );
}

// ── Reject ───────────────────────────────────────────────────────────────────
function actionReject(prId) {
  openModal('Reject Purchase Requisition',
    `<div class="form-group">
      <label class="form-label required">Rejection Reason (mandatory)</label>
      <textarea class="form-textarea" id="m_reason" placeholder="Provide a clear reason for rejection…"></textarea>
      <span class="form-hint">This reason will be visible to the requester.</span>
    </div>`,
    [
      { label:'Confirm Reject', cls:'btn-danger', action: () => {
        const reason = document.getElementById('m_reason').value.trim();
        if (!reason) { toast('❌ Rejection reason is mandatory.', 'error'); return; }

        const pr = DB.prs.find(p => p.prId === prId);
        const old = pr.status;
        pr.status = STATUS.REJECTED;
        pr.rejectionComment = reason;
        writeAuditLog(prId, old, STATUS.REJECTED, 'Reject', reason);
        toast('❌ PR Rejected.', 'warning');
        closeModal(); renderObjectPage(prId);
      }},
      { label:'Cancel', cls:'btn-secondary', action: closeModal }
    ]
  );
}

// ── Delegate ─────────────────────────────────────────────────────────────────
function actionDelegate(prId) {
  openModal('Delegate Approval',
    `<div class="form-group">
      <label class="form-label required">Substitute Approver (username)</label>
      <input class="form-input" id="m_sub" placeholder="e.g. MANAGER2" />
    </div>
    <div class="form-group mt-3">
      <label class="form-label">Reason for Delegation</label>
      <input class="form-input" id="m_dreason" placeholder="e.g. On leave until Monday" />
    </div>`,
    [
      { label:'Delegate', cls:'btn-warning', action: () => {
        const sub = document.getElementById('m_sub').value.trim();
        if (!sub) { toast('❌ Substitute approver is required.', 'error'); return; }

        const pr  = DB.prs.find(p => p.prId === prId);
        const old = pr.approver;
        pr.approver = sub;
        const reason = document.getElementById('m_dreason').value || '';
        writeAuditLog(prId, pr.status, pr.status, 'Delegate', `Delegated from ${old} to ${sub}. ${reason}`);
        toast(`🔄 Approval delegated to ${sub}`, 'info');
        closeModal(); renderObjectPage(prId);
      }},
      { label:'Cancel', cls:'btn-secondary', action: closeModal }
    ]
  );
}

// ── Withdraw ─────────────────────────────────────────────────────────────────
function actionWithdraw(prId) {
  openModal('Withdraw Requisition',
    `<p style="color:var(--text-secondary);font-size:14px">Are you sure you want to withdraw this PR? It will be marked as <strong>Closed</strong> and cannot be resubmitted.</p>`,
    [
      { label:'Withdraw', cls:'btn-danger', action: () => {
        const pr  = DB.prs.find(p => p.prId === prId);
        const old = pr.status;
        pr.status = STATUS.CLOSED;
        writeAuditLog(prId, old, STATUS.CLOSED, 'Withdraw', 'Withdrawn by requester');
        toast('↩ PR Withdrawn', 'warning');
        closeModal(); renderObjectPage(prId);
      }},
      { label:'Cancel', cls:'btn-secondary', action: closeModal }
    ]
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ANALYTICS PAGE
// ─────────────────────────────────────────────────────────────────────────────
function renderAnalytics() {
  const all    = DB.prs;
  const pending = all.filter(p => p.status === STATUS.PENDING).length;
  const approved= all.filter(p => p.status === STATUS.APPROVED).length;
  const total   = all.reduce((s,p) => s + p.totalValue, 0);

  const byStatus = Object.values(STATUS).map(s => ({ s, count: all.filter(p=>p.status===s).length })).filter(x=>x.count>0);
  const maxCount = Math.max(...byStatus.map(x=>x.count),1);

  const statusColors = {
    [STATUS.DRAFT]: '#6c757d', [STATUS.SUBMITTED]:'#0070f2', [STATUS.PENDING]:'#e67e00',
    [STATUS.APPROVED]:'#107e3e', [STATUS.REJECTED]:'#bb0000', [STATUS.CLOSED]:'#9e9e9e'
  };

  document.getElementById('mainContent').innerHTML = `
    <div class="page-header"><div>
      <div class="page-title">Analytics Dashboard</div>
      <div class="page-subtitle">Procurement KPIs for ${currentUser}</div>
    </div></div>

    <div class="kpi-grid">
      <div class="kpi-tile">
        <div class="kpi-tile-icon">⏳</div>
        <div class="kpi-tile-value" style="color:var(--status-pending)">${pending}</div>
        <div class="kpi-tile-label">Pending Approvals</div>
        <div class="kpi-tile-sub">Awaiting action</div>
      </div>
      <div class="kpi-tile">
        <div class="kpi-tile-icon">✅</div>
        <div class="kpi-tile-value" style="color:var(--status-approved)">${approved}</div>
        <div class="kpi-tile-label">Approved PRs</div>
        <div class="kpi-tile-sub">This period</div>
      </div>
      <div class="kpi-tile">
        <div class="kpi-tile-icon">📄</div>
        <div class="kpi-tile-value">${all.length}</div>
        <div class="kpi-tile-label">Total PRs</div>
        <div class="kpi-tile-sub">All statuses</div>
      </div>
      <div class="kpi-tile">
        <div class="kpi-tile-icon">💰</div>
        <div class="kpi-tile-value" style="color:var(--brand-primary);font-size:24px">₹${fmt(total)}</div>
        <div class="kpi-tile-label">Total PR Value</div>
        <div class="kpi-tile-sub">Across all PRs</div>
      </div>
    </div>

    <div class="card mb-4">
      <div class="card-header"><span class="card-title">📊 PRs by Status</span></div>
      <div class="card-body">
        <div class="chart-bars">
          ${byStatus.map(x => `
            <div class="chart-row">
              <div class="chart-row-label">${x.s}</div>
              <div class="chart-bar-bg">
                <div class="chart-bar-fill" style="width:${(x.count/maxCount*100)}%;background:${statusColors[x.s]||'#888'}">${x.count}</div>
              </div>
              <div class="chart-row-count">${x.count}</div>
            </div>`).join('')}
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-header"><span class="card-title">💰 Budget Utilisation</span></div>
      <div class="card-body">
        <div class="chart-bars">
          ${DB.costCenters.map(cc => {
            const pct = (cc.consumedBudget/cc.totalBudget*100).toFixed(1);
            const cls = pct > 90 ? '#bb0000' : pct > 70 ? '#e67e00' : '#107e3e';
            return `
              <div class="chart-row">
                <div class="chart-row-label">${cc.costCenter} (${cc.department})</div>
                <div class="chart-bar-bg">
                  <div class="chart-bar-fill" style="width:${pct}%;background:${cls}">${pct}%</div>
                </div>
                <div class="chart-row-count" style="width:100px;font-size:11px">₹${fmt(cc.remainingBudget)} left</div>
              </div>`;
          }).join('')}
        </div>
      </div>
    </div>
  `;
}

// ─────────────────────────────────────────────────────────────────────────────
// AUDIT LOG HELPER
// ─────────────────────────────────────────────────────────────────────────────
function writeAuditLog(prId, oldStatus, newStatus, action, comments='') {
  DB.auditLog.push({
    logId: uid(), prId,
    logTimestamp: new Date().toISOString(),
    changedBy: currentUser, oldStatus, newStatus, actionTaken: action, comments
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// MODAL
// ─────────────────────────────────────────────────────────────────────────────
function openModal(title, bodyHtml, buttons) {
  document.getElementById('modalTitle').textContent = title;
  document.getElementById('modalBody').innerHTML    = bodyHtml;
  document.getElementById('modalFooter').innerHTML  = buttons.map((b,i) =>
    `<button class="btn ${b.cls}" id="mbtn${i}">${b.label}</button>`
  ).join('');
  buttons.forEach((b,i) => document.getElementById(`mbtn${i}`).onclick = b.action);
  document.getElementById('modalOverlay').classList.remove('hidden');
}
function closeModal() { document.getElementById('modalOverlay').classList.add('hidden'); }

// ─────────────────────────────────────────────────────────────────────────────
// TOAST
// ─────────────────────────────────────────────────────────────────────────────
function toast(msg, type='info') {
  const map = { success:'toast-success', error:'toast-error', warning:'toast-warning', info:'toast-info' };
  const icons = { success:'✅', error:'❌', warning:'⚠️', info:'ℹ️' };
  const el = document.createElement('div');
  el.className = `toast ${map[type]||'toast-info'}`;
  el.innerHTML = `<span>${icons[type]||'ℹ️'}</span><span>${msg}</span>`;
  document.getElementById('toastContainer').appendChild(el);
  setTimeout(() => el.remove(), 4000);
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
function uid() { return Math.random().toString(36).slice(2) + Date.now().toString(36); }
function fmt(n) { return Number(n).toLocaleString('en-IN', { minimumFractionDigits:0, maximumFractionDigits:2 }); }
function today() { return new Date().toISOString().slice(0,10); }
function currentPeriod() { const d=new Date(); return `${d.getFullYear()}/${String(d.getMonth()+1).padStart(2,'0')}`; }
function fmtDate(ts) { return ts ? new Date(ts).toLocaleString('en-IN') : '—'; }
function vendorName(id) { const v = DB.vendors.find(v=>v.vendorId===id); return v ? `${id} — ${v.vendorName}` : id||'—'; }
function getCostCenter(id) { const p=currentPeriod(); return DB.costCenters.find(c=>c.costCenter===id && c.budgetPeriod===p) || DB.costCenters.find(c=>c.costCenter===id); }

function statusBadge(s) {
  const map = {
    [STATUS.DRAFT]:    'draft',    [STATUS.SUBMITTED]: 'submitted',
    [STATUS.PENDING]:  'pending',  [STATUS.APPROVED]:  'approved',
    [STATUS.REJECTED]: 'rejected', [STATUS.CLOSED]:    'closed'
  };
  return `<span class="badge badge-${map[s]||'draft'}">${s}</span>`;
}

// ─────────────────────────────────────────────────────────────────────────────
// USER DROPDOWN TOGGLE
// ─────────────────────────────────────────────────────────────────────────────
document.getElementById('userPill').addEventListener('click', e => {
  document.getElementById('userPill').classList.toggle('open');
  e.stopPropagation();
});
document.addEventListener('click', () => {
  document.getElementById('userPill').classList.remove('open');
});

// ─────────────────────────────────────────────────────────────────────────────
// BOOT
// ─────────────────────────────────────────────────────────────────────────────
seedData();
window.addEventListener('hashchange', router);
router();
