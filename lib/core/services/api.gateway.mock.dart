import 'package:mocktail/mocktail.dart';
import 'package:templated_flutter/core/services/api.gateway.dart';
import 'package:templated_flutter/store.dart';

class MockApiGateway extends Mock implements ApiGateway {}

ApiGateway apiMockGateway() {
  final store = Store();
  final apiGateway = MockApiGateway();

  // Stub gateway methods here as they're added to ApiGateway, e.g.:
  //
  // when(() => apiGateway.login(...)).thenAnswer(
  //   (_) async => BaseApiResponse(statusCode: 200, data: ...),
  // );

  return apiGateway;
}
