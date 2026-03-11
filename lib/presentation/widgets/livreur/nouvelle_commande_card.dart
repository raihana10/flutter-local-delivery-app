import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/commande_model.dart';

class NouvelleCommandeCard extends StatefulWidget {
  final CommandeModel commande;
  final VoidCallback onAccepter;
  final VoidCallback onRefuser;

  const NouvelleCommandeCard({
    super.key,
    required this.commande,
    required this.onAccepter,
    required this.onRefuser,
  });

  @override
  State<NouvelleCommandeCard> createState() => _NouvelleCommandeCardState();
}

class _NouvelleCommandeCardState extends State<NouvelleCommandeCard> {
  late int _secondsLeft;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.commande.tempsRestant;
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        widget.onRefuser(); // Auto-refus si timer expire
        return false;
      }
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.yellow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header : titre + timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.nouvelleCommande,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.commande.restaurant} · ${widget.commande.distance.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.navyDark,
                    ),
                  ),
                ],
              ),
              // Timer
              Text(
                '$_secondsLeft',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Prix
          Text(
            '${widget.commande.prix.toStringAsFixed(0)} MAD',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.navyDark,
            ),
          ),

          const SizedBox(height: 14),

          // Boutons
          Row(
            children: [
              // Accepter
              Expanded(
                child: GestureDetector(
                  onTap: widget.onAccepter,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color:        AppColors.navyDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      AppStrings.accepter,
                      style: TextStyle(
                        color:      AppColors.textWhite,
                        fontWeight: FontWeight.w600,
                        fontSize:   15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Refuser
              Expanded(
                child: GestureDetector(
                  onTap: widget.onRefuser,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color:        Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border:       Border.all(color: AppColors.navyDark, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      AppStrings.refuser,
                      style: TextStyle(
                        color:      AppColors.navyDark,
                        fontWeight: FontWeight.w600,
                        fontSize:   15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}