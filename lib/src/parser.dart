import 'dart:convert';

import 'package:gsoc/src/change.dart';
import 'package:gsoc/src/changelog.dart';
import 'package:gsoc/src/release.dart';
import 'package:markdown/markdown.dart';
import 'package:pub_semver/pub_semver.dart';

/// Parses the [Changelog] from a markdown string
Changelog parseChangelog(String markdown, String package) {
  final log = Changelog();
  final doc = Document();
  final sections = <List<Node>>[];
  for (final node in doc.parseLines(LineSplitter.split(markdown).toList())) {
    if (_isRelease(node)) {
      sections.add([node]);
    } else if (sections.isEmpty) {
      log.header.add(node);
    } else {
      sections.last.add(node);
    }
  }
  for (final nodes in sections) {
    final release = _release(nodes);
    final version = release.version.toString().toLowerCase();
    release.link = doc.linkReferences[version]?.destination ??
        'https://pub.dev/packages/$package/versions/$version';
    log.add(release);
  }
  return log;
}

final _versionPrefix = RegExp(r'\d+\.\d+\.\d+');

bool _isRelease(Node node) =>
    node is Element &&
    node.tag == 'h2' &&
    node.textContent.trim().startsWith(_versionPrefix);

Release _release(Iterable<Node> nodes) {
  final header = nodes.first.textContent.trim();
  final parts = header.split(' - ');
  final version = Version.parse(parts[0].trim());
  DateTime? date;
  if (parts.length > 1) {
    date = DateTime.parse(parts.last.trim());
  }
  final release = Release(version, date);
  _changes(nodes.skip(1)).forEach(release.add);
  return release;
}

List<Change> _changes(Iterable<Node> nodes) {
  final changes = <Change>[];
  for (final node in nodes.whereType<Element>()) {
    node.children!
        .whereType<Element>()
        .map((node) => Change(node.children!))
        .forEach(changes.add);
  }
  return changes;
}
