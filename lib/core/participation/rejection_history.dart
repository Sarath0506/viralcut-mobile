import 'participation_models.dart';

bool isSameRejectedDriveUrl(FormatDeliverable deliverable, String url) {
  final trimmed = url.trim();
  final lastRejected = deliverable.lastRejectedDriveUrl;
  if (lastRejected == null) return false;
  return lastRejected.trim() == trimmed;
}

List<RejectionHistoryEvent> priorRejectionEvents(FormatDeliverable deliverable) {
  if (deliverable.rejectionHistory.length <= 1) {
    return const [];
  }
  return deliverable.rejectionHistory.sublist(1);
}
