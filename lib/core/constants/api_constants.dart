class ApiConstants {
  // Using the machine's specific local IPv4 address so that a physical
  // device on the same Wi-Fi/Network can connect to XAMPP.
  static const String baseUrl = 'http://10.81.232.26/ai-job-portal/public/api';

  static String resolveImageUrl(String path) {
    var trimmed = path.trim();
    if (trimmed.isEmpty) return '';

    // Extract target authority/host from baseUrl
    String targetAuthority = 'localhost';
    try {
      final uri = Uri.parse(baseUrl);
      targetAuthority =
          uri.authority; // E.g. "10.140.197.26" or "10.140.197.26:8080"
    } catch (_) {}

    if (trimmed.contains('localhost')) {
      trimmed = trimmed.replaceAll('localhost', targetAuthority);
    } else if (trimmed.contains('127.0.0.1')) {
      trimmed = trimmed.replaceAll('127.0.0.1', targetAuthority);
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final cleanPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    final base = baseUrl.replaceAll('/api', '');
    return '$base/$cleanPath';
  }
}
