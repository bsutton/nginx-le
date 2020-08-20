import 'package:dshell/dshell.dart';
import 'package:nginx_le_shared/src/certbot/certbot.dart';

class Environment {
  static final _self = Environment._internal();
  factory Environment() => _self;

  Environment._internal();

  bool get debug => env('DEBUG') == 'true';
  set debug(bool _debug) => setEnv('DEBUG', '$_debug');

  bool get certbotVerbose => env('CERTBOT_VERBOSE') == 'true';
  set certbotVerbose(bool certbotVerbose) => setEnv('CERTBOT_VERBOSE', '$certbotVerbose');

  String get hostname => env('HOSTNAME');
  set hostname(String _hostname) => setEnv('HOSTNAME', _hostname);

  String get domain => env('DOMAIN');
  set domain(String domain) => setEnv('DOMAIN', domain);

  String get tld => env('TLD');
  set tld(String tld) => setEnv('TLD', tld);

  String get emailaddress => env('EMAIL_ADDRESS');
  set emailaddress(String emailaddress) => setEnv('EMAIL_ADDRESS', emailaddress);

  String get mode => env('MODE');
  set mode(String mode) => setEnv('MODE', mode);

  bool get staging => (env('STAGING') ?? 'false') == 'true';
  set staging(bool staging) => setEnv('STAGING', '$staging');

  bool get autoAcquire => (env('AUTO_ACQUIRE') ?? 'true') == 'true';
  set autoAcquire(bool autoAcquire) => setEnv('AUTO_ACQUIRE', '$autoAcquire');

  String get namecheapApiKey => env('NAMECHEAP_API_KEY');
  set namecheapApiKey(String namecheapApiKey) => setEnv('NAMECHEAP_API_KEY', namecheapApiKey);
  String get namecheapApiUser => env('NAMECHEAP_API_USER');
  set namecheapApiUser(String namecheapApiUser) => setEnv('NAMECHEAP_API_USER', namecheapApiUser);

  String get certbotRoot => env(Certbot.LETSENCRYPT_ROOT_ENV);
  set certbotRoot(String letsencryptDir) => setEnv(Certbot.LETSENCRYPT_ROOT_ENV, letsencryptDir);

  String get certbotDomain => env('CERTBOT_DOMAIN');
  set certbotDomain(String domain) => setEnv('CERTBOT_DOMAIN', domain);

  String get certbotValidation => env('CERTBOT_VALIDATION');
  set certbotValidation(String token) => setEnv('CERTBOT_VALIDATION', token);

  String get certbotToken => env('CERTBOT_TOKEN');
  set certbotToken(String token) => setEnv('CERTBOT_TOKEN', token);

  String get certbotRootOverwrite => env(Certbot.NGINX_CERT_ROOT_OVERWRITE);
  set certbotRootOverwrite(String overwriteDir) => setEnv(Certbot.NGINX_CERT_ROOT_OVERWRITE, overwriteDir);

  String get certbotDNSAuthHookPath => env('CERTBOT_DNS_AUTH_HOOK_PATH');
  set certbotDNSAuthHookPath(String path) => setEnv('CERTBOT_DNS_AUTH_HOOK_PATH', path);

  String get certbotDNSCleanupHookPath => env('CERTBOT_DNS_CLEANUP_HOOK_PATH');
  set certbotDNSCleanupHookPath(String path) => setEnv('CERTBOT_DNS_CLEANUP_HOOK_PATH', path);

  int get certbotDNSRetries => int.tryParse(env('DNS_RETRIES') ?? '20') ?? 20;
  set certbotDNSRetries(int retries) => setEnv('DNS_RETRIES', 'retries');
}