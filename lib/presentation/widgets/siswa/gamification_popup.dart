import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:lottie/lottie.dart'; // Aktifkan jika package lottie sudah diinstal

class GamificationPopup extends StatelessWidget {
  final int xpGained;
  final int? newLevel;
  final List<String> newBadges;

  const GamificationPopup({
    Key? key,
    required this.xpGained,
    this.newLevel,
    this.newBadges = const [],
  }) : super(key: key);

  static void show(BuildContext context, {
    required int xpGained,
    int? newLevel,
    List<String> newBadges = const [],
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GamificationPopup(
        xpGained: xpGained,
        newLevel: newLevel,
        newBadges: newBadges,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLevelUp = newLevel != null;
    bool hasBadges = newBadges.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animasi Perayaan
            SizedBox(
              height: 150,
              // Ganti dengan Lottie.asset('assets/animations/celebration.json') jika lottie sudah siap
              child: Icon(
                isLevelUp ? Icons.military_tech_rounded : Icons.star_rounded,
                size: 100,
                color: Colors.amber.shade500,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              isLevelUp ? 'Level Up!' : 'Selamat!',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade900,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              '+$xpGained XP',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.green.shade600,
              ),
            ),
            
            if (isLevelUp) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Kamu mencapai Level $newLevel',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ),
            ],

            if (hasBadges) ...[
              const SizedBox(height: 16),
              Text(
                'Badge Baru Terbuka:',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: newBadges.map((badge) => Chip(
                  avatar: const Icon(Icons.shield, color: Colors.amber, size: 18),
                  label: Text(
                    badge,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                  backgroundColor: Colors.amber.shade50,
                  side: BorderSide(color: Colors.amber.shade200),
                )).toList(),
              ),
            ],
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Keren!',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
