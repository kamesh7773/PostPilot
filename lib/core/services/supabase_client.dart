import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_client.g.dart';

/// The Supabase client initialised in `main_*.dart`. Used for auth only —
/// app data goes through our backend (`apiClientProvider`), never directly
/// to Supabase tables.
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;
