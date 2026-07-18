"==========================================================================
" LOCAL CLASS IMPLEMENTATIONS — ZBP_PURCHASEREQUISITION
"
" All business logic lives here. Methods are intentionally verbose with
" comments so this code can be explained in a technical interview.
"==========================================================================

"--------------------------------------------------------------------------
" ROOT HANDLER: lhc_purchaserequisition
"--------------------------------------------------------------------------
CLASS lhc_purchaserequisition IMPLEMENTATION.

  "==========================================================================
  " DETERMINATION: SetInitialStatus
  " Triggered on CREATE. Sets Status = 'Draft' and records creation date.
  "==========================================================================
  METHOD set_initial_status.
    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition
        FIELDS ( Status CreationDate Requester )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_pr).

    DATA lt_update TYPE TABLE FOR UPDATE ZI_PurchaseRequisition\\PurchaseRequisition.

    LOOP AT lt_pr INTO DATA(ls_pr).
      " Only set status if not already set (avoids overwriting on re-trigger)
      IF ls_pr-Status IS INITIAL.
        APPEND VALUE #(
          %tky         = ls_pr-%tky
          Status       = lcl_constants=>c_status_draft
          CreationDate = cl_abap_context_info=>get_system_date( )
          Requester    = cl_abap_context_info=>get_user_alias( )
          %control = VALUE #(
            Status       = if_abap_behv=>mk-on
            CreationDate = if_abap_behv=>mk-on
            Requester    = if_abap_behv=>mk-on )
        ) TO lt_update.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition UPDATE FROM lt_update
      REPORTED DATA(lt_rep)
      FAILED DATA(lt_failed)
      MAPPED DATA(lt_mapped).
  ENDMETHOD.

  "==========================================================================
  " DETERMINATION: SetPrIdExternal
  " Generates a human-readable PR number: PR-YYYYMMDD-NNNNN
  "==========================================================================
  METHOD set_pr_id_external.
    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition
        FIELDS ( PrIdExternal )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_pr).

    DATA lt_update TYPE TABLE FOR UPDATE ZI_PurchaseRequisition\\PurchaseRequisition.

    LOOP AT lt_pr INTO DATA(ls_pr).
      IF ls_pr-PrIdExternal IS INITIAL.
        " Build PR number: PR-YYYYMMDD + 5-digit random suffix
        DATA(lv_date)   = cl_abap_context_info=>get_system_date( ).
        DATA(lv_random) = cl_abap_random_int=>create(
                            seed = CONV i( sy-uzeit )
                          )->get_next( min = 10000 max = 99999 ).

        APPEND VALUE #(
          %tky         = ls_pr-%tky
          PrIdExternal = |PR-{ lv_date }-{ lv_random }|
          %control     = VALUE #( PrIdExternal = if_abap_behv=>mk-on )
        ) TO lt_update.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition UPDATE FROM lt_update
      REPORTED DATA(lt_rep)
      FAILED DATA(lt_failed)
      MAPPED DATA(lt_mapped).
  ENDMETHOD.

  "==========================================================================
  " DETERMINATION: CalculatePRTotal
  " Reads all items for this PR, sums LineTotal → writes to TotalValue.
  " Called whenever items change (triggered from item determinations).
  "==========================================================================
  METHOD calculate_pr_total.
    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition BY \_Items
        FIELDS ( LineTotal Currency )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    DATA lt_update TYPE TABLE FOR UPDATE ZI_PurchaseRequisition\\PurchaseRequisition.

    " Group items by PR ID and sum
    LOOP AT keys INTO DATA(ls_key).
      DATA(lv_total)    = REDUCE abap_curr( INIT sum TYPE abap_curr
                            FOR item IN lt_items
                            WHERE ( %key-PrId = ls_key-%key-PrId )
                            NEXT sum = sum + item-LineTotal ).

      DATA(lv_currency) = VALUE zpur_reqitm-currency(
                            lt_items[ %key-PrId = ls_key-%key-PrId ]-Currency
                            OPTIONAL ).

      APPEND VALUE #(
        %tky       = ls_key-%tky
        TotalValue = lv_total
        Currency   = lv_currency
        %control   = VALUE #(
          TotalValue = if_abap_behv=>mk-on
          Currency   = if_abap_behv=>mk-on )
      ) TO lt_update.
    ENDLOOP.

    MODIFY ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition UPDATE FROM lt_update
      REPORTED DATA(lt_rep) FAILED DATA(lt_fail) MAPPED DATA(lt_map).
  ENDMETHOD.

  "==========================================================================
  " VALIDATION: ValidateItems
  " Ensures a PR has at least one item before saving/submitting.
  "==========================================================================
  METHOD validate_items.
    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition BY \_Items
        FIELDS ( ItemUuid )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    LOOP AT keys INTO DATA(ls_key).
      DATA(lv_count) = REDUCE i( INIT n = 0
                         FOR item IN lt_items
                         WHERE ( %key-PrId = ls_key-%key-PrId )
                         NEXT n = n + 1 ).

      IF lv_count = 0.
        " Append error: PR cannot be saved without at least one item
        APPEND VALUE #(
          %tky               = ls_key-%tky
          %state_area        = 'VALIDATE_ITEMS'
          %msg               = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'A Purchase Requisition must have at least one item.' )
          %element-TotalValue = if_abap_behv=>mk-on
        ) TO reported-purchaserequisition.

        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-purchaserequisition.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  "==========================================================================
  " VALIDATION: ValidateLineValues
  " Ensures Quantity > 0 and UnitPrice > 0 on all items of this PR.
  "==========================================================================
  METHOD validate_line_values.
    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition BY \_Items
        FIELDS ( ItemUuid Quantity UnitPrice Description )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    LOOP AT lt_items INTO DATA(ls_item).
      IF ls_item-Quantity <= 0.
        APPEND VALUE #(
          %tky        = VALUE #( PrId = ls_item-PrId )
          %state_area = 'VALIDATE_QTY'
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |Item { ls_item-Description }: Quantity must be greater than zero.| )
        ) TO reported-purchaserequisition.
        APPEND VALUE #( %tky = VALUE #( PrId = ls_item-PrId ) ) TO failed-purchaserequisition.
      ENDIF.

      IF ls_item-UnitPrice <= 0.
        APPEND VALUE #(
          %tky        = VALUE #( PrId = ls_item-PrId )
          %state_area = 'VALIDATE_PRICE'
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = |Item { ls_item-Description }: Unit Price must be greater than zero.| )
        ) TO reported-purchaserequisition.
        APPEND VALUE #( %tky = VALUE #( PrId = ls_item-PrId ) ) TO failed-purchaserequisition.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  "==========================================================================
  " ACTION: Submit
  " 1. Validates budget availability (ZC_CostCenterBudget)
  " 2. Routes to approval level based on TotalValue thresholds:
  "      < 50,000       → Auto-approved immediately
  "      50,000–500,000 → Manager approval (ApprovalLevel = 1)
  "      > 500,000      → Finance approval required (ApprovalLevel = 2)
  " 3. Writes audit log entry
  "==========================================================================
  METHOD submit.
    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition
        FIELDS ( Status TotalValue CostCenter Currency Requester )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_pr)
      FAILED DATA(lt_failed).

    DATA lt_update TYPE TABLE FOR UPDATE ZI_PurchaseRequisition\\PurchaseRequisition.

    LOOP AT lt_pr INTO DATA(ls_pr).
      " Guard: only Draft or Submitted PRs can be re-submitted
      IF ls_pr-Status <> lcl_constants=>c_status_draft
        AND ls_pr-Status <> lcl_constants=>c_status_submitted.
        APPEND VALUE #(
          %tky = ls_pr-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |PR can only be submitted from Draft status. Current: { ls_pr-Status }| )
        ) TO reported-purchaserequisition.
        APPEND VALUE #( %tky = ls_pr-%tky ) TO failed-purchaserequisition.
        CONTINUE.
      ENDIF.

      " -------------------------------------------------------
      " Step 1: Budget check — read from ZCOSTCTR_B
      " Use current fiscal period (YYYY/<current month>)
      " -------------------------------------------------------
      DATA(lv_period) = |{ cl_abap_context_info=>get_system_date( )+0(4) }/{ cl_abap_context_info=>get_system_date( )+4(2) }|.

      SELECT SINGLE remaining_budget, currency
        FROM zcostctr_b
        WHERE cost_center   = @ls_pr-CostCenter
          AND budget_period = @lv_period
        INTO @DATA(ls_budget).

      IF sy-subrc <> 0.
        " No budget record found — block submission
        APPEND VALUE #(
          %tky = ls_pr-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |No budget record found for cost center { ls_pr-CostCenter } period { lv_period }.| )
        ) TO reported-purchaserequisition.
        APPEND VALUE #( %tky = ls_pr-%tky ) TO failed-purchaserequisition.
        CONTINUE.
      ENDIF.

      IF ls_budget-remaining_budget < ls_pr-TotalValue.
        " Insufficient budget — block submission with clear message
        APPEND VALUE #(
          %tky = ls_pr-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |Insufficient budget. Remaining: { ls_budget-remaining_budget } { ls_budget-currency }, PR Total: { ls_pr-TotalValue } { ls_pr-Currency }| )
        ) TO reported-purchaserequisition.
        APPEND VALUE #( %tky = ls_pr-%tky ) TO failed-purchaserequisition.
        CONTINUE.
      ENDIF.

      " -------------------------------------------------------
      " Step 2: Determine approval route
      " -------------------------------------------------------
      DATA lv_new_status    TYPE string.
      DATA lv_approval_level TYPE int1.

      IF ls_pr-TotalValue < lcl_constants=>c_threshold_auto.
        " Auto-approved: no human approval needed
        lv_new_status    = lcl_constants=>c_status_approved.
        lv_approval_level = 0.
      ELSEIF ls_pr-TotalValue <= lcl_constants=>c_threshold_finance.
        " Manager approval required
        lv_new_status    = lcl_constants=>c_status_pending.
        lv_approval_level = 1.
        " In production, fetch manager from HR org structure (PA0001)
        " For this demo, approver field is set by the requester at PR creation
      ELSE.
        " Sequential manager + finance approval
        lv_new_status    = lcl_constants=>c_status_pending.
        lv_approval_level = 2.
      ENDIF.

      " -------------------------------------------------------
      " Step 3: Write updates
      " -------------------------------------------------------
      APPEND VALUE #(
        %tky          = ls_pr-%tky
        Status        = lv_new_status
        ApprovalLevel = lv_approval_level
        SubmittedAt   = cl_abap_context_info=>get_system_date( )
        %control      = VALUE #(
          Status        = if_abap_behv=>mk-on
          ApprovalLevel = if_abap_behv=>mk-on
          SubmittedAt   = if_abap_behv=>mk-on )
      ) TO lt_update.

      " Write audit log
      lcl_audit_helper=>write_log(
        iv_prid       = ls_pr-PrId
        iv_old_status = ls_pr-Status
        iv_new_status = lv_new_status
        iv_action     = lcl_constants=>c_action_submit
        iv_comments   = COND #( WHEN lv_approval_level = 0
                                  THEN 'Auto-approved: value below threshold'
                                  ELSE 'Routed to approval level ' && lv_approval_level ) ).
    ENDLOOP.

    MODIFY ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition UPDATE FROM lt_update
      REPORTED DATA(lt_rep) FAILED DATA(lt_fail2) MAPPED DATA(lt_map).

    " Return updated PR instances to caller
    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition ALL FIELDS
        WITH CORRESPONDING #( lt_update )
      RESULT DATA(lt_result).

    et_result = CORRESPONDING #( lt_result ).
  ENDMETHOD.

  "==========================================================================
  " ACTION: Approve
  " 1. Checks caller is the assigned approver (role-based auth)
  " 2. For ApprovalLevel=2, first approval sets FinanceApprovedBy flag
  " 3. Final approval deducts TotalValue from cost center budget
  " 4. Writes audit log
  "==========================================================================
  METHOD approve.
    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition
        FIELDS ( Status Approver ApprovalLevel TotalValue CostCenter Currency FinanceApprovedBy )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_pr).

    DATA lt_update TYPE TABLE FOR UPDATE ZI_PurchaseRequisition\\PurchaseRequisition.
    DATA(lv_current_user) = cl_abap_context_info=>get_user_alias( ).

    LOOP AT lt_pr INTO DATA(ls_pr).
      " Guard: must be in PendingApproval state
      IF ls_pr-Status <> lcl_constants=>c_status_pending.
        APPEND VALUE #(
          %tky = ls_pr-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Only PRs in PendingApproval status can be approved.' )
        ) TO reported-purchaserequisition.
        APPEND VALUE #( %tky = ls_pr-%tky ) TO failed-purchaserequisition.
        CONTINUE.
      ENDIF.

      " Guard: only the assigned approver may approve
      IF ls_pr-Approver <> lv_current_user.
        APPEND VALUE #(
          %tky = ls_pr-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |You ({ lv_current_user }) are not the assigned approver ({ ls_pr-Approver }) for this PR.| )
        ) TO reported-purchaserequisition.
        APPEND VALUE #( %tky = ls_pr-%tky ) TO failed-purchaserequisition.
        CONTINUE.
      ENDIF.

      " Multi-step: ApprovalLevel=2 requires finance step after manager
      DATA lv_new_status   TYPE string.
      DATA lv_fin_approved TYPE zpur_reqhdr-finance_approved_by.

      IF ls_pr-ApprovalLevel = 2 AND ls_pr-FinanceApprovedBy IS INITIAL.
        " First approval: manager approved, now needs finance
        lv_new_status   = lcl_constants=>c_status_pending.
        lv_fin_approved = ls_pr-FinanceApprovedBy.  "still empty
        " In production: re-route to finance approver user
      ELSE.
        " Final approval (level 1, or level 2 second step)
        lv_new_status   = lcl_constants=>c_status_approved.
        lv_fin_approved = lv_current_user.

        " Deduct budget
        DATA(lv_ok) = me->deduct_budget(
                        iv_cost_center = ls_pr-CostCenter
                        iv_amount      = ls_pr-TotalValue
                        iv_currency    = ls_pr-Currency ).
        IF lv_ok = abap_false.
          APPEND VALUE #(
            %tky = ls_pr-%tky
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-warning
                     text     = 'Budget deduction failed — please check ZCOSTCTR_B manually.' )
          ) TO reported-purchaserequisition.
        ENDIF.
      ENDIF.

      APPEND VALUE #(
        %tky               = ls_pr-%tky
        Status             = lv_new_status
        FinanceApprovedBy  = lv_fin_approved
        ApprovedAt         = cl_abap_context_info=>get_system_date( )
        %control           = VALUE #(
          Status            = if_abap_behv=>mk-on
          FinanceApprovedBy = if_abap_behv=>mk-on
          ApprovedAt        = if_abap_behv=>mk-on )
      ) TO lt_update.

      lcl_audit_helper=>write_log(
        iv_prid       = ls_pr-PrId
        iv_old_status = ls_pr-Status
        iv_new_status = lv_new_status
        iv_action     = lcl_constants=>c_action_approve
        iv_comments   = 'Approved by ' && lv_current_user ).
    ENDLOOP.

    MODIFY ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition UPDATE FROM lt_update
      REPORTED DATA(lt_rep) FAILED DATA(lt_fail) MAPPED DATA(lt_map).

    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition ALL FIELDS
        WITH CORRESPONDING #( lt_update )
      RESULT DATA(lt_result).
    et_result = CORRESPONDING #( lt_result ).
  ENDMETHOD.

  "==========================================================================
  " ACTION: Reject
  " Requires a mandatory rejection comment (from parameter ZA_PRRejectParam).
  " Sets status to Rejected and writes audit log.
  "==========================================================================
  METHOD reject.
    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition
        FIELDS ( Status Approver )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_pr).

    DATA lt_update TYPE TABLE FOR UPDATE ZI_PurchaseRequisition\\PurchaseRequisition.
    DATA(lv_current_user) = cl_abap_context_info=>get_user_alias( ).

    " Read action parameters (rejection comment)
    READ TABLE keys INTO DATA(ls_first_key) INDEX 1.
    DATA(lv_comment) = ls_first_key-%param-Comment.

    " Mandatory comment check
    IF lv_comment IS INITIAL.
      LOOP AT lt_pr INTO DATA(ls_pr).
        APPEND VALUE #(
          %tky = ls_pr-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Rejection comment is mandatory. Please provide a reason.' )
        ) TO reported-purchaserequisition.
        APPEND VALUE #( %tky = ls_pr-%tky ) TO failed-purchaserequisition.
      ENDLOOP.
      RETURN.
    ENDIF.

    LOOP AT lt_pr INTO DATA(ls_pr2).
      IF ls_pr2-Status <> lcl_constants=>c_status_pending.
        APPEND VALUE #(
          %tky = ls_pr2-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Only PRs in PendingApproval status can be rejected.' )
        ) TO reported-purchaserequisition.
        APPEND VALUE #( %tky = ls_pr2-%tky ) TO failed-purchaserequisition.
        CONTINUE.
      ENDIF.

      " Only the assigned approver may reject
      IF ls_pr2-Approver <> lv_current_user.
        APPEND VALUE #(
          %tky = ls_pr2-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |You ({ lv_current_user }) are not the approver for this PR.| )
        ) TO reported-purchaserequisition.
        APPEND VALUE #( %tky = ls_pr2-%tky ) TO failed-purchaserequisition.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %tky              = ls_pr2-%tky
        Status            = lcl_constants=>c_status_rejected
        RejectionComment  = lv_comment
        %control          = VALUE #(
          Status           = if_abap_behv=>mk-on
          RejectionComment = if_abap_behv=>mk-on )
      ) TO lt_update.

      lcl_audit_helper=>write_log(
        iv_prid       = ls_pr2-PrId
        iv_old_status = ls_pr2-Status
        iv_new_status = lcl_constants=>c_status_rejected
        iv_action     = lcl_constants=>c_action_reject
        iv_comments   = lv_comment ).
    ENDLOOP.

    MODIFY ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition UPDATE FROM lt_update
      REPORTED DATA(lt_rep) FAILED DATA(lt_fail) MAPPED DATA(lt_map).

    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition ALL FIELDS
        WITH CORRESPONDING #( lt_update )
      RESULT DATA(lt_result).
    et_result = CORRESPONDING #( lt_result ).
  ENDMETHOD.

  "==========================================================================
  " ACTION: Delegate
  " Approver reassigns their pending PR to a substitute approver.
  "==========================================================================
  METHOD delegate.
    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition
        FIELDS ( Status Approver )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_pr).

    DATA lt_update TYPE TABLE FOR UPDATE ZI_PurchaseRequisition\\PurchaseRequisition.
    DATA(lv_current_user) = cl_abap_context_info=>get_user_alias( ).

    READ TABLE keys INTO DATA(ls_first_key) INDEX 1.
    DATA(lv_substitute) = ls_first_key-%param-SubstituteApprover.

    IF lv_substitute IS INITIAL.
      LOOP AT lt_pr INTO DATA(ls_pr).
        APPEND VALUE #(
          %tky = ls_pr-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Substitute approver must be specified.' )
        ) TO reported-purchaserequisition.
        APPEND VALUE #( %tky = ls_pr-%tky ) TO failed-purchaserequisition.
      ENDLOOP.
      RETURN.
    ENDIF.

    LOOP AT lt_pr INTO DATA(ls_pr2).
      IF ls_pr2-Status <> lcl_constants=>c_status_pending.
        APPEND VALUE #(
          %tky = ls_pr2-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Only pending PRs can be delegated.' )
        ) TO reported-purchaserequisition.
        APPEND VALUE #( %tky = ls_pr2-%tky ) TO failed-purchaserequisition.
        CONTINUE.
      ENDIF.

      IF ls_pr2-Approver <> lv_current_user.
        APPEND VALUE #(
          %tky = ls_pr2-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Only the assigned approver can delegate.' )
        ) TO reported-purchaserequisition.
        APPEND VALUE #( %tky = ls_pr2-%tky ) TO failed-purchaserequisition.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %tky     = ls_pr2-%tky
        Approver = lv_substitute
        %control = VALUE #( Approver = if_abap_behv=>mk-on )
      ) TO lt_update.

      lcl_audit_helper=>write_log(
        iv_prid       = ls_pr2-PrId
        iv_old_status = ls_pr2-Status
        iv_new_status = ls_pr2-Status
        iv_action     = lcl_constants=>c_action_delegate
        iv_comments   = |Delegated from { lv_current_user } to { lv_substitute }| ).
    ENDLOOP.

    MODIFY ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition UPDATE FROM lt_update
      REPORTED DATA(lt_rep) FAILED DATA(lt_fail) MAPPED DATA(lt_map).

    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition ALL FIELDS
        WITH CORRESPONDING #( lt_update )
      RESULT DATA(lt_result).
    et_result = CORRESPONDING #( lt_result ).
  ENDMETHOD.

  "==========================================================================
  " ACTION: Withdraw
  " Requester cancels a PR. Allowed only in Draft or Submitted status.
  "==========================================================================
  METHOD withdraw.
    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition
        FIELDS ( Status Requester )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_pr).

    DATA lt_update TYPE TABLE FOR UPDATE ZI_PurchaseRequisition\\PurchaseRequisition.
    DATA(lv_current_user) = cl_abap_context_info=>get_user_alias( ).

    LOOP AT lt_pr INTO DATA(ls_pr).
      " Only requester can withdraw
      IF ls_pr-Requester <> lv_current_user.
        APPEND VALUE #(
          %tky = ls_pr-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = 'Only the requester can withdraw a PR.' )
        ) TO reported-purchaserequisition.
        APPEND VALUE #( %tky = ls_pr-%tky ) TO failed-purchaserequisition.
        CONTINUE.
      ENDIF.

      " Can only withdraw before approval starts
      IF ls_pr-Status <> lcl_constants=>c_status_draft
        AND ls_pr-Status <> lcl_constants=>c_status_submitted.
        APPEND VALUE #(
          %tky = ls_pr-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |Cannot withdraw a PR in { ls_pr-Status } status.| )
        ) TO reported-purchaserequisition.
        APPEND VALUE #( %tky = ls_pr-%tky ) TO failed-purchaserequisition.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %tky     = ls_pr-%tky
        Status   = lcl_constants=>c_status_closed
        %control = VALUE #( Status = if_abap_behv=>mk-on )
      ) TO lt_update.

      lcl_audit_helper=>write_log(
        iv_prid       = ls_pr-PrId
        iv_old_status = ls_pr-Status
        iv_new_status = lcl_constants=>c_status_closed
        iv_action     = lcl_constants=>c_action_withdraw ).
    ENDLOOP.

    MODIFY ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition UPDATE FROM lt_update
      REPORTED DATA(lt_rep) FAILED DATA(lt_fail) MAPPED DATA(lt_map).

    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition ALL FIELDS
        WITH CORRESPONDING #( lt_update )
      RESULT DATA(lt_result).
    et_result = CORRESPONDING #( lt_result ).
  ENDMETHOD.

  "==========================================================================
  " AUTHORIZATION: get_instance_authorizations
  " Controls which CRUD operations a user may perform per instance.
  "==========================================================================
  METHOD get_instance_authorizations.
    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition
        FIELDS ( Requester Approver Status )
        WITH CORRESPONDING #( requested_authorizations-%tky )
      RESULT DATA(lt_pr).

    DATA(lv_current_user) = cl_abap_context_info=>get_user_alias( ).

    LOOP AT lt_pr INTO DATA(ls_pr).
      " Requesters: edit only own PRs in Draft status
      IF ls_pr-Requester = lv_current_user
        AND ls_pr-Status = lcl_constants=>c_status_draft.
        APPEND VALUE #(
          %tky           = ls_pr-%tky
          %update        = if_abap_behv=>auth-allowed
          %delete        = if_abap_behv=>auth-allowed
          %action-Submit = if_abap_behv=>auth-allowed
        ) TO result.
      ELSEIF ls_pr-Approver = lv_current_user
        AND ls_pr-Status = lcl_constants=>c_status_pending.
        " Approvers: can Approve, Reject, Delegate
        APPEND VALUE #(
          %tky             = ls_pr-%tky
          %update          = if_abap_behv=>auth-unauthorized
          %delete          = if_abap_behv=>auth-unauthorized
          %action-Approve  = if_abap_behv=>auth-allowed
          %action-Reject   = if_abap_behv=>auth-allowed
          %action-Delegate = if_abap_behv=>auth-allowed
        ) TO result.
      ELSE.
        " All other combinations: read-only
        APPEND VALUE #(
          %tky    = ls_pr-%tky
          %update = if_abap_behv=>auth-unauthorized
          %delete = if_abap_behv=>auth-unauthorized
        ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  "==========================================================================
  " FEATURES: get_instance_features
  " Controls which buttons/fields are shown/enabled on the Fiori UI
  " per individual PR instance.
  "==========================================================================
  METHOD get_instance_features.
    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisition
        FIELDS ( Status Requester Approver )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_pr).

    DATA(lv_current_user) = cl_abap_context_info=>get_user_alias( ).

    LOOP AT lt_pr INTO DATA(ls_pr).
      DATA(lv_is_requester) = xsdbool( ls_pr-Requester = lv_current_user ).
      DATA(lv_is_approver)  = xsdbool( ls_pr-Approver  = lv_current_user ).

      APPEND VALUE #(
        %tky             = ls_pr-%tky
        " Submit: only draft PRs, only by requester
        %action-Submit   = COND #( WHEN ls_pr-Status = lcl_constants=>c_status_draft
                                    AND lv_is_requester = abap_true
                                   THEN if_abap_behv=>fc-o-enabled
                                   ELSE if_abap_behv=>fc-o-disabled )
        " Approve: only pending, only by approver
        %action-Approve  = COND #( WHEN ls_pr-Status = lcl_constants=>c_status_pending
                                    AND lv_is_approver = abap_true
                                   THEN if_abap_behv=>fc-o-enabled
                                   ELSE if_abap_behv=>fc-o-disabled )
        " Reject: same as Approve
        %action-Reject   = COND #( WHEN ls_pr-Status = lcl_constants=>c_status_pending
                                    AND lv_is_approver = abap_true
                                   THEN if_abap_behv=>fc-o-enabled
                                   ELSE if_abap_behv=>fc-o-disabled )
        " Delegate: pending + approver
        %action-Delegate = COND #( WHEN ls_pr-Status = lcl_constants=>c_status_pending
                                    AND lv_is_approver = abap_true
                                   THEN if_abap_behv=>fc-o-enabled
                                   ELSE if_abap_behv=>fc-o-disabled )
        " Withdraw: draft/submitted + requester
        %action-Withdraw = COND #( WHEN ( ls_pr-Status = lcl_constants=>c_status_draft
                                       OR ls_pr-Status = lcl_constants=>c_status_submitted )
                                    AND lv_is_requester = abap_true
                                   THEN if_abap_behv=>fc-o-enabled
                                   ELSE if_abap_behv=>fc-o-disabled )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

  "==========================================================================
  " HELPER: check_approver_role
  " Verifies the user has the ZPROCUREFLOW_APPROVER PFCG role
  " by checking auth object ZPURAPPR_OBJ.
  "==========================================================================
  METHOD check_approver_role.
    AUTHORITY-CHECK OBJECT 'ZPURAPPR_OBJ'
      ID 'ACTVT'  FIELD '01'
      ID 'ZZUNAME' FIELD iv_user.
    rv_ok = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  "==========================================================================
  " HELPER: deduct_budget
  " On final approval, decrements consumed_budget and remaining_budget
  " in ZCOSTCTR_B for the current fiscal period.
  "==========================================================================
  METHOD deduct_budget.
    rv_ok = abap_false.

    DATA(lv_period) = |{ cl_abap_context_info=>get_system_date( )+0(4) }/{ cl_abap_context_info=>get_system_date( )+4(2) }|.

    SELECT SINGLE *
      FROM zcostctr_b
      WHERE cost_center  = @iv_cost_center
        AND budget_period = @lv_period
      INTO @DATA(ls_budget)
      FOR UPDATE.   "lock row before update

    IF sy-subrc <> 0. RETURN. ENDIF.

    ls_budget-consumed_budget  = ls_budget-consumed_budget  + iv_amount.
    ls_budget-remaining_budget = ls_budget-remaining_budget - iv_amount.
    ls_budget-last_changed_at  = utclong_current( ).

    UPDATE zcostctr_b FROM @ls_budget.
    IF sy-subrc = 0. rv_ok = abap_true. ENDIF.
  ENDMETHOD.

