import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'package:app/data/models/commande_supabase_model.dart';
import '../../../data/models/commande_model.dart';
import 'commande_details_dialog.dart';

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header : titre + timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded, size: 20, color: AppColors.navyDark),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.commande.restaurant,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.navyDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: AppColors.mutedForeground),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.commande.distance.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Timer Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_rounded, size: 14, color: AppColors.red),
                    const SizedBox(width: 4),
                    Text(
                      '$_secondsLeft s',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.border, height: 1),
          ),
          
          if (widget.commande is CommandeSupabaseModel && (widget.commande as CommandeSupabaseModel).items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (widget.commande as CommandeSupabaseModel).items.take(2).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: AppColors.mutedForeground, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedForeground,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList()..addAll([
                  if ((widget.commande as CommandeSupabaseModel).items.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+ ${(widget.commande as CommandeSupabaseModel).items.length - 2} autres articles',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.navyMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                ]),
              ),
            ),

          // Prix
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total commande',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.commande.fraisLivraison != null && widget.commande.fraisLivraison! > 0)
                    Text(
                      '+ Vous gagnez: ${widget.commande.fraisLivraison!.toStringAsFixed(2)} MAD',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.yellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              Text(
                '${widget.commande.prix.toStringAsFixed(2)} MAD',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.forest,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Boutons
          Row(
            children: [
              OutlinedButton(
                onPressed: widget.onRefuser,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  foregroundColor: AppColors.red,
                  side: const BorderSide(color: AppColors.red, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.close_rounded, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onAccepter,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.forest,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Accepter',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => CommandeDetailsDialog(
                    commande: widget.commande,
                    onAccepter: widget.onAccepter,
                    onRefuser: widget.onRefuser,
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.navyMedium,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Voir les détails', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}