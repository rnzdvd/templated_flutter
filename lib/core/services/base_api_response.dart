class BaseApiResponse<T> {
  final int statusCode;
  final T data;

  BaseApiResponse({required this.statusCode, required this.data});

  bool isSuccess() {
    return statusCode >= 200 && statusCode < 300;
  }
}