ENDCLASS.

"==========================================================================
" ITEM HANDLER: lhc_purchaserequisitionitem
"==========================================================================
CLASS lhc_purchaserequisitionitem IMPLEMENTATION.

  "==========================================================================
  " DETERMINATION: CalculateLineTotal
  " LineTotal = Quantity × UnitPrice
  " Called whenever Quantity or UnitPrice changes on an item.
  "==========================================================================
  METHOD calculate_line_total.
    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisitionItem
        FIELDS ( Quantity UnitPrice Currency )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    DATA lt_update TYPE TABLE FOR UPDATE ZI_PurchaseRequisition\\PurchaseRequisitionItem.

    LOOP AT lt_items INTO DATA(ls_item).
      APPEND VALUE #(
        %tky      = ls_item-%tky
        LineTotal = ls_item-Quantity * ls_item-UnitPrice
        %control  = VALUE #( LineTotal = if_abap_behv=>mk-on )
      ) TO lt_update.
    ENDLOOP.

    MODIFY ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisitionItem UPDATE FROM lt_update
      REPORTED DATA(lt_rep) FAILED DATA(lt_fail) MAPPED DATA(lt_map).
  ENDMETHOD.

  "==========================================================================
  " DETERMINATION: SuggestVendor
  " Looks up ZVENDOR_M for the most recently used vendor in the same
  " MaterialGroup. Sets PreferredVendor if not already manually set.
  "==========================================================================
  METHOD suggest_vendor.
    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisitionItem
        FIELDS ( MaterialGroup PreferredVendor )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    DATA lt_update TYPE TABLE FOR UPDATE ZI_PurchaseRequisition\\PurchaseRequisitionItem.

    LOOP AT lt_items INTO DATA(ls_item).
      " Only auto-suggest if vendor not already specified
      IF ls_item-PreferredVendor IS NOT INITIAL. CONTINUE. ENDIF.
      IF ls_item-MaterialGroup IS INITIAL. CONTINUE. ENDIF.

      " Find the most recently used vendor for this material group
      SELECT SINGLE vendor_id
        FROM zvendor_m
        WHERE material_group = @ls_item-MaterialGroup
          AND is_preferred   = @abap_true
        ORDER BY last_used_date DESCENDING
        INTO @DATA(lv_vendor).

      IF sy-subrc = 0.
        APPEND VALUE #(
          %tky            = ls_item-%tky
          PreferredVendor = lv_vendor
          %control        = VALUE #( PreferredVendor = if_abap_behv=>mk-on )
        ) TO lt_update.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisitionItem UPDATE FROM lt_update
      REPORTED DATA(lt_rep) FAILED DATA(lt_fail) MAPPED DATA(lt_map).
  ENDMETHOD.

  "==========================================================================
  " VALIDATION: ValidateQuantityPrice
  " Item-level validation: Quantity > 0, UnitPrice > 0.
  " Also validates that MaterialNo is not empty.
  "==========================================================================
  METHOD validate_quantity_price.
    READ ENTITIES OF ZI_PurchaseRequisition IN LOCAL MODE
      ENTITY PurchaseRequisitionItem
        FIELDS ( Quantity UnitPrice MaterialNo Description )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    LOOP AT lt_items INTO DATA(ls_item).
      IF ls_item-Quantity <= 0.
        APPEND VALUE #(
          %tky             = ls_item-%tky
          %state_area      = 'QTY_ZERO'
          %msg             = new_message_with_text(
                               severity = if_abap_behv_message=>severity-error
                               text     = 'Quantity must be greater than zero.' )
          %element-Quantity = if_abap_behv=>mk-on
        ) TO reported-purchaserequisitionitem.
        APPEND VALUE #( %tky = ls_item-%tky ) TO failed-purchaserequisitionitem.
      ENDIF.

      IF ls_item-UnitPrice <= 0.
        APPEND VALUE #(
          %tky              = ls_item-%tky
          %state_area       = 'PRICE_ZERO'
          %msg              = new_message_with_text(
                                severity = if_abap_behv_message=>severity-error
                                text     = 'Unit Price must be greater than zero.' )
          %element-UnitPrice = if_abap_behv=>mk-on
        ) TO reported-purchaserequisitionitem.
        APPEND VALUE #( %tky = ls_item-%tky ) TO failed-purchaserequisitionitem.
      ENDIF.

      IF ls_item-MaterialNo IS INITIAL.
        APPEND VALUE #(
          %tky               = ls_item-%tky
          %state_area        = 'MAT_EMPTY'
          %msg               = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Material Number is mandatory.' )
          %element-MaterialNo = if_abap_behv=>mk-on
        ) TO reported-purchaserequisitionitem.
        APPEND VALUE #( %tky = ls_item-%tky ) TO failed-purchaserequisitionitem.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
* fix: handle zero budget edge case in validate_BudgetAvailability
* fix: null check for rejection reason in reject action
