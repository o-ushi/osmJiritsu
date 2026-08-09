/// The four quadrants of a SWOT analysis.
///
/// Mirrors `SWOTCategory` from the original osmSWOT iOS app
/// (osmSWOT/Models/SWOTItem.swift).
enum SwotCategory {
  strength,
  weakness,
  opportunity,
  threat;

  /// Single-letter abbreviation used as the JSON key in AI responses
  /// (e.g. `{"S": [...], "W": [...], "O": [...], "T": [...]}`).
  String get abbreviation {
    switch (this) {
      case SwotCategory.strength:
        return 'S';
      case SwotCategory.weakness:
        return 'W';
      case SwotCategory.opportunity:
        return 'O';
      case SwotCategory.threat:
        return 'T';
    }
  }

  String get englishName {
    switch (this) {
      case SwotCategory.strength:
        return 'Strength';
      case SwotCategory.weakness:
        return 'Weakness';
      case SwotCategory.opportunity:
        return 'Opportunity';
      case SwotCategory.threat:
        return 'Threat';
    }
  }

  /// Persistence key. Kept stable across app versions.
  String get rawValue {
    switch (this) {
      case SwotCategory.strength:
        return 'strength';
      case SwotCategory.weakness:
        return 'weakness';
      case SwotCategory.opportunity:
        return 'opportunity';
      case SwotCategory.threat:
        return 'threat';
    }
  }

  /// Parses a raw value, accepting both the current English rawValues and
  /// the legacy Japanese ones used by early osmSWOT sessions (kept for
  /// parity with `SWOTCategory.init?(rawValue:)` on iOS).
  static SwotCategory? fromRawValue(String rawValue) {
    switch (rawValue) {
      case 'strength':
      case '強み':
        return SwotCategory.strength;
      case 'weakness':
      case '弱み':
        return SwotCategory.weakness;
      case 'opportunity':
      case '機会':
        return SwotCategory.opportunity;
      case 'threat':
      case '脅威':
        return SwotCategory.threat;
      default:
        return null;
    }
  }
}
