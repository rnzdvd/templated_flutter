
import 'package:{{package_name}}/store.dart';

class {{repository_name.pascalCase()}}Repository {
  final Store _store;

  {{repository_name.pascalCase()}}Repository({required Store store}) : _store = store;
}
