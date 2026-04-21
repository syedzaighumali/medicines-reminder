import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Supabase Connection Test', () async {
    try {
      final client = SupabaseClient(
        'https://xbauyhsrtldtkthwsrwt.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhiYXV5aHNydGxkdGt0aHdzcnd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYzMzI1NDcsImV4cCI6MjA5MTkwODU0N30.C8EszdRKLuQKaCldVVK1UfWaBTvEOMf4IbfnD5xm-ik',
      );

      await client.from('medicines').select().limit(1);
      print('Connection successful, response: \$response');
    } catch (e) {
      print('Supabase query failed: \$e');
      fail(e.toString());
    }
  });
}
