*==========================================================================
* Test Data Insertion Script — ProcureFlow
* Run this as an ABAP program (SE38 / ADT) after activating all objects.
*
* Creates:
*   - 3 Vendors
*   - 2 Cost Centers with budgets
*   - 4 PRs in different statuses (Draft, Pending, Approved, Rejected)
*   - Items for each PR
*   - Sample audit log entries
*==========================================================================
REPORT zprocureflow_test_data.

START-OF-SELECTION.
  PERFORM insert_vendors.
  PERFORM insert_cost_centers.
  PERFORM insert_prs.
  COMMIT WORK AND WAIT.
  WRITE: / 'Test data inserted successfully.'.

*==========================================================================
* FORM: Insert Vendors
*==========================================================================
FORM insert_vendors.
  DATA lt_vendors TYPE TABLE OF zvendor_m.

  lt_vendors = VALUE #(
    client         = sy-mandt
    (
      vendor_id      = 'VND001'
      vendor_name    = 'TechSupply India Pvt Ltd'
      material_group = 'ELECTRONICS'
      last_used_date = '20250601'
      unit_price     = '1500.00'
      currency       = 'INR'
      country        = 'IN'
      contact_email  = 'procurement@techsupply.in'
      is_preferred   = abap_true
    )
    (
      vendor_id      = 'VND002'
      vendor_name    = 'Office Essentials Co.'
      material_group = 'STATIONERY'
      last_used_date = '20250515'
      unit_price     = '50.00'
      currency       = 'INR'
      country        = 'IN'
      contact_email  = 'orders@officeessentials.in'
      is_preferred   = abap_true
    )
    (
      vendor_id      = 'VND003'
      vendor_name    = 'Industrial Parts Ltd'
      material_group = 'MACHINERY'
      last_used_date = '20250401'
      unit_price     = '25000.00'
      currency       = 'INR'
      country        = 'IN'
      contact_email  = 'supply@industrialparts.in'
      is_preferred   = abap_false
    )
  ).

  DELETE FROM zvendor_m WHERE client = @sy-mandt.   "clean slate
  INSERT zvendor_m FROM TABLE @lt_vendors.
ENDFORM.

*==========================================================================
* FORM: Insert Cost Centers
*==========================================================================
FORM insert_cost_centers.
  DATA lt_cc TYPE TABLE OF zcostctr_b.
  DATA(lv_period) = |{ sy-datum+0(4) }/{ sy-datum+4(2) }|.

  lt_cc = VALUE #(
    client  = sy-mandt
    (
      cost_center      = 'CC_IT'
      budget_period    = lv_period
      total_budget     = '2000000.00'
      consumed_budget  = '350000.00'
      remaining_budget = '1650000.00'
      currency         = 'INR'
      department       = 'IT'
      last_changed_at  = utclong_current( )
    )
    (
      cost_center      = 'CC_OPS'
      budget_period    = lv_period
      total_budget     = '1000000.00'
      consumed_budget  = '800000.00'
      remaining_budget = '200000.00'
      currency         = 'INR'
      department       = 'OPERATIONS'
      last_changed_at  = utclong_current( )
    )
  ).

  DELETE FROM zcostctr_b WHERE client = @sy-mandt.
  INSERT zcostctr_b FROM TABLE @lt_cc.
ENDFORM.

