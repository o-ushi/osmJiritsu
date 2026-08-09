import 'package:flutter_test/flutter_test.dart';
import 'package:osm_jiritsu/models/jiritsu.dart';
import 'package:osm_jiritsu/models/jiritsu_check.dart';
import 'package:osm_jiritsu/models/project_status.dart';

void main() {
  group('JiritsuElement', () {
    test('rawValue round-trips through fromRawValue', () {
      for (final element in JiritsuElement.values) {
        expect(JiritsuElement.fromRawValue(element.rawValue), element);
      }
    });

    test('fromRawValue returns null for unknown values', () {
      expect(JiritsuElement.fromRawValue('nope'), isNull);
    });
  });

  group('ProjectStatus', () {
    test('rawValue round-trips through fromRawValue', () {
      for (final status in ProjectStatus.values) {
        expect(ProjectStatus.fromRawValue(status.rawValue), status);
      }
    });

    test('fromRawValue returns null for unknown values', () {
      expect(ProjectStatus.fromRawValue('nope'), isNull);
    });
  });

  group('JiritsuCheck', () {
    test('none has zero score and is not fully autonomous', () {
      expect(JiritsuCheck.none.satisfiedCount, 0);
      expect(JiritsuCheck.none.score, 0.0);
      expect(JiritsuCheck.none.isFullyAutonomous, isFalse);
    });

    test('score reflects the count of satisfied elements', () {
      const check = JiritsuCheck(selfDetermined: true, clearOutcome: true);
      expect(check.satisfiedCount, 2);
      expect(check.score, closeTo(2 / 3, 1e-9));
      expect(check.isFullyAutonomous, isFalse);
    });

    test('is fully autonomous only when all three elements are true', () {
      const check = JiritsuCheck(
        selfDetermined: true,
        clearOutcome: true,
        sharedGoal: true,
      );
      expect(check.satisfiedCount, 3);
      expect(check.score, 1.0);
      expect(check.isFullyAutonomous, isTrue);
    });

    test('answerFor returns the field matching each element', () {
      const check = JiritsuCheck(sharedGoal: true);
      expect(check.answerFor(JiritsuElement.selfDetermined), isFalse);
      expect(check.answerFor(JiritsuElement.clearOutcome), isFalse);
      expect(check.answerFor(JiritsuElement.sharedGoal), isTrue);
    });

    test('JSON round trip preserves all three answers', () {
      const check = JiritsuCheck(selfDetermined: true, clearOutcome: false, sharedGoal: true);
      final decoded = JiritsuCheck.fromJson(check.toJson());
      expect(decoded.selfDetermined, isTrue);
      expect(decoded.clearOutcome, isFalse);
      expect(decoded.sharedGoal, isTrue);
    });

    test('fromJson defaults missing/malformed fields to false', () {
      final decoded = JiritsuCheck.fromJson({'selfDetermined': true});
      expect(decoded.selfDetermined, isTrue);
      expect(decoded.clearOutcome, isFalse);
      expect(decoded.sharedGoal, isFalse);
    });

    test('copyWith overrides only the given fields', () {
      const check = JiritsuCheck(selfDetermined: true);
      final updated = check.copyWith(clearOutcome: true);
      expect(updated.selfDetermined, isTrue);
      expect(updated.clearOutcome, isTrue);
      expect(updated.sharedGoal, isFalse);
    });
  });
}
