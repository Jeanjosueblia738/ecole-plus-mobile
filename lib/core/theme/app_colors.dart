import 'package:flutter/material.dart';

// ─── Palette principale ECOLE+ ────────────────────────────────────────────
const Color primaryBlue = Color(0xFF1E3A8A); // Confiance, institution
const Color primaryLight = Color(0xFF3B6FD4); // Variante claire
const Color primaryDark = Color(0xFF152A6E); // Variante sombre

const Color successGreen = Color(0xFF16A34A); // Validation, admis
const Color successLight = Color(0xFFDCFCE7); // Fond succès

const Color dangerRed = Color(0xFFDC2626); // Absence, alerte
const Color dangerLight = Color(0xFFFEE2E2); // Fond danger

const Color warningYellow = Color(0xFFF59E0B); // Attention (mis à jour)
const Color warningLight = Color(0xFFFEF3C7); // Fond warning

const Color infoBlue = Color(0xFF2563EB); // Info, SMS
const Color infoLight = Color(0xFFEFF6FF); // Fond info

// ─── Neutrals ─────────────────────────────────────────────────────────────
const Color textDark = Color(0xFF111827);
const Color textMedium = Color(0xFF374151);
const Color textGrey = Color(0xFF6B7280);
const Color textLight = Color(0xFF9CA3AF);

const Color background = Color(0xFFF9FAFB);
const Color surfaceWhite = Color(0xFFFFFFFF);
const Color border = Color(0xFFE5E7EB);
const Color borderLight = Color(0xFFF3F4F6);

// ─── Dégradés ─────────────────────────────────────────────────────────────
const LinearGradient primaryGradient = LinearGradient(
  colors: [primaryBlue, primaryLight],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient successGradient = LinearGradient(
  colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ─── Shadows ──────────────────────────────────────────────────────────────
List<BoxShadow> get cardShadow => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];

List<BoxShadow> get elevatedShadow => [
      BoxShadow(
        color: primaryBlue.withValues(alpha: 0.2),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
