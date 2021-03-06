import 'dart:io';

import 'package:dcli/dcli.dart' as d;
import 'package:dcli/dcli.dart';
import 'package:docker2/docker2.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:settings_yaml/settings_yaml.dart';

class ConfigYaml {
  static final _self = ConfigYaml._internal();
  static const configDir = '.nginx-le';
  static const configFile = 'settings.yaml';
  static const MODE_PUBLIC = 'public';
  static const MODE_PRIVATE = 'private';
  static const CERTIFICATE_TYPE_PRODUCTION = 'production';
  static const CERTIFICATE_TYPE_STAGING = 'staging';

  static const START_METHOD_NGINX_LE = 'nginx-le';
  static const START_METHOD_DOCKER_START = 'docker start/run';
  static const START_METHOD_DOCKER_COMPOSE = 'docker-compose';

  late SettingsYaml settings;

  /// keys
  static const START_METHOD_KEY = 'start-method';
  static const START_PAUSED = 'start-paused';
  static const MODE_KEY = 'mode';
  static const HOSTNAME_KEY = 'host';
  static const FQDN_KEY = 'fqdn';
  static const TLD_KEY = 'tld';
  static const IMAGE = 'image';
  static const CONTAINERID = 'containerid';
  static const EMAILADDRESS = 'emailaddress';
  static const CERTIFICATE_TYPE = 'certificate_type';
  static const HOST_INCLUDE_PATH = 'host_include_path';
  static const CONTENT_PROVIDER = 'content_provider';
  static const AUTH_PROVIDER = 'auth_provider';
  static const WWW_ROOT = 'www_root';

  static const SMTP_SERVER = 'smtp_server';
  static const SMTP_SERVER_PORT = 'smtp_server_port';
  static const DOMAIN_WILDCARD = 'domain_wildcard';

  // defaults:
  static const DEFAULT_HOST_INCLUDE_PATH = '/opt/nginx/include';

  String? startMethod;
  String? mode;
  bool? startPaused;
  String? fqdn;
  String? tld;
  Image? image;

  String? certificateType;

  /// the name of the container to run
  String? containerid;

  /// email
  String? emailaddress;
  String? smtpServer;
  int smtpServerPort = 25;

  /// If true we are using a wildcard dns (e.g. *.clouddialer.com.au)
  bool domainWildcard = false;

  // The name of the selected [ContentProvider]
  String? contentProvider;

  /// host path which is mounted into ngix and contains .location and .upstream files from.
  String? _hostIncludePath;

  /// the DNS authentication provider to be used by certbot
  String? authProvider;

  factory ConfigYaml() => _self;

  ConfigYaml._internal() {
    if (!d.exists(d.dirname(configPath))) {
      d.createDir(d.dirname(configPath), recursive: true);
    }

    settings = SettingsYaml.load(pathToSettings: configPath);
    startMethod = settings[START_METHOD_KEY] as String?;
    mode = settings[MODE_KEY] as String?;
    startPaused = settings[Environment().startPausedKey] as bool?;
    fqdn = settings[FQDN_KEY] as String?;
    tld = settings[TLD_KEY] as String?;
    image = Images().findByImageId((settings[IMAGE] as String?)!);
    certificateType = settings[CERTIFICATE_TYPE] as String?;
    emailaddress = settings[EMAILADDRESS] as String?;
    containerid = settings[CONTAINERID] as String?;
    authProvider = settings[AUTH_PROVIDER] as String?;
    contentProvider = settings[CONTENT_PROVIDER] as String?;
    _hostIncludePath = settings[HOST_INCLUDE_PATH] as String?;

    smtpServer = settings[Environment().smtpServerKey] as String?;
    smtpServerPort = settings[Environment().smtpServerPortKey] as int? ?? 25;

    /// If true we are using a wildcard dns (e.g. *.clouddialer.com.au)
    domainWildcard =
        ((settings[Environment().domainWildcardKey] as bool?) ?? false);
  }

  ///
  bool get isConfigured => d.exists(configPath) && fqdn != null;

  bool get isProduction =>
      certificateType == ConfigYaml.CERTIFICATE_TYPE_PRODUCTION;

  bool get isModePrivate => mode == MODE_PRIVATE;
  String? get hostIncludePath {
    _hostIncludePath ??= DEFAULT_HOST_INCLUDE_PATH;
    if (_hostIncludePath!.isEmpty) {
      _hostIncludePath = DEFAULT_HOST_INCLUDE_PATH;
    }
    return _hostIncludePath;
  }

  String? get domain {
    if (fqdn == null) return '';

    if (fqdn!.contains('.')) {
      /// return everything but the first part (hostname).
      return fqdn!.split('.').sublist(1).join('.');
    }

    return fqdn;
  }

  String? get hostname {
    if (fqdn == null) return '';

    if (fqdn!.contains('.')) {
      return fqdn!.split('.')[0];
    }

    return fqdn;
  }

  set hostIncludePath(String? hostIncludePath) {
    _hostIncludePath = hostIncludePath;
  }

  void save() {
    settings[START_METHOD_KEY] = startMethod;
    settings[MODE_KEY] = mode;
    settings[Environment().startPausedKey] = startPaused;
    settings[FQDN_KEY] = fqdn;
    settings[TLD_KEY] = tld;
    settings[IMAGE] = '${image?.imageid}';
    settings[CERTIFICATE_TYPE] = certificateType;
    settings[EMAILADDRESS] = emailaddress;
    settings[CONTAINERID] = containerid;
    settings[AUTH_PROVIDER] = authProvider;
    settings[CONTENT_PROVIDER] = contentProvider;
    settings[HOST_INCLUDE_PATH] = hostIncludePath;

    settings[Environment().smtpServerKey] = smtpServer;
    settings[Environment().smtpServerPortKey] = smtpServerPort;
    settings[Environment().domainWildcardKey] = domainWildcard;

    settings.save();
  }

  String get configPath {
    return d.join(d.HOME, configDir, configFile);
  }

  void validate(void Function() showUsage) {
    if (!isConfigured) {
      printerr(red(
          "A saved configuration doesn't exist. You must use first run 'nginx-le config."));
      showUsage();
    }

    if (image == null) {
      printerr(red(
          "Your configuration is in an inconsistent state. (image is null). Run 'nginx-le config'."));
      showUsage();
    }

    if (containerid == null) {
      printerr(red(
          "Your configuration is in an inconsistent state. (containerid is null). Run 'nginx-le config'."));
      showUsage();
    }

    if (!Containers().existsByContainerId(containerid!)) {
      printerr(red('The ngnix-le container $containerid no longer exists.'));
      printerr(red('  Run nginx-le config to change the container.'));
      exit(1);
    }
    if (!Images().existsByImageId(imageid: image!.imageid!)) {
      printerr(red('The ngnix-le image ${image!.imageid} no longer exists.'));
      printerr(red('  Run nginx-le config to change the image.'));
      exit(1);
    }
  }
}
