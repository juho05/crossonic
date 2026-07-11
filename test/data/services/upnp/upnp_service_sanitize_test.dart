import 'package:crossonic/data/services/upnp/upnp_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpnpService.sanitizeLog', () {
    test('redacts token auth params (t, s) in xml-escaped element text', () {
      const body =
          '<CurrentURI>http://h:4533/rest/stream?u=bob&amp;t=deadbeef'
          '&amp;s=SALT12&amp;id=42</CurrentURI>';
      expect(
        UpnpService.sanitizeLog(body),
        '<CurrentURI>http://h:4533/rest/stream?u=bob&amp;t=xxx'
        '&amp;s=xxx&amp;id=42</CurrentURI>',
      );
    });

    test('redacts password auth param (p)', () {
      const body =
          '<res>http://h/rest/stream?u=bob&amp;p=s3cr3t%26weird'
          '&amp;id=9</res>';
      expect(
        UpnpService.sanitizeLog(body),
        '<res>http://h/rest/stream?u=bob&amp;p=xxx&amp;id=9</res>',
      );
    });

    test('redacts apiKey auth param', () {
      const body =
          '<TrackURI>http://h/rest/stream?apiKey=ABCDEF&amp;id=1</TrackURI>';
      expect(
        UpnpService.sanitizeLog(body),
        '<TrackURI>http://h/rest/stream?apiKey=xxx&amp;id=1</TrackURI>',
      );
    });

    test('redacts the first param introduced with ?', () {
      expect(
        UpnpService.sanitizeLog('http://h/x?s=SALT&amp;u=bob'),
        'http://h/x?s=xxx&amp;u=bob',
      );
    });

    test('redacts a raw (unescaped) ampersand separator', () {
      expect(
        UpnpService.sanitizeLog('http://h/x?u=bob&t=HASH&id=1'),
        'http://h/x?u=bob&t=xxx&id=1',
      );
    });

    test('redacts double-escaped params inside nested metadata', () {
      const body =
          '&lt;res&gt;http://h/stream?u=bob&amp;amp;s=SALT&amp;amp;t=HASH'
          '&lt;/res&gt;';
      expect(
        UpnpService.sanitizeLog(body),
        '&lt;res&gt;http://h/stream?u=bob&amp;amp;s=xxx&amp;amp;t=xxx'
        '&lt;/res&gt;',
      );
    });

    test('redacts multiple secrets across a whole soap envelope', () {
      const body =
          '<CurrentURI>http://h/stream?u=bob&amp;t=AAA&amp;s=BBB</CurrentURI>'
          '<NextURI>http://h/stream?u=bob&amp;p=CCC</NextURI>';
      expect(
        UpnpService.sanitizeLog(body),
        '<CurrentURI>http://h/stream?u=bob&amp;t=xxx&amp;s=xxx</CurrentURI>'
        '<NextURI>http://h/stream?u=bob&amp;p=xxx</NextURI>',
      );
    });

    test('redacts a value that runs to the end of the string', () {
      expect(
        UpnpService.sanitizeLog('http://h/x?p=tailwithnoterminator'),
        'http://h/x?p=xxx',
      );
    });

    test('handles an empty secret value', () {
      expect(
        UpnpService.sanitizeLog('http://h/x?p=&amp;u=bob'),
        'http://h/x?p=xxx&amp;u=bob',
      );
    });

    test('does not touch params whose name merely ends in p/t/s', () {
      const body =
          'http://h/x?os=linux&amp;props=1&amp;format=json&amp;versions=3';
      expect(UpnpService.sanitizeLog(body), body);
    });

    test('leaves bodies without any credentials unchanged', () {
      const body = '<InstanceID>0</InstanceID><Speed>1</Speed>';
      expect(UpnpService.sanitizeLog(body), body);
    });

    test('returns an empty string unchanged', () {
      expect(UpnpService.sanitizeLog(''), '');
    });

    test('is idempotent when run over already-sanitized output', () {
      const body =
          '<CurrentURI>http://h/stream?u=bob&amp;t=AAA&amp;s=BBB</CurrentURI>';
      final once = UpnpService.sanitizeLog(body);
      expect(UpnpService.sanitizeLog(once), once);
    });
  });
}