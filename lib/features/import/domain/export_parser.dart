import 'dart:convert';

import 'package:archive/archive.dart';

import 'parsed_export.dart';

/// Which list a JSON document describes.
enum _ListKind { followers, following, unknown }

/// Pure-Dart parser for the "Followers and following" data export.
///
/// The export format changes from time to time, so this parser is
/// deliberately tolerant:
///  * files may live anywhere inside the ZIP (any folder depth),
///  * followers may be split across `followers_1.json`, `followers_2.json`...
///  * the top level may be a bare list or an object wrapping a list
///    (e.g. `{"relationships_following": [...]}`),
///  * the username may be in `string_list_data[].value`, in `title`, or only
///    recoverable from `string_list_data[].href`.
class ExportParser {
  const ExportParser();

  static final RegExp _followersName = RegExp(r'^followers(_\d+)?\.json$');
  static final RegExp _followingName = RegExp(r'^following(_\d+)?\.json$');
  static final RegExp _followersHtmlName = RegExp(r'^followers(_\d+)?\.html?$');
  static final RegExp _followingHtmlName = RegExp(r'^following(_\d+)?\.html?$');

  /// Instagram-style handle: letters, digits, dots and underscores, max 30.
  static final RegExp _username = RegExp(r'^[a-z0-9._]{1,30}$');

  /// Parses any mix of ZIP and JSON files and merges the results.
  ///
  /// Throws [ExportParseException] when nothing usable is found.
  ParsedExport parseFiles(List<ExportInputFile> files) {
    final acc = _Accumulator();
    for (final file in files) {
      final lower = file.name.toLowerCase();
      if (lower.endsWith('.zip') || _looksLikeZip(file.bytes)) {
        _parseZipInto(file.bytes, acc);
      } else if (lower.endsWith('.html') || lower.endsWith('.htm')) {
        acc.sawHtml = true;
      } else {
        _parseJsonFileInto(_basename(file.name), file.bytes, acc);
      }
    }
    return acc.build();
  }

  /// Parses a ZIP archive.
  ParsedExport parseZip(List<int> bytes) {
    final acc = _Accumulator();
    _parseZipInto(bytes, acc);
    return acc.build();
  }

  /// Parses a single JSON document. [fileName] helps decide whether a bare
  /// list is followers or following; it may be empty.
  ParsedExport parseJson(String fileName, String content) {
    final acc = _Accumulator();
    _parseJsonStringInto(_basename(fileName), content, acc);
    return acc.build();
  }

  /// Extracts usernames from a decoded JSON value, whatever its shape.
  /// Exposed for testing.
  Set<String> extractUsernames(Object? json) {
    final out = <String>{};
    for (final entry in _entries(json)) {
      final name = _usernameFromEntry(entry);
      if (name != null) out.add(name);
    }
    return out;
  }

  /// Lowercases, trims and strips a leading `@`. Returns `null` for values
  /// that cannot be a username.
  static String? normalizeUsername(Object? raw) {
    if (raw is! String) return null;
    var v = raw.trim().toLowerCase();
    if (v.startsWith('@')) v = v.substring(1);
    return _username.hasMatch(v) ? v : null;
  }

  // ---------------------------------------------------------------------------

