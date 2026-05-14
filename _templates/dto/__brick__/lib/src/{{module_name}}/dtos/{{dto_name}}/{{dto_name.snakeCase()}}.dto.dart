// ignore_for_file: non_constant_identifier_names
import 'package:freezed_annotation/freezed_annotation.dart';

part '{{dto_name.snakeCase()}}.dto.freezed.dart';
part '{{dto_name.snakeCase()}}.dto.g.dart';

@freezed
class {{dto_name.pascalCase()}}DTO with _${{dto_name.pascalCase()}}DTO {
  const factory {{dto_name.pascalCase()}}DTO({
    // Add your fields here
  }) = _{{dto_name.pascalCase()}}DTO;

  factory {{dto_name.pascalCase()}}DTO.fromJson(Map<String, dynamic> json) =>
      _${{dto_name.pascalCase()}}DTOFromJson(json);
}
