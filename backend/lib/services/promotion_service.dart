import 'package:dotenv/dotenv.dart';
import 'email_service.dart';
import '../supabase/supabase_client.dart';

/// Service pour gérer les promotions et leurs notifications
class PromotionService {
  final EmailService emailService;

  PromotionService({required this.emailService});

  /// Récupère les emails des clients qui ont ce business en favoris
  Future<List<String>> getClientsEmailsForBusiness(int businessId) async {
    try {
      // 1. Récupérer les id_client du business en favoris
      final favorisClients = await SupabaseConfig.client
          .from('favoris')
          .select('id_client')
          .eq('id_business', businessId)
          .isFilter('deleted_at', null);

      final favorisClientIds = (favorisClients as List)
          .map((fav) => fav['id_client'] as int)
          .toList();

      if (favorisClientIds.isEmpty) {
        return [];
      }

      // 2. Récupérer les emails via app_user
      final clientsData = await SupabaseConfig.client
          .from('client')
          .select('id_user')
          .inFilter('id_client', favorisClientIds);

      final userIds = (clientsData as List)
          .map((c) => c['id_user'] as int)
          .toList();

      if (userIds.isEmpty) {
        return [];
      }

      // 3. Récupérer les emails des utilisateurs
      final users = await SupabaseConfig.client
          .from('app_user')
          .select('email')
          .inFilter('id_user', userIds);

      return (users as List)
          .map((u) => u['email'] as String)
          .where((email) => email.isNotEmpty)
          .toList();
    } catch (e) {
      print('❌ ERREUR récupération emails: $e');
      return [];
    }
  }

  /// Envoie un email de promotion aux clients favoris
  Future<void> sendPromotionEmail({
    required String businessName,
    required String productName,
    required double discount,
    required List<String> clientEmails,
  }) async {
    if (clientEmails.isEmpty) {
      print('ℹ️ Aucun email à envoyer');
      return;
    }

    final subject = '🎉 Nouvelle promotion chez $businessName !';
    final html = _buildPromotionEmailHtml(
      businessName: businessName,
      productName: productName,
      discount: discount,
    );

    try {
      for (var email in clientEmails) {
        await emailService.sendToUser(
          to: email,
          subject: subject,
          html: html,
        );
      }
      print('📧 Emails de promotion envoyés à ${clientEmails.length} clients');
    } catch (e) {
      print('❌ ERREUR envoi emails promotion: $e');
    }
  }

  /// Construit le HTML du email de promotion
  String _buildPromotionEmailHtml({
    required String businessName,
    required String productName,
    required double discount,
  }) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            body { font-family: Arial, sans-serif; background-color: #f5f5f5; }
            .container { max-width: 600px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; text-align: center; }
            .content { padding: 20px; }
            .discount { font-size: 48px; color: #ff6b6b; font-weight: bold; text-align: center; }
            .product { font-size: 24px; color: #333; text-align: center; margin: 20px 0; }
            .cta { text-align: center; margin: 30px 0; }
            .button { background-color: #667eea; color: white; padding: 12px 30px; border-radius: 5px; text-decoration: none; display: inline-block; }
            .footer { color: #999; font-size: 12px; text-align: center; margin-top: 20px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎉 Promotion Spéciale !</h1>
            </div>
            <div class="content">
                <p>Bonjour,</p>
                <p>Votre restaurant favori <strong>$businessName</strong> propose une nouvelle promotion !</p>
                <div class="product">$productName</div>
                <div class="discount">-$discount%</div>
                <p style="text-align: center; color: #666;">Une offre exclusive pour vous ! 🎁</p>
                <div class="cta">
                    <a href="https://rqzfukgpnyvrcxlrhblh.supabase.co" class="button">Découvrir l'offre</a>
                </div>
                <p style="color: #999; font-size: 12px;">Cette promotion est valable pour une durée limitée. Dépêchez-vous de en profiter !</p>
            </div>
            <div class="footer">
                <p>© 2026 Livraison Locale - Tous droits réservés</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }
}
