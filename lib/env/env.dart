import 'package:envied/envied.dart';

// This is necessary for the generator to create the implementation file
part 'env.g.dart';

@Envied(path: '.env') // Specifies the path to your .env file
abstract class Env {
  // The `varName` must match the key in your .env file
  // The generator will create a static variable with the same name as the field
  @EnviedField(varName: 'ALGOLIA_APP_ID', obfuscate: true)
  static final String algoliaAppId = _Env.algoliaAppId;

  @EnviedField(varName: 'ALGOLIA_API_KEY', obfuscate: true)
  static final String algoliaApiKey = _Env.algoliaApiKey;
}
