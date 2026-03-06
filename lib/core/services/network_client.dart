import 'package:http/http.dart' as http;

class NetworkClient {
  final String _baseUrl;
  final List<String> _pinnedCertificates; // PEM strings

  NetworkClient({required String baseUrl, required List<String> pinnedCertificates})
      : _baseUrl = baseUrl,
        _pinnedCertificates = pinnedCertificates;

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    // Perform SSL pinning check before the request
    final isValid = await HttpCertificatePinning.checkCertificate(
      serverURL: _baseUrl,
      headerHttp: {},
      sha: _pinnedCertificates,
      timeout: const Duration(seconds: 10),
    );
    if (!isValid) {
      throw Exception('SSL pinning validation failed for $_baseUrl');
    }
    return await http.get(url);
  }

  // Add other HTTP methods (post, put, delete) as needed, following the same pinning logic.
}
