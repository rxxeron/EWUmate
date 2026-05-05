import 'package:supabase_flutter/supabase_flutter.dart';

void testSignout() {
  Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
}
