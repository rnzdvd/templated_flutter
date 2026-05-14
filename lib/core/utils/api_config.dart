const String baseUrl = 'https://dummyjson.com/';
const String originUrl = 'https://dummyjson.com/';

class ApiConfig {
  final String? url;
  final String? originUrl;
  final Duration timeout;
  final Map<String, dynamic> headers;

  ApiConfig({
    this.url,
    this.originUrl,
    required this.timeout,
    required this.headers,
  });
}

final ApiConfig defaultApiConfig = ApiConfig(
  url: baseUrl,
  originUrl: originUrl,
  timeout: const Duration(milliseconds: 120000), // 120 seconds
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Cache-Control': 'no-store',
  },
);