  void _parseZipInto(List<int> bytes, _Accumulator acc) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw ExportParseException(ExportParseError.corruptArchive, '$e');
    }
    if (archive.isEmpty) {
      throw const ExportParseException(ExportParseError.corruptArchive, 'empty archive');
    }
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final base = _basename(entry.name).toLowerCase();
      if (base.startsWith('._')) continue; // macOS resource forks
      final isFollowers = _followersName.hasMatch(base);
      final isFollowing = _followingName.hasMatch(base);
      if (isFollowers || isFollowing) {
        final data = entry.readBytes();
        if (data == null) continue;
        _parseJsonFileInto(base, data, acc);
      } else if (_followersHtmlName.hasMatch(base) || _followingHtmlName.hasMatch(base)) {
        acc.sawHtml = true;
      }
    }
  }

  void _parseJsonFileInto(String name, List<int> bytes, _Accumulator acc) {
    final String text;
    try {
      text = utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return;
    }
    _parseJsonStringInto(name, text, acc);
  }

  void _parseJsonStringInto(String name, String text, _Accumulator acc) {
    final trimmed = text.trimLeft();
    if (trimmed.startsWith('<')) {
      acc.sawHtml = true;
      return;
    }
    final Object? json;
    try {
      json = jsonDecode(trimmed.startsWith('﻿') ? trimmed.substring(1) : trimmed);
    } on FormatException {
      return;
    }

    final lowerName = name.toLowerCase();
    var kind = _followersName.hasMatch(lowerName)
        ? _ListKind.followers
        : _followingName.hasMatch(lowerName)
        ? _ListKind.following
        : _ListKind.unknown;

    // The object keys are more reliable than the file name when present.
    if (json is Map) {
      final keyKind = _kindFromKeys(json.keys);
      if (keyKind != _ListKind.unknown) kind = keyKind;
    }
    // A bare top-level list is the followers format.
    if (kind == _ListKind.unknown && json is List) kind = _ListKind.followers;
    if (kind == _ListKind.unknown) return;

    final names = extractUsernames(json);
    if (kind == _ListKind.followers) {
      acc.foundFollowers = true;
      acc.followers.addAll(names);
    } else {
      acc.foundFollowing = true;
      acc.following.addAll(names);
    }
  }

  _ListKind _kindFromKeys(Iterable<dynamic> keys) {
    for (final k in keys) {
      if (k is! String) continue;
      final key = k.toLowerCase();
      if (key.contains('followers')) return _ListKind.followers;
      if (key.contains('following')) return _ListKind.following;
    }
    return _ListKind.unknown;
  }

  /// Yields every map that looks like a relationship entry.
  Iterable<Map<dynamic, dynamic>> _entries(Object? json) sync* {
    if (json is List) {
      for (final item in json) {
        if (item is Map) yield item;
      }
    } else if (json is Map) {
      // Object wrapping one or more lists, e.g. relationships_following.
      var yielded = false;
      for (final value in json.values) {
        if (value is List) {
          for (final item in value) {
            if (item is Map) {
              yielded = true;
              yield item;
            }
          }
        }
      }
      // A single entry at the top level.
      if (!yielded && (json.containsKey('string_list_data') || json.containsKey('title'))) {
        yield json;
      }
    }
  }

  String? _usernameFromEntry(Map<dynamic, dynamic> entry) {
    final sld = entry['string_list_data'];
    if (sld is List) {
      for (final item in sld) {
        if (item is Map) {
          final v = normalizeUsername(item['value']);
          if (v != null) return v;
        }
      }
    }
    final title = normalizeUsername(entry['title']);
    if (title != null) return title;

    for (final key in const ['value', 'username']) {
      final v = normalizeUsername(entry[key]);
      if (v != null) return v;
    }

    if (sld is List) {
      for (final item in sld) {
        if (item is Map) {
          final v = usernameFromHref(item['href']);
          if (v != null) return v;
        }
      }
    }
    return usernameFromHref(entry['href']);
  }

  /// Extracts the handle from a profile URL such as
  /// `https://www.instagram.com/_u/some.user` or `https://instagram.com/some.user/`.
  static String? usernameFromHref(Object? href) {
    if (href is! String || href.isEmpty) return null;
    final uri = Uri.tryParse(href.trim());
    if (uri == null) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty && s != '_u').toList();
    if (segments.isEmpty) return null;
    return normalizeUsername(segments.last);
  }

  static bool _looksLikeZip(List<int> bytes) =>
      bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04;

  static String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final i = normalized.lastIndexOf('/');
    return i < 0 ? normalized : normalized.substring(i + 1);
  }
}

class _Accumulator {
  final followers = <String>{};
  final following = <String>{};
  bool foundFollowers = false;
  bool foundFollowing = false;
  bool sawHtml = false;

  ParsedExport build() {
    if (!foundFollowers && !foundFollowing) {
      throw ExportParseException(sawHtml ? ExportParseError.htmlFormat : ExportParseError.nothingRecognized);
    }
    return ParsedExport(
      followers: followers,
      following: following,
      foundFollowersFile: foundFollowers,
      foundFollowingFile: foundFollowing,
    );
  }
}
