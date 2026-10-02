import 'package:supabase_flutter/supabase_flutter.dart';

/// يحوّل أخطاء الخادم (رموز RPC) إلى رسائل عربية مفهومة.
String friendlyError(Object error) {
  final raw = switch (error) {
    PostgrestException e => e.message,
    AuthException e => e.message,
    StorageException e => e.message,
    _ => error.toString(),
  };
  for (final entry in _messages.entries) {
    if (raw.contains(entry.key)) return entry.value;
  }
  if (raw.contains('SocketException') ||
      raw.contains('ClientException') ||
      raw.contains('Failed host lookup') ||
      raw.contains('Connection')) {
    return 'لا يوجد اتصال بالإنترنت. حاول مرة أخرى عند عودة الشبكة.';
  }
  return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
}

const _messages = <String, String>{
  'items_required': 'اختر غرضاً واحداً على الأقل من كل طرف.',
  'too_many_items': 'الحد الأقصى 5 أغراض في كل طرف.',
  'invalid_cash': 'تحقق من مبلغ الفرق ومن سيدفعه.',
  'requested_items_unavailable': 'هذا الغرض لم يعد متاحاً.',
  'offered_items_unavailable': 'أحد أغراضك لم يعد متاحاً للتبادل.',
  'cannot_offer_to_self': 'لا يمكنك تقديم عرض على غرضك.',
  'too_many_pending_offers': 'لديك عروض معلّقة كثيرة. انتظر الردود أو ألغِ بعضها.',
  'duplicate_pending_offer': 'لديك عرض معلّق على هذا الغرض بالفعل.',
  'invalid_counter_offer': 'لا يمكن الرد على هذا العرض الآن.',
  'offer_not_found': 'العرض غير موجود.',
  'offer_not_pending': 'تم الرد على هذا العرض مسبقاً.',
  'items_no_longer_available': 'أحد الأغراض لم يعد متاحاً.',
  'cannot_cancel': 'لا يمكن إلغاء هذا العرض.',
  'offer_not_accepted': 'العرض لم يُقبل بعد.',
  'swap_not_completed': 'يمكنك التقييم بعد إتمام التبادل.',
  'already_rated': 'لقد قيّمت هذا التبادل مسبقاً.',
  'account_banned': 'تم إيقاف حسابك. تواصل مع الدعم.',
  'profile_required': 'أكمل ملفك الشخصي أولاً.',
  'blocked': 'لا يمكن إتمام العملية مع هذا المستخدم.',
  'invalid_status_transition': 'لا يمكن تغيير حالة هذا الإعلان الآن.',
  'Token has expired or is invalid': 'الرمز غير صحيح أو منتهي الصلاحية.',
  'rate limit': 'محاولات كثيرة. انتظر قليلاً ثم حاول.',
};
