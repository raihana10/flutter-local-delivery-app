class Formatters {
  /// Formate un montant en MAD
  /// Ex: 1340 → "1,340 MAD"
  static String toMAD(double amount) {
    if (amount >= 1000) {
      final formatted = amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
      return '$formatted MAD';
    }
    return '${amount.toStringAsFixed(0)} MAD';
  }

  /// Formate une distance
  /// Ex: 1.2 → "1.2 km"
  static String toKm(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  /// Formate un temps en secondes → "45s" ou "2min"
  static String toTimer(int seconds) {
    if (seconds >= 60) {
      return '${(seconds / 60).floor()}min';
    }
    return '${seconds}s';
  }

  /// Formate une heure HH:mm
  /// Ex: DateTime → "14:30"
  static String toHourMin(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Formatters._();
}
