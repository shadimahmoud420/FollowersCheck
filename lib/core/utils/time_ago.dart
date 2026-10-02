String timeAgo(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
  if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
  final months = diff.inDays ~/ 30;
  if (months < 12) return 'منذ $months شهر';
  return 'منذ ${months ~/ 12} سنة';
}
