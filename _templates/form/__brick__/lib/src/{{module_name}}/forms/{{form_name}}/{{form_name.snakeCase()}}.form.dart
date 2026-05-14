import 'package:freezed_annotation/freezed_annotation.dart';

part '{{form_name.snakeCase()}}.form.freezed.dart';
part '{{form_name.snakeCase()}}.form.g.dart';

@freezed
class {{form_name.pascalCase()}}FormModel with _${{form_name.pascalCase()}}FormModel {
  const factory {{form_name.pascalCase()}}FormModel({
    // Add your required fields here
    // Example: required String email,
    required String key
  }) = _{{form_name.pascalCase()}}FormModel;

  factory {{form_name.pascalCase()}}FormModel.fromJson(Map<String, dynamic> json) =>
      _${{form_name.pascalCase()}}FormModelFromJson(json);
}
