import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'Comment suivre ma commande ?',
      'answer': 'Vous pouvez suivre votre commande en temps réel depuis l\'onglet "Historique" ou via le bouton de suivi sur l\'écran d\'accueil après avoir passé commande.'
    },
    {
      'question': 'Puis-je annuler ma commande ?',
      'answer': 'L\'annulation est possible tant que le restaurant n\'a pas commencé la préparation. Contactez le support rapidement pour toute demande.'
    },
    {
      'question': 'Quels sont les modes de paiement ?',
      'answer': 'Nous acceptons le paiement à la livraison, par carte bancaire et via Apple/Google Pay.'
    },
    {
      'question': 'Un article est manquant, que faire ?',
      'answer': 'Veuillez nous contacter via le chat intégré ou appeler notre support client avec votre numéro de commande.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Support & FAQ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactCards(),
            const SizedBox(height: 32),
            const Text(
              'Questions Fréquentes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            ..._faqs.map((faq) => _buildFaqItem(faq['question']!, faq['answer']!)).toList(),
          ],
        ),
      ),
      bottomNavigationBar: _buildChatButton(),
    );
  }

  Widget _buildContactCards() {
    return Row(
      children: [
        Expanded(
          child: _buildContactCard(
            'Appelez-nous',
            Icons.phone_in_talk,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildContactCard(
            'Email',
            Icons.mail_outline,
            AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.primary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(color: AppColors.mutedForeground, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ouverture du chat de support...')),
            );
          },
          icon: const Icon(Icons.chat_bubble_rounded),
          label: const Text('Discuter avec un conseiller',
              style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
