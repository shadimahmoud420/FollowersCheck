import 'package:badelha/core/utils/errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('maps RPC error codes to Arabic messages', () {
    expect(friendlyError(const PostgrestException(message: 'duplicate_pending_offer')),
        contains('عرض معلّق'));
    expect(friendlyError(const PostgrestException(message: 'requested_items_unavailable')),
        contains('لم يعد متاحاً'));
  });

  test('network errors get a connectivity message', () {
    expect(friendlyError(Exception('SocketException: Failed host lookup')), contains('اتصال'));
  });

  test('unknown errors get a generic message', () {
    expect(friendlyError(Exception('boom')), contains('خطأ غير متوقع'));
  });
}
