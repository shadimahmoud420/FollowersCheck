import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:follower_check/features/import/domain/export_parser.dart';
import 'package:follower_check/features/import/domain/parsed_export.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _fixture(String path) => File('test/fixtures/$path').readAsBytesSync();

ExportInputFile _input(String path) => ExportInputFile(path.split('/').last, _fixture(path));

List<int> _zip(Map<String, List<int>> entries) {
  final archive = Archive();
  entries.forEach((name, bytes) => archive.addFile(ArchiveFile.bytes(name, bytes)));
  return ZipEncoder().encodeBytes(archive);
}

void main() {
  const parser = ExportParser();

  group('current format (bare followers list, following with title)', () {
    test('parses split followers files and following.json from JSON inputs', () {
      final result = parser.parseFiles([
        _input('current/followers_1.json'),
        _input('current/followers_2.json'),
        _input('current/following.json'),
      ]);

      expect(result.foundFollowersFile, isTrue);
      expect(result.foundFollowingFile, isTrue);
      // Merged, lowercased and de-duplicated.
      expect(result.followers, {'alice.smith', 'bob_99', 'carol', 'dave'});
      // "title" preferred; falls back to href when title is empty.
      expect(result.following, {'alice.smith', 'erin.codes', 'frank_'});
    });

    test('finds files anywhere inside a ZIP archive', () {
      final zip = _zip({
        'connections/followers_and_following/followers_1.json': _fixture('current/followers_1.json'),
        'connections/followers_and_following/followers_2.json': _fixture('current/followers_2.json'),
        'deep/nested/folder/following.json': _fixture('current/following.json'),
        'connections/followers_and_following/pending_follow_requests.json': utf8.encode(
          '{"relationships_follow_requests_sent": []}',
        ),
        'connections/followers_and_following/recently_unfollowed_profiles.json': utf8.encode(
          '{"relationships_unfollowed_users": [{"string_list_data": [{"value": "ghost"}]}]}',
        ),
        '__MACOSX/connections/._followers_1.json': [0, 1, 2],
      });

      final result = parser.parseFiles([ExportInputFile('export.zip', zip)]);
      expect(result.followers, {'alice.smith', 'bob_99', 'carol', 'dave'});
      expect(result.following, {'alice.smith', 'erin.codes', 'frank_'});
      expect(result.followers.contains('ghost'), isFalse);
    });

    test('detects a ZIP by its magic bytes even without .zip extension', () {
      final zip = _zip({'followers_1.json': _fixture('current/followers_1.json')});
      final result = parser.parseFiles([ExportInputFile('download', zip)]);
      expect(result.followers, hasLength(3));
      expect(result.foundFollowingFile, isFalse);
    });
  });

  group('legacy format (wrapped followers, following with value)', () {
    test('parses wrapped objects and ignores invalid usernames', () {
      final zip = _zip({
        'followers_and_following/followers_1.json': _fixture('legacy/followers_1.json'),
        'followers_and_following/following.json': _fixture('legacy/following.json'),
      });
      final result = parser.parseZip(zip);
      expect(result.followers, {'zoe', 'yan'});
      expect(result.following, {'zoe', 'xavier'});
    });

    test('detects list kind from JSON keys when file name is unknown', () {
      final result = parser.parseJson('renamed.json', File('test/fixtures/legacy/following.json').readAsStringSync());
      expect(result.foundFollowingFile, isTrue);
      expect(result.foundFollowersFile, isFalse);
      expect(result.following, {'zoe', 'xavier'});
    });

    test('treats an unnamed bare list as followers', () {
      final result = parser.parseJson('', File('test/fixtures/current/followers_1.json').readAsStringSync());
      expect(result.foundFollowersFile, isTrue);
      expect(result.followers, hasLength(3));
    });
  });

  group('errors', () {
    test('HTML export inside ZIP reports htmlFormat', () {
      final zip = _zip({'connections/followers_1.html': _fixture('html/followers_1.html')});
      expect(
        () => parser.parseFiles([ExportInputFile('export.zip', zip)]),
        throwsA(isA<ExportParseException>().having((e) => e.error, 'error', ExportParseError.htmlFormat)),
      );
    });

    test('HTML file picked directly reports htmlFormat', () {
      expect(
        () => parser.parseFiles([_input('html/followers_1.html')]),
        throwsA(isA<ExportParseException>().having((e) => e.error, 'error', ExportParseError.htmlFormat)),
      );
    });

    test('HTML content with a .json name reports htmlFormat', () {
      expect(
        () => parser.parseJson('followers_1.json', '<html></html>'),
        throwsA(isA<ExportParseException>().having((e) => e.error, 'error', ExportParseError.htmlFormat)),
      );
    });

    test('unrelated JSON reports nothingRecognized', () {
      expect(
        () => parser.parseFiles([_input('unrelated.json')]),
        throwsA(isA<ExportParseException>().having((e) => e.error, 'error', ExportParseError.nothingRecognized)),
      );
    });

    test('malformed JSON reports nothingRecognized', () {
      expect(
        () => parser.parseJson('followers_1.json', '[{"string_list_data": '),
        throwsA(isA<ExportParseException>().having((e) => e.error, 'error', ExportParseError.nothingRecognized)),
      );
    });

    test('corrupt ZIP reports corruptArchive', () {
      expect(
        () => parser.parseFiles([
          ExportInputFile('export.zip', [0x50, 0x4B, 0x03, 0x04, 1, 2, 3]),
        ]),
        throwsA(isA<ExportParseException>().having((e) => e.error, 'error', ExportParseError.corruptArchive)),
      );
    });

    test('ZIP without relevant files reports nothingRecognized', () {
      final zip = _zip({'media/posts_1.json': utf8.encode('[]')});
      expect(
        () => parser.parseZip(zip),
        throwsA(isA<ExportParseException>().having((e) => e.error, 'error', ExportParseError.nothingRecognized)),
      );
    });
  });

  group('helpers', () {
    test('normalizeUsername', () {
      expect(ExportParser.normalizeUsername('  @Foo.Bar_1 '), 'foo.bar_1');
      expect(ExportParser.normalizeUsername('has space'), isNull);
      expect(ExportParser.normalizeUsername(''), isNull);
      expect(ExportParser.normalizeUsername(42), isNull);
      expect(ExportParser.normalizeUsername('a' * 31), isNull);
    });

    test('usernameFromHref', () {
      expect(ExportParser.usernameFromHref('https://www.instagram.com/_u/Some.User'), 'some.user');
      expect(ExportParser.usernameFromHref('https://instagram.com/some_user/'), 'some_user');
      expect(ExportParser.usernameFromHref('https://instagram.com/'), isNull);
      expect(ExportParser.usernameFromHref(null), isNull);
    });

    test('empty but valid followers list is accepted', () {
      final result = parser.parseJson('followers_1.json', '[]');
      expect(result.foundFollowersFile, isTrue);
      expect(result.followers, isEmpty);
    });
  });
}