*==========================================================================
* FORM: Insert PRs, Items, and Audit Log entries
*==========================================================================
FORM insert_prs.
  DATA lt_hdrs  TYPE TABLE OF zpur_reqhdr.
  DATA lt_items TYPE TABLE OF zpur_reqitm.
  DATA lt_logs  TYPE TABLE OF zpur_auditlog.

  " Generate UUIDs for PR headers
  DATA: lv_pr1 TYPE sysuuid_x16, lv_pr2 TYPE sysuuid_x16,
        lv_pr3 TYPE sysuuid_x16, lv_pr4 TYPE sysuuid_x16.

  TRY.
      lv_pr1 = cl_system_uuid=>create_uuid_x16_static( ).
      lv_pr2 = cl_system_uuid=>create_uuid_x16_static( ).
      lv_pr3 = cl_system_uuid=>create_uuid_x16_static( ).
      lv_pr4 = cl_system_uuid=>create_uuid_x16_static( ).
    CATCH cx_uuid_error.
      WRITE: / 'UUID generation failed'.
      RETURN.
  ENDTRY.

  " -----------------------------------------------------------------------
  " PR 1: Draft — IT dept, low value, no items submitted yet
  " -----------------------------------------------------------------------
  APPEND VALUE #(
    client                = sy-mandt
    prid                  = lv_pr1
    prid_external         = 'PR-20250701-10001'
    requester             = 'REQUESTER1'
    department            = 'IT'
    cost_center           = 'CC_IT'
    creation_date         = sy-datum
    total_value           = '30000.00'
    currency              = 'INR'
    status                = 'Draft'
    approver              = 'MANAGER1'
    priority              = 'Medium'
    approval_level        = 0
    local_last_changed_at = utclong_current( )
    last_changed_by       = 'REQUESTER1'
  ) TO lt_hdrs.

  " -----------------------------------------------------------------------
  " PR 2: PendingApproval — IT dept, mid value (₹1,20,000), needs manager
  " -----------------------------------------------------------------------
  APPEND VALUE #(
    client                = sy-mandt
    prid                  = lv_pr2
    prid_external         = 'PR-20250702-10002'
    requester             = 'REQUESTER1'
    department            = 'IT'
    cost_center           = 'CC_IT'
    creation_date         = sy-datum - 2
    total_value           = '120000.00'
    currency              = 'INR'
    status                = 'PendingApproval'
    approver              = 'MANAGER1'
    priority              = 'High'
    approval_level        = 1
    submitted_at          = sy-datum - 1
    local_last_changed_at = utclong_current( )
    last_changed_by       = 'REQUESTER1'
  ) TO lt_hdrs.

  " -----------------------------------------------------------------------
  " PR 3: Approved — Operations, low value (₹45,000), auto-approved
  " -----------------------------------------------------------------------
  APPEND VALUE #(
    client                = sy-mandt
    prid                  = lv_pr3
    prid_external         = 'PR-20250703-10003'
    requester             = 'REQUESTER2'
    department            = 'OPERATIONS'
    cost_center           = 'CC_OPS'
    creation_date         = sy-datum - 5
    total_value           = '45000.00'
    currency              = 'INR'
    status                = 'Approved'
    approver              = 'SYSTEM'
    priority              = 'Low'
    approval_level        = 0
    submitted_at          = sy-datum - 4
    approved_at           = sy-datum - 4
    local_last_changed_at = utclong_current( )
    last_changed_by       = 'SYSTEM'
  ) TO lt_hdrs.

  " -----------------------------------------------------------------------
  " PR 4: Rejected — Operations, finance-level (₹6,00,000), rejected
  " -----------------------------------------------------------------------
  APPEND VALUE #(
    client                = sy-mandt
    prid                  = lv_pr4
    prid_external         = 'PR-20250704-10004'
    requester             = 'REQUESTER2'
    department            = 'OPERATIONS'
    cost_center           = 'CC_OPS'
    creation_date         = sy-datum - 10
    total_value           = '600000.00'
    currency              = 'INR'
    status                = 'Rejected'
    approver              = 'MANAGER2'
    priority              = 'Critical'
    approval_level        = 2
    rejection_comment     = 'Budget overrun: Operations already at 80% consumption.'
    submitted_at          = sy-datum - 8
    local_last_changed_at = utclong_current( )
    last_changed_by       = 'MANAGER2'
  ) TO lt_hdrs.

  " -----------------------------------------------------------------------
  " Items for PR1
  " -----------------------------------------------------------------------
  APPEND VALUE #(
    client = sy-mandt  prid = lv_pr1
    item_uuid = cl_system_uuid=>create_uuid_x16_static( )
    item_no = '00010'  material_no = 'MAT-LAPTOP'
    description = 'Laptop - Dell XPS 15'
    quantity = '2.000'  unit_of_measure = 'EA'
    unit_price = '75000.00'  currency = 'INR'
    line_total = '150000.00'
    material_group = 'ELECTRONICS'  preferred_vendor = 'VND001'
    local_last_changed_at = utclong_current( )
  ) TO lt_items.

  " Items for PR2
  APPEND VALUE #(
    client = sy-mandt  prid = lv_pr2
    item_uuid = cl_system_uuid=>create_uuid_x16_static( )
    item_no = '00010'  material_no = 'MAT-MONITOR'
    description = '27" 4K Monitor'
    quantity = '3.000'  unit_of_measure = 'EA'
    unit_price = '25000.00'  currency = 'INR'
    line_total = '75000.00'
    material_group = 'ELECTRONICS'  preferred_vendor = 'VND001'
    local_last_changed_at = utclong_current( )
  ) TO lt_items.
  APPEND VALUE #(
    client = sy-mandt  prid = lv_pr2
    item_uuid = cl_system_uuid=>create_uuid_x16_static( )
    item_no = '00020'  material_no = 'MAT-KEYBOARD'
    description = 'Mechanical Keyboard x5'
    quantity = '5.000'  unit_of_measure = 'EA'
    unit_price = '9000.00'  currency = 'INR'
    line_total = '45000.00'
    material_group = 'ELECTRONICS'  preferred_vendor = 'VND001'
    local_last_changed_at = utclong_current( )
  ) TO lt_items.

  " Items for PR3
  APPEND VALUE #(
    client = sy-mandt  prid = lv_pr3
    item_uuid = cl_system_uuid=>create_uuid_x16_static( )
    item_no = '00010'  material_no = 'MAT-A4PAPER'
    description = 'A4 Printer Paper (Ream x50)'
    quantity = '50.000'  unit_of_measure = 'EA'
    unit_price = '500.00'  currency = 'INR'
    line_total = '25000.00'
    material_group = 'STATIONERY'  preferred_vendor = 'VND002'
    local_last_changed_at = utclong_current( )
  ) TO lt_items.
  APPEND VALUE #(
    client = sy-mandt  prid = lv_pr3
    item_uuid = cl_system_uuid=>create_uuid_x16_static( )
    item_no = '00020'  material_no = 'MAT-PEN'
    description = 'Ballpoint Pens (Box x12)'
    quantity = '20.000'  unit_of_measure = 'EA'
    unit_price = '100.00'  currency = 'INR'
    line_total = '2000.00'
    material_group = 'STATIONERY'  preferred_vendor = 'VND002'
    local_last_changed_at = utclong_current( )
  ) TO lt_items.

  " Items for PR4
  APPEND VALUE #(
    client = sy-mandt  prid = lv_pr4
    item_uuid = cl_system_uuid=>create_uuid_x16_static( )
    item_no = '00010'  material_no = 'MAT-CONVEYOR'
    description = 'Conveyor Belt Motor Unit'
    quantity = '3.000'  unit_of_measure = 'EA'
    unit_price = '200000.00'  currency = 'INR'
    line_total = '600000.00'
    material_group = 'MACHINERY'  preferred_vendor = 'VND003'
    local_last_changed_at = utclong_current( )
  ) TO lt_items.

  " -----------------------------------------------------------------------
  " Audit Log Entries
  " -----------------------------------------------------------------------
  " PR2: Submitted → PendingApproval
  APPEND VALUE #(
    client        = sy-mandt  prid = lv_pr2
    log_id        = cl_system_uuid=>create_uuid_x16_static( )
    log_timestamp = utclong_current( ) - 86400   "1 day ago
    changed_by    = 'REQUESTER1'
    old_status    = 'Draft'
    new_status    = 'PendingApproval'
    action_taken  = 'Submit'
    comments      = 'Routed to approval level 1'
  ) TO lt_logs.

  " PR3: Auto-approved
  APPEND VALUE #(
    client        = sy-mandt  prid = lv_pr3
    log_id        = cl_system_uuid=>create_uuid_x16_static( )
    log_timestamp = utclong_current( ) - 432000  "5 days ago
    changed_by    = 'SYSTEM'
    old_status    = 'Draft'
    new_status    = 'Approved'
    action_taken  = 'Submit'
    comments      = 'Auto-approved: value below threshold of INR 50,000'
  ) TO lt_logs.

  " PR4: Submitted
  APPEND VALUE #(
    client        = sy-mandt  prid = lv_pr4
    log_id        = cl_system_uuid=>create_uuid_x16_static( )
    log_timestamp = utclong_current( ) - 691200  "8 days ago
    changed_by    = 'REQUESTER2'
    old_status    = 'Draft'
    new_status    = 'PendingApproval'
    action_taken  = 'Submit'
    comments      = 'Routed to approval level 2 (Finance)'
  ) TO lt_logs.

  " PR4: Rejected
  APPEND VALUE #(
    client        = sy-mandt  prid = lv_pr4
    log_id        = cl_system_uuid=>create_uuid_x16_static( )
    log_timestamp = utclong_current( ) - 604800  "7 days ago
    changed_by    = 'MANAGER2'
    old_status    = 'PendingApproval'
    new_status    = 'Rejected'
    action_taken  = 'Reject'
    comments      = 'Budget overrun: Operations already at 80% consumption.'
  ) TO lt_logs.

  " Persist all records
  DELETE FROM zpur_reqhdr WHERE client = @sy-mandt.
  DELETE FROM zpur_reqitm  WHERE client = @sy-mandt.
  DELETE FROM zpur_auditlog WHERE client = @sy-mandt.

  INSERT zpur_reqhdr  FROM TABLE @lt_hdrs.
  INSERT zpur_reqitm  FROM TABLE @lt_items.
  INSERT zpur_auditlog FROM TABLE @lt_logs.

ENDFORM.

* Added: test data for multi-currency PRs (USD, EUR, GBP scenarios)
