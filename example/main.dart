import 'dart:io';

import 'package:gsoc/change.dart';

/// This example shows how to parse a changelog.
/// Run it from the project example folder:
/// ```
/// cd example
/// dart run main.dart
/// ```
/// It will generate a new markdown with links pointing to the correct version
void main() async {
  // Changelog for markdowm package
  generateMarkdown('changelog_1.md', 'markdown');

  // changelog for flutter_pinput (contains date)
  generateMarkdown('changelog_2.md', 'markdown');
}

Future<void> generateMarkdown(String fileName, String package) async {
  final file = File(fileName);
  final log = parseChangelog(file.readAsStringSync(), package);

  await File('out_' + fileName).writeAsString(printChangelog(log));

  // We can also see various details through the log
  final latest = log.history().last;
  print('Changelog contains ${log.history().length} releases.');
  print('The latest version is ${latest.version}');
  print('released on ${latest.date}');
  print('and containing ${latest.changes().length} change(s).');
}
