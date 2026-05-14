import 'package:envied/envied.dart';

part 'env.g.dart';

const isProduction = String.fromEnvironment('IS_PRODUCTION') == '1';

@Envied(path: isProduction ? '.env.prod' : '.env.dev', obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'API_URL')
  static final String apiUrl = _Env.apiUrl;
}
