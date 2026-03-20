import 'package:supabase/supabase.dart';

void main() {
  final c = SupabaseClient('x', 'y');
  try {
    c.from('x').select().filter('deleted_at', 'is', 'null');
  } catch (e) {}
  try {
    c.from('x').select().is_('deleted_at', null);
  } catch (e) {}
  try {
    c.from('x').select().isNull('deleted_at');
  } catch (e) {}
}
