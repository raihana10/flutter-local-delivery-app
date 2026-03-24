import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import 'dart:async';

class InAppCallScreen extends StatefulWidget {
  final String contactName;
  final String phoneNumber;
  final String role; // 'Client' or 'Livreur'

  const InAppCallScreen({
    super.key,
    required this.contactName,
    required this.phoneNumber,
    required this.role,
  });

  @override
  State<InAppCallScreen> createState() => _InAppCallScreenState();
}

class _InAppCallScreenState extends State<InAppCallScreen> {
  int _secondsElapsed = 0;
  Timer? _timer;
  bool _isMuted = false;
  bool _isSpeaker = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    // Simulate connection delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isConnected = true;
          _startTimer();
        });
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            
            // Profile Info
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.forest.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.amber, width: 2),
              ),
              child: const Icon(LucideIcons.user, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              widget.contactName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.role,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isConnected ? _formatDuration(_secondsElapsed) : 'Appel en cours...',
              style: TextStyle(
                color: _isConnected ? AppColors.amber : Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
            
            const Spacer(),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildControlButton(
                    icon: _isMuted ? LucideIcons.micOff : LucideIcons.mic,
                    label: 'Sourdine',
                    isActive: _isMuted,
                    onTap: () {
                      setState(() {
                        _isMuted = !_isMuted;
                      });
                    },
                  ),
                  _buildControlButton(
                    icon: LucideIcons.layoutGrid,
                    label: 'Clavier',
                    isActive: false,
                    onTap: () {},
                  ),
                  _buildControlButton(
                    icon: _isSpeaker ? LucideIcons.volume2 : LucideIcons.volume1,
                    label: 'Haut-parleur',
                    isActive: _isSpeaker,
                    onTap: () {
                      setState(() {
                        _isSpeaker = !_isSpeaker;
                      });
                    },
                  ),
                ],
              ),
            ),

            // End Call Button
            Container(
              margin: const EdgeInsets.only(bottom: 60),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent,
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ]
                  ),
                  child: const Icon(LucideIcons.phoneOff, color: Colors.white, size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        )
      ],
    );
  }
}
