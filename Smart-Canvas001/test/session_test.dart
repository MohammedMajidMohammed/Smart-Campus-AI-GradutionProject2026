import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Test session properties', () {
    // Check if Session is defined and what properties/methods it has
    final session = Session(
      accessToken: 'test',
      tokenType: 'test',
      user: User(
        id: 'test',
        appMetadata: {},
        userMetadata: {},
        aud: 'test',
        createdAt: 'test',
      ),
    );

    print('Session expiresAt: ${session.expiresAt}');
    print('Session expiresAt DateTime: ${DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)}');
    print('Session isExpired: ${session.isExpired}');
  });
}
