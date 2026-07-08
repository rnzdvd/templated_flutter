import 'package:test/test.dart';
import 'package:{{package_name}}/store.dart';

import '{{usecase_name.snakeCase()}}.case.dart';

void main() {
  group('{{usecase_name.sentenceCase()}}', () {
    late {{usecase_name.pascalCase()}}Case useCase;

    final store = Store();

    setUp(() {
      useCase = {{usecase_name.pascalCase()}}Case();
    });

    test('execute', () async {
      await useCase.execute();
      expect(true, isTrue);
    });
  });
}
