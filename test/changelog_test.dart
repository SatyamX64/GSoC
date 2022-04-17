import 'dart:io';

import 'package:gsoc/change.dart';
import 'package:markdown/markdown.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('Parsing', () {
    group('Example', () {
      final file = File('test/md/markdown.md');
      final changelog = parseChangelog(file.readAsStringSync(), 'markdown');

      test('Check if version exists', () {
        expect(changelog.has('5.0.0'), isTrue);
        expect(changelog.has('9.0.5'), isFalse);
      });

      test('Iterate releases', () {
        expect(changelog.history().length, 35);
        expect(changelog.history().first.version.toString(), '0.7.1+2');
        expect(changelog.history().last.version.toString(), '6.0.0-dev');
      });

      // NOTE: Fails for ' ', as parser does not add that to output
      test('Read release properties', () {
        expect(() => changelog.get('9.5.5'), throwsStateError);
        expect(changelog.get('1.0.0').changes().first.toString(),
            'Fix issue where `accept` could cause an exception');
        expect(changelog.get('5.0.0').link,
            'https://pub.dev/packages/markdown/versions/5.0.0');
        expect(changelog.get('2.0.3').changes().length, 4);
      });
    });

    group('Non-standard', () {
      final file = File('test/md/non_standard.md');

      test('Can be read', () {
        final log = parseChangelog(file.readAsStringSync(), 'markdown');
        expect(log.history().single.link, isNotEmpty);
        expect(log.history().single.version.toString(), '0.0.1-beta+42');
      });
    });
  });

  group('Printing', () {
    group('Example', () {
      // NOTE: Add boolean to allow user to stop adding links
      // Otherwise user will have no way to preserve original file
      test('Example can be written unchanged', () {
        final file = File('test/md/markdown.md');
        final log = parseChangelog(file.readAsStringSync(), ',markdown.md');
        final markdown = printChangelog(log, keepEmptyUnreleased: true);
        expect(markdown, file.readAsStringSync());
      });
    });

    test('Non-standard', () {
      final original = File('test/md/non_standard.md');
      final saved = File('test/md/non_standard_saved.md');
      expect(
          printChangelog(
              parseChangelog(original.readAsStringSync(), 'markdown.md')),
          saved.readAsStringSync());
    });

    final step1 = File('test/md/step1.md');
    final step2 = File('test/md/step2.md');
    final step3 = File('test/md/step3.md');

    test('Empty changelog is empty', () {
      expect(printChangelog(Changelog()), isEmpty);
    });

// NOTE : Fails due to conflict between carriage return('\r\n') and line feed ('\n)
    test('Can make release', () {
      final changelog = parseChangelog(step2.readAsStringSync(), 'markdown.md');
      final release =
          Release(Version.parse('1.1.0'), DateTime.parse('2018-10-18'));
      release.addAll([
        Change([Text('Some change')])
      ]);
      release.link =
          'https://pub.dev/packages/markdown/versions/${release.version}';
      changelog.add(release);
      expect(printChangelog(changelog), step3.readAsStringSync());
    });

    test('Can not add an existing release', () {
      final changelog = parseChangelog(step1.readAsStringSync(), 'markdown.md');
      final release =
          Release(Version.parse('1.0.0'), DateTime.parse('2018-10-18'));
      release.add(Change([Text('Something')]));
      expect(() => changelog.add(release), throwsStateError);
    });

    test('Can print release', () {
      final release =
          Release(Version.parse('0.0.1'), DateTime.parse('2020-02-02'));
      release.add(Change([Text('Some change')]));
      release.link = 'https://example.com';
      expect(
          printRelease(release),
          [
            '## [0.0.1] - 2020-02-02',
            '- Some change',
            '',
            '[0.0.1]: https://example.com',
          ].join('\n'));
    });
  });
}
