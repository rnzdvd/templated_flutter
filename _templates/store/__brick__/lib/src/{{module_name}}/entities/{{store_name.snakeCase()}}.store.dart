import 'package:mobx/mobx.dart';

part '{{store_name.snakeCase()}}.store.g.dart';

class {{store_name.pascalCase()}}Store = {{store_name.pascalCase()}}StoreBase with _${{store_name.pascalCase()}}Store;

abstract class {{store_name.pascalCase()}}StoreBase with Store {}
