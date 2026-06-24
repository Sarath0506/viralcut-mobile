String participationSummaryLabel(String summary) {
  switch (summary) {
    case 'joined':
      return 'Joined';
    case 'drafts_incomplete':
      return 'Drafts incomplete';
    case 'in_review':
      return 'Under review';
    case 'action_required':
      return 'Action required';
    case 'proof_complete':
      return 'Complete';
    case 'closed':
      return 'Closed';
    default:
      return summary.replaceAll('_', ' ');
  }
}

String participationSummaryMessage(String summary) {
  switch (summary) {
    case 'joined':
      return 'Submit your drafts for each required format.';
    case 'drafts_incomplete':
      return 'Finish uploading drafts for every platform.';
    case 'in_review':
      return 'The brand is reviewing your drafts. You will be notified when they respond.';
    case 'action_required':
      return 'Post approved content live or resubmit any rejected drafts.';
    case 'proof_complete':
      return 'All formats are approved and live proof is on file.';
    case 'closed':
      return 'This campaign is no longer accepting submissions.';
    default:
      return '';
  }
}

String deliverableStatusLabel(String status) {
  switch (status) {
    case 'draft_pending':
      return 'Draft pending';
    case 'under_review':
      return 'Under review';
    case 'draft_approved':
      return 'Approved';
    case 'draft_rejected':
      return 'Rejected';
    case 'live_submitted':
      return 'Live submitted';
    default:
      return status.replaceAll('_', ' ');
  }
}

String deliverableStatusHint(String status) {
  switch (status) {
    case 'draft_pending':
      return 'Upload your Google Drive draft link.';
    case 'under_review':
      return 'Waiting for brand review.';
    case 'draft_approved':
      return 'Post on the platform, then submit your live post URL.';
    case 'draft_rejected':
      return 'Update your draft and resubmit.';
    case 'live_submitted':
      return 'Live proof submitted.';
    default:
      return '';
  }
}
