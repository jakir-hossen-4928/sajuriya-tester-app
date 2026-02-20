import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      throw Exception(
        'Supabase Error: You tried to access the Supabase client before the instance was initialized. '
        'Initialization happens in main() before runApp(). Check your .env for a valid SUPABASE_URL and SUPABASE_ANON_KEY.'
      );
    }
  }
}
