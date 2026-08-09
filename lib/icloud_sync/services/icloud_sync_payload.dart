import 'dart:convert';

import '../../models/project.dart';

const icloudSyncPayloadVersion = 1;

/// Full-library JSON blob stored in iCloud KVS — every [Project], synced as
/// one blob (osmPod/osmSolver-style) rather than per-record.
String encodeIcloudSyncPayload(List<Project> projects) {
  return jsonEncode({
    'version': icloudSyncPayloadVersion,
    'projects': projects.map((p) => p.toJson()).toList(),
  });
}

List<Project> decodeIcloudSyncPayload(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Expected a JSON object');
  }
  final rawList = decoded['projects'];
  if (rawList is! List) {
    throw const FormatException('Expected a projects array');
  }
  final projects = <Project>[];
  for (final item in rawList) {
    if (item is! Map) continue;
    try {
      projects.add(Project.fromJson(Map<String, dynamic>.from(item)));
    } on FormatException {
      // Skip a single corrupt record rather than losing the whole sync.
    }
  }
  return projects;
}

/// Apple `timeIntervalSinceReferenceDate` (2001-01-01 UTC) — the clock the
/// native iCloud KVS bridge compares timestamps in.
double dateToAppleReference(DateTime date) =>
    date.toUtc().difference(DateTime.utc(2001)).inMicroseconds / 1e6;

DateTime appleReferenceToDate(double referenceSeconds) => DateTime.utc(
  2001,
).add(Duration(microseconds: (referenceSeconds * 1e6).round()));
