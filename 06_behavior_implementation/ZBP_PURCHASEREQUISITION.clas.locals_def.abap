"==========================================================================
" LOCAL CLASS DEFINITIONS — ZBP_PURCHASEREQUISITION
"
" Structure:
"   LHC_PURCHASEREQUISITION  — Handler for root entity (PR Header)
"   LHC_PURCHASEREQUISITIONITEM — Handler for child entity (PR Items)
"   LHC_PRAAUDITLOG          — Handler for audit log (mostly read-only)
"   LSC_PURCHASEREQUISITION  — Saver class (called after CRUD cycle)
"
" Constants for Status values — centralised here so logic is consistent
"==========================================================================

"--------------------------------------------------------------------------
" Status constants used throughout the implementation
"--------------------------------------------------------------------------
CLASS lcl_constants DEFINITION.
  PUBLIC SECTION.
    CONSTANTS:
      c_status_draft      TYPE string VALUE 'Draft',
      c_status_submitted  TYPE string VALUE 'Submitted',
      c_status_pending    TYPE string VALUE 'PendingApproval',
      c_status_approved   TYPE string VALUE 'Approved',
      c_status_rejected   TYPE string VALUE 'Rejected',
      c_status_closed     TYPE string VALUE 'Closed',

      c_priority_low      TYPE string VALUE 'Low',
      c_priority_medium   TYPE string VALUE 'Medium',
      c_priority_high     TYPE string VALUE 'High',
      c_priority_critical TYPE string VALUE 'Critical',

      c_action_submit     TYPE string VALUE 'Submit',
      c_action_approve    TYPE string VALUE 'Approve',
      c_action_reject     TYPE string VALUE 'Reject',
      c_action_delegate   TYPE string VALUE 'Delegate',
      c_action_withdraw   TYPE string VALUE 'Withdraw',

      " Approval threshold constants (INR)
      c_threshold_auto    TYPE p LENGTH 10 DECIMALS 2 VALUE '50000.00',
      c_threshold_finance TYPE p LENGTH 10 DECIMALS 2 VALUE '500000.00'.
ENDCLASS.
CLASS lcl_constants IMPLEMENTATION.
ENDCLASS.

"--------------------------------------------------------------------------
" Helper: Write a record to the audit log
"--------------------------------------------------------------------------
CLASS lcl_audit_helper DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS write_log
      IMPORTING
        iv_prid       TYPE sysuuid_x16
        iv_old_status TYPE string
        iv_new_status TYPE string
        iv_action     TYPE string
        iv_comments   TYPE string OPTIONAL.
ENDCLASS.
CLASS lcl_audit_helper IMPLEMENTATION.
  METHOD write_log.
    DATA: ls_log TYPE zpur_auditlog.

    " Generate a new UUID for the log entry
    TRY.
        ls_log-log_id       = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
        RETURN.   "silently skip if UUID generation fails
    ENDTRY.

    ls_log-client        = sy-mandt.
    ls_log-prid          = iv_prid.
    ls_log-log_timestamp = utclong_current( ).
    ls_log-changed_by    = cl_abap_context_info=>get_user_alias( ).
    ls_log-old_status    = iv_old_status.
    ls_log-new_status    = iv_new_status.
    ls_log-action_taken  = iv_action.
    ls_log-comments      = iv_comments.

    INSERT zpur_auditlog FROM @ls_log.
    " Errors here are non-fatal; the main transaction will still commit.
  ENDMETHOD.
ENDCLASS.

"--------------------------------------------------------------------------
" Handler class: PR Header (root entity)
"--------------------------------------------------------------------------
CLASS lhc_purchaserequisition DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    " --- Determinations ---
    METHODS set_initial_status       FOR DETERMINE ON CREATE
                                     FOR PurchaseRequisition~SetInitialStatus.
    METHODS set_pr_id_external       FOR DETERMINE ON CREATE
                                     FOR PurchaseRequisition~SetPrIdExternal.
    METHODS calculate_pr_total       FOR DETERMINE ON MODIFY
                                     FOR PurchaseRequisition~CalculatePRTotal.

    " --- Validations ---
    METHODS validate_items           FOR VALIDATE ON SAVE
                                     FOR PurchaseRequisition~ValidateItems.
    METHODS validate_line_values     FOR VALIDATE ON SAVE
                                     FOR PurchaseRequisition~ValidateLineValues.

    " --- Custom Actions ---
    METHODS submit                   FOR MODIFY
                                     FOR ACTION PurchaseRequisition~Submit
                                     RESULT et_result.
    METHODS approve                  FOR MODIFY
                                     FOR ACTION PurchaseRequisition~Approve
                                     RESULT et_result.
    METHODS reject                   FOR MODIFY
                                     FOR ACTION PurchaseRequisition~Reject
                                     RESULT et_result.
    METHODS delegate                 FOR MODIFY
                                     FOR ACTION PurchaseRequisition~Delegate
                                     RESULT et_result.
    METHODS withdraw                 FOR MODIFY
                                     FOR ACTION PurchaseRequisition~Withdraw
                                     RESULT et_result.

    " --- Authorization ---
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
                                        FOR PurchaseRequisition~Authorization.
    METHODS get_instance_features       FOR INSTANCE FEATURES
                                        FOR PurchaseRequisition~Features.

    " --- Private helpers ---
    METHODS check_approver_role
      IMPORTING iv_user         TYPE abap_syst_uname
                iv_approver     TYPE abap_syst_uname
      RETURNING VALUE(rv_ok)    TYPE abap_boolean.

    METHODS deduct_budget
      IMPORTING iv_cost_center  TYPE zpur_reqhdr-cost_center
                iv_amount       TYPE zpur_reqhdr-total_value
                iv_currency     TYPE zpur_reqhdr-currency
      RETURNING VALUE(rv_ok)    TYPE abap_boolean.

ENDCLASS.

"--------------------------------------------------------------------------
" Handler class: PR Item (child entity)
"--------------------------------------------------------------------------
CLASS lhc_purchaserequisitionitem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calculate_line_total    FOR DETERMINE ON MODIFY
                                    FOR PurchaseRequisitionItem~CalculateLineTotal.
    METHODS suggest_vendor          FOR DETERMINE ON MODIFY
                                    FOR PurchaseRequisitionItem~SuggestVendor.
    METHODS validate_quantity_price FOR VALIDATE ON SAVE
                                    FOR PurchaseRequisitionItem~ValidateQuantityPrice.

ENDCLASS.
