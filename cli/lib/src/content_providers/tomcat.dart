import 'package:dcli/dcli.dart';
import 'package:nginx_le/src/content_providers/content_provider.dart';
import 'package:nginx_le/src/util/ask_fqdn_validator.dart';
import 'package:nginx_le/src/util/ask_location_path.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

class Tomcat extends ContentProvider {
  @override
  String get name => 'tomcat';

  @override
  String get summary => 'Tomcat web application server.';

  @override
  void promptForSettings() {
    var config = ConfigYaml();
    String? fqdn;
    print('');
    print('${green('Tomcat server details')}');

    var context = config.settings[contextKey] as String?;
    context ??= '';

    context = ask('webapp context (blank for the ROOT context):',
        defaultValue: context);

    fqdn = config.settings[fqdnKey] as String?;
    fqdn ??= 'localhost';

    fqdn = ask('FQDN of Tomcat server:',
        defaultValue: fqdn,
        validator: Ask.all([Ask.required, AskFQDNOrLocalhost()]));

    var port = config.settings[portKey] as int?;
    port ??= 8080;

    port = int.parse(ask('TCP Port of Tomcat server:',
        defaultValue: '$port',
        validator: Ask.all([Ask.required, Ask.integer])));

    config.settings[fqdnKey] = fqdn;
    config.settings[portKey] = port;
    config.settings[contextKey] = context;

    askForLocationPath(
        'Host directory for generated tomcat `.location` and `.upstream` files');
  }

  String get portKey => '$name-port';

  String get fqdnKey => '$name-fqdn';

  String get contextKey => '$name-context';

  @override
  void createLocationFile() {
    var config = ConfigYaml();

    find('*.location', workingDirectory: config.hostIncludePath!)
        .forEach((file) => delete(file));
    var location = join(config.hostIncludePath!, 'tomcat.location');

    var context = config.settings[contextKey] as String?;

    // avoid double slashes.
    if (context == '/') {
      context = '';
    }

    /// add trailing slash.
    if (context!.isNotEmpty) {
      context += '/';
    }

    location.write('''location / {
      	#try_files \$uri \$uri/ =404;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_redirect off;
        proxy_max_temp_file_size 0;
        proxy_pass http://tomcat/$context;
        proxy_read_timeout 300;
}
''');

    location.append('''location /$context {
      	#try_files \$uri \$uri/ =404;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_redirect off;
        proxy_max_temp_file_size 0;
        proxy_pass http://tomcat/$context;
        proxy_read_timeout 300;
}
''');
  }

  @override
  void createUpstreamFile() {
    find('*.upstream', workingDirectory: ConfigYaml().hostIncludePath!)
        .forEach((file) => delete(file));
    var config = ConfigYaml();
    var location = join(ConfigYaml().hostIncludePath!, 'tomcat.upstream');

    var fqdn = config.settings[fqdnKey] as String?;
    var port = config.settings[portKey] as int?;

    location.write('''upstream tomcat {
    server $fqdn:$port fail_timeout=0;
}
''');
  }

  @override
  List<Volume> getVolumes() {
    var config = ConfigYaml();
    return [
      Volume(
          hostPath: config.hostIncludePath,
          containerPath: Nginx.containerIncludePath),
    ];
  }
}
