import '../supabase/supabase_client.dart';

class CommissionConfig {
  static Future<double> _getVal(String key, double defaultValue) async {
    try {
      final res = await SupabaseConfig.client
          .from('app_config')
          .select('valeur')
          .eq('cle', key)
          .maybeSingle();
      if (res != null && res['valeur'] != null) {
        return double.parse(res['valeur'].toString());
      }
    } catch (_) {}
    return defaultValue;
  }

  static Future<double> get commissionBusinessRate => _getVal('commission_business_rate', 0.25);
  static Future<double> get businessRate => _getVal('business_rate', 0.75);
  static Future<double> get livreurRate => _getVal('livreur_rate', 0.85);
  static Future<double> get appLivraisonRate => _getVal('app_livraison_rate', 0.15);
  static Future<double> get prixParKm => _getVal('prix_par_km', 1.5);
}
