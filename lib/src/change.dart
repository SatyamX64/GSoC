import 'package:markdown/markdown.dart';

/// A single change
class Change {
  Change(Iterable<Node> description) {
    this.description.addAll(description);
  }

  /// Change description
  final description = <Node>[];

  /// Change description in plain text
  @override
  String toString() => description.map((e) => e.textContent).join();
}
