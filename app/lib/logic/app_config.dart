enum AppEnvironment { dev, prod }

class AppConfig {
  static AppEnvironment environment = AppEnvironment.dev;

  static String get googleServerClientId => switch (environment) {
    AppEnvironment.prod =>
      '847947122489-kbpqd3e7m8b3aehd3ah9714rgsd10es3.apps.googleusercontent.com',
    AppEnvironment.dev =>
      '688587508865-fhe9rghlo1f909rn8t7vqjvld7km36sl.apps.googleusercontent.com',
  };
}
