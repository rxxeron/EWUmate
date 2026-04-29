class VersionUtils {
  /// Returns true if 'latest' version is greater than 'current' version.
  /// Supports semantic versioning (e.g., "1.0.5", "1.1.0").
  static bool isUpdateAvailable(String current, String latest) {
    try {
      final currentParts = current.split('+').first.split('.');
      final latestParts = latest.split('+').first.split('.');

      final maxLength = currentParts.length > latestParts.length 
          ? currentParts.length 
          : latestParts.length;

      for (int i = 0; i < maxLength; i++) {
        final currentVal = i < currentParts.length ? int.parse(currentParts[i]) : 0;
        final latestVal = i < latestParts.length ? int.parse(latestParts[i]) : 0;

        if (latestVal > currentVal) return true;
        if (currentVal > latestVal) return false;
      }
    } catch (e) {
      // Fallback if parsing fails
      return false;
    }
    return false;
  }
}
