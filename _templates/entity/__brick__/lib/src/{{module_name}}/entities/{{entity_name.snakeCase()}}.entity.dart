import 'package:{{package_name}}/core/utils/base_api_mapped.entity.dart';
import 'package:mobx/mobx.dart';

part '{{entity_name.snakeCase()}}.entity.g.dart';


abstract class {{entity_name.pascalCase()}}EntityBase extends BaseApiMappedEntity<dynamic, dynamic> with Store {

  @override
  void setFromApiModel(dynamic data) {
    // Use this method if the data is comes from an API response
  }

  @override
  void setFromFormModel(dynamic data) {
    // Use this method if the data is comes from a FORM submission
  }
}

class {{entity_name.pascalCase()}}Entity extends {{entity_name.pascalCase()}}EntityBase with _${{entity_name.pascalCase()}}Entity {
  {{entity_name.pascalCase()}}Entity();

  factory {{entity_name.pascalCase()}}Entity.fromApi(dynamic data) {
    final entity = {{entity_name.pascalCase()}}Entity();
    entity.setFromApiModel(data);
    return entity;
  }

  static List<{{entity_name.pascalCase()}}Entity> fromApiList(List<dynamic> dataList) {
    return dataList.map((data) => {{entity_name.pascalCase()}}Entity.fromApi(data)).toList();
  }

  factory {{entity_name.pascalCase()}}Entity.fromForm(dynamic data) {
    final entity = {{entity_name.pascalCase()}}Entity();
    entity.setFromFormModel(data);
    return entity;
  }
}
