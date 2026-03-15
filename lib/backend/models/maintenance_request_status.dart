class MaintenanceRequestStatus {
  static const String pending = 'Pending';
  static const String inProgress = 'In Progress';
  static const String onHold = 'On Hold';
  static const String completed = 'Completed';
  static const String rejected = 'Rejected';

  static const List<String> ownerSelectableStatuses = <String>[
    pending,
    inProgress,
    onHold,
    completed,
    rejected,
  ];

  static String normalize(String value) {
    final cleaned = value.trim().toLowerCase();
    switch (cleaned) {
      case '':
      case 'open':
      case 'pending':
        return pending;
      case 'in progress':
      case 'in_progress':
      case 'inprogress':
        return inProgress;
      case 'on hold':
      case 'on_hold':
      case 'onhold':
        return onHold;
      case 'completed':
      case 'complete':
      case 'done':
      case 'closed':
        return completed;
      case 'rejected':
      case 'reject':
      case 'declined':
        return rejected;
      default:
        return pending;
    }
  }
}
