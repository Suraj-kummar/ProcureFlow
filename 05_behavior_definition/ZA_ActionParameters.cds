"==========================================================================
" Abstract entities used as parameter types for RAP custom actions.
" These are CDS abstract entities, not database tables.
" In ADT: create as CDS Data Definition with template "Abstract Entity"
"==========================================================================

"--- Parameter for Approve action ---
@EndUserText.label: 'Approve Action Parameter'
define abstract entity ZA_PRApproveParam
{
  Comment : abap.char(500);   "Optional approval comment
}

"--- Parameter for Reject action (Comment is mandatory — enforced in code) ---
@EndUserText.label: 'Reject Action Parameter'
define abstract entity ZA_PRRejectParam
{
  Comment : abap.char(500);   "MANDATORY rejection reason
}

"--- Parameter for Delegate action ---
@EndUserText.label: 'Delegate Action Parameter'
define abstract entity ZA_PRDelegateParam
{
  SubstituteApprover : abap.char(12);   "User alias of substitute approver
  Comment            : abap.char(200);
}
