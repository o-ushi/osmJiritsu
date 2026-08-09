import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_jiritsu/theme/app_theme.dart';
import 'package:osm_jiritsu/theme/widgets/app_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const _HomeScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a dialog opened via showAppAlertDialog styles its TextButtons with linkOnCard, not linkOnScene',
    (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final context = tester.element(find.text('キャンセル'));
      final effectiveStyle = Theme.of(context).textButtonTheme.style!;
      final resolvedColor = effectiveStyle.foregroundColor!.resolve({});
      expect(resolvedColor, AppPalette.linkOnCard);
      expect(
        AppPalette.contrastRatio(AppPalette.cardFill, resolvedColor!),
        greaterThanOrEqualTo(3.0),
      );
    },
  );

  testWidgets(
    'showAppDatePicker uses card ink onSurface so days stay readable',
    (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('pick date'));
      await tester.pumpAndSettle();

      final context = tester.element(find.text('Cancel'));
      final scheme = Theme.of(context).colorScheme;
      expect(scheme.onSurface, AppPalette.ink);
      expect(scheme.surface, AppPalette.cardFill);
      expect(
        AppPalette.contrastRatio(scheme.surface, scheme.onSurface),
        greaterThanOrEqualTo(4.5),
      );

      final buttonStyle = Theme.of(context).textButtonTheme.style!;
      final buttonColor = buttonStyle.foregroundColor!.resolve({});
      expect(buttonColor, AppPalette.linkOnCard);
    },
  );
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => showAppAlertDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('確認'),
                  content: const Text('本当によろしいですか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('キャンセル'),
                    ),
                  ],
                ),
              ),
              child: const Text('open'),
            ),
            TextButton(
              onPressed: () => showAppDatePicker(
                context: context,
                initialDate: DateTime(2026, 7, 22),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              ),
              child: const Text('pick date'),
            ),
          ],
        ),
      ),
    );
  }
}
