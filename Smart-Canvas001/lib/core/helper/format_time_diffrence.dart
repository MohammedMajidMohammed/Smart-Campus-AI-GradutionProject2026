String formatTimeDifference(DateTime createdAt) {
  final difference = DateTime.now().difference(createdAt);

  if (difference.inSeconds < 60) {
    return '${difference.inSeconds} Seconds Ago';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} Minutes Ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} Hours Ago';
  } else if (difference.inDays < 30) {
    return '${difference.inDays} Days Ago';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return '$months Months Ago';
  } else {
    final years = (difference.inDays / 365).floor();
    return '$years Years Ago';
  }
}
