@Timeout(Duration(minutes: 30))

/// certificate renewals can take 20 minutes hence the long timeout above.

import 'package:nginx_le_shared/src/certbot/certbot_paths.dart';
import 'package:nginx_le_shared/src/certbot/certificate.dart';
import 'package:test/test.dart';

import '../util/prepare.dart';

void main() {
  test('certificate ...', () async {
    prepareEnvironment();
    var certificates = Certificate.load();

    for (var cert in certificates) {
      print(cert.toString());
    }
  });

  test('check for certificate with matching details ...', () async {
    prepareEnvironment();

    print('loading certificates from: ${CertbotPaths().letsEncryptConfigPath}');
    var certificates = Certificate.load();

    print('Found ${certificates.length} certificates');

    for (var cert in certificates) {
      print(cert.toString());
      // if (cert.wasIssuedFor())

    }
  });

  test('parse', () {
    var cert = '''
   Certificate Name: robtest5.noojee.org
     Domains: robtest5.noojee.org
     Expiry Date: 2021-05-13 04:36:22+00:00 (INVALID: TEST_CERT)
     Certificate Path: /etc/letsencrypt/config/live/robtest5.noojee.org/fullchain.pem
     Private Key Path: /etc/letsencrypt/config/live/robtest5.noojee.org/privkey.pem
''';

    var certificate = Certificate.parse(cert.split('\n'));

    print(certificate);

    expect(
        certificate[0]!.wasIssuedFor(
            hostname: 'robtest5',
            domain: 'noojee.org',
            wildcard: false,
            production: false),
        equals(true));
  });
}
