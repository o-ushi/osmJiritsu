import '../l10n/app_language.dart';
import '../models/swot_category.dart';
import '../models/swot_matrix.dart';

/// Prompt language for Chrome AI Mode — mirrors [AppLanguage] so the AI
/// round trip follows the UI language the user picked.
enum PromptLanguage {
  japanese,
  english,
  vietnamese;

  static PromptLanguage fromAppLanguage(AppLanguage language) {
    switch (language) {
      case AppLanguage.japanese:
        return PromptLanguage.japanese;
      case AppLanguage.english:
        return PromptLanguage.english;
      case AppLanguage.vietnamese:
        return PromptLanguage.vietnamese;
    }
  }
}

/// Builds the system/user prompts sent to Chrome AI Mode for Stage1's
/// strategy (Step 5) and first-step (Step 9) divergence.
///
/// SWOT cross-analysis runs inside the model (never a separate TOWS UI
/// step). Callers must pass [PromptLanguage.fromAppLanguage] so en/vi UI
/// users do not silently get Japanese prompts.
class PromptLibrary {
  PromptLibrary._();

  static String _noneLabel(PromptLanguage language) {
    switch (language) {
      case PromptLanguage.japanese:
        return '(なし)';
      case PromptLanguage.english:
        return '(none)';
      case PromptLanguage.vietnamese:
        return '(không có)';
    }
  }

  static String _bulletSectionLocalized(
    PromptLanguage language,
    String header,
    List<String> items,
  ) {
    if (items.isEmpty) return '$header\n${_noneLabel(language)}';
    final mark = language == PromptLanguage.english ? '- ' : '・';
    return '$header\n${items.map((i) => '$mark$i').join('\n')}';
  }

  /// System prompt for Stage1 Step 5: return 5 方策 candidates.
  static String strategySystemPrompt(PromptLanguage language) {
    switch (language) {
      case PromptLanguage.japanese:
        return '''
導入文・締め文不要。JSONのみ出力。
あなたは実行支援コーチです。ユーザーの「テーマ」「在りたい姿」「在りたくない姿」と、SWOT分析（強み・弱み・機会・脅威）の情報をもとに、以下のSWOTからゴール達成のための方策を5個提案してください。

なお方策は、内発的動機づけの３要素をできるだけ満たしてください。
１．自分で決められるか？ — やり方を自分で決め、主導権が自分にあり、言われる前に動ける
２．成果が分かりやすいか？ — 成長や能力発揮を実感でき、粒度が細かく結果が見える（小さなくるくる）
３．周りと繋がっているか？ — ビジョン・ゴール・進捗を共有でき、サポートを得られ、役に立ち当てにされる（唱って躍れる）

出力スキーマ（このJSONのみを返す）:
{
  "strategies": [
    {
      "text": "方策の内容（1〜2文、具体的に）",
      "rationale": "なぜこれがゴールへのギャップを埋めるか（SWOTの根拠に言及）"
    }
  ]
}

ルール:
- strategies は5件
- text は具体的な方策そのもの。1ヶ月プランや週次ステップへの分解はまだ不要
- rationale では元になった強み/弱み/機会/脅威の具体的な内容に言及する
''';
      case PromptLanguage.english:
        return '''
No preamble. Output JSON only.
You are an execution coach. Using the user's theme, desired outcome, state to avoid, and their SWOT analysis (strengths/weaknesses/opportunities/threats), propose 5 strategies for reaching the goal from the SWOT below.

As much as possible, each strategy should satisfy the three elements of intrinsic motivation:
1. Can you decide it yourself? — you decide how, hold the initiative, and act before being told
2. Can you see your results clearly? — you feel your growth and ability, with fine-grained, visible progress
3. Are you connected with others? — you can share your vision/goals/progress, get support, and feel needed

Output schema (return this JSON only):
{
  "strategies": [
    {
      "text": "The strategy itself (1-2 concrete sentences)",
      "rationale": "Why this closes the gap to the goal (referencing SWOT evidence)"
    }
  ]
}

Rules:
- strategies must contain exactly 5 items
- text is the strategy itself — no month-plan or weekly-step breakdown yet
- rationale must reference the specific strengths/weaknesses/opportunities/threats behind it
- Write text and rationale in English
''';
      case PromptLanguage.vietnamese:
        return '''
Không viết lời mở đầu. Chỉ xuất JSON.
Bạn là huấn luyện viên hỗ trợ hành động. Dựa trên chủ đề, trạng thái mong muốn, trạng thái muốn tránh, và phân tích SWOT (điểm mạnh/yếu/cơ hội/đe dọa), hãy đề xuất 5 phương sách để đạt mục tiêu.

Mỗi phương sách nên thỏa càng nhiều càng tốt 3 yếu tố của động lực nội tại:
1. Bạn có thể tự quyết định không? — tự quyết định cách làm, nắm quyền chủ động, hành động trước khi được nhắc
2. Bạn có thấy rõ thành quả không? — cảm nhận được sự trưởng thành và năng lực, với các bước nhỏ và kết quả rõ ràng
3. Bạn có kết nối với mọi người không? — chia sẻ được tầm nhìn/mục tiêu/tiến độ, nhận được hỗ trợ, và cảm thấy được cần đến

Schema đầu ra (chỉ trả JSON này):
{
  "strategies": [
    {
      "text": "Nội dung phương sách (1-2 câu cụ thể)",
      "rationale": "Vì sao phương sách này thu hẹp khoảng cách tới mục tiêu (nhắc bằng chứng SWOT)"
    }
  ]
}

Quy tắc:
- strategies đúng 5 mục
- text là phương sách cụ thể — chưa cần kế hoạch tháng hay bước theo tuần
- rationale phải nhắc nội dung cụ thể của điểm mạnh/yếu/cơ hội/đe dọa
- Viết text và rationale bằng tiếng Việt
''';
    }
  }

  static String strategyUserPrompt({
    required String theme,
    required String desiredGoal,
    String undesiredGoal = '',
    required SwotMatrix matrix,
    PromptLanguage language = PromptLanguage.japanese,
  }) {
    final s = matrix.contentFor(SwotCategory.strength);
    final w = matrix.contentFor(SwotCategory.weakness);
    final o = matrix.contentFor(SwotCategory.opportunity);
    final t = matrix.contentFor(SwotCategory.threat);

    switch (language) {
      case PromptLanguage.japanese:
        final buffer = StringBuffer()
          ..writeln('テーマ: $theme')
          ..writeln('在りたい姿: $desiredGoal');
        if (undesiredGoal.trim().isNotEmpty) {
          buffer.writeln('在りたくない姿: ${undesiredGoal.trim()}');
        }
        buffer
          ..writeln()
          ..writeln(_bulletSectionLocalized(language, '【強み S】', s))
          ..writeln(_bulletSectionLocalized(language, '【弱み W】', w))
          ..writeln(_bulletSectionLocalized(language, '【機会 O】', o))
          ..writeln(_bulletSectionLocalized(language, '【脅威 T】', t))
          ..writeln()
          ..writeln(
            '上記をもとに、指示された条件とJSONスキーマに従って方策を提案してください。',
          );
        return buffer.toString().trim();
      case PromptLanguage.english:
        final buffer = StringBuffer()
          ..writeln('Theme: $theme')
          ..writeln('Desired outcome: $desiredGoal');
        if (undesiredGoal.trim().isNotEmpty) {
          buffer.writeln('State to avoid: ${undesiredGoal.trim()}');
        }
        buffer
          ..writeln()
          ..writeln(_bulletSectionLocalized(language, '[Strengths S]', s))
          ..writeln(_bulletSectionLocalized(language, '[Weaknesses W]', w))
          ..writeln(_bulletSectionLocalized(language, '[Opportunities O]', o))
          ..writeln(_bulletSectionLocalized(language, '[Threats T]', t))
          ..writeln()
          ..writeln(
            'Using the above, propose strategies following the given conditions and JSON schema.',
          );
        return buffer.toString().trim();
      case PromptLanguage.vietnamese:
        final buffer = StringBuffer()
          ..writeln('Chủ đề: $theme')
          ..writeln('Trạng thái mong muốn: $desiredGoal');
        if (undesiredGoal.trim().isNotEmpty) {
          buffer.writeln('Trạng thái muốn tránh: ${undesiredGoal.trim()}');
        }
        buffer
          ..writeln()
          ..writeln(_bulletSectionLocalized(language, '[Điểm mạnh S]', s))
          ..writeln(_bulletSectionLocalized(language, '[Điểm yếu W]', w))
          ..writeln(_bulletSectionLocalized(language, '[Cơ hội O]', o))
          ..writeln(_bulletSectionLocalized(language, '[Đe dọa T]', t))
          ..writeln()
          ..writeln(
            'Dựa trên thông tin trên, hãy đề xuất phương sách theo điều kiện và schema JSON đã cho.',
          );
        return buffer.toString().trim();
    }
  }

  /// System + user merged for Chrome AI Mode (single query string).
  static String strategyChromeAiPrompt({
    required String theme,
    required String desiredGoal,
    String undesiredGoal = '',
    required SwotMatrix matrix,
    PromptLanguage language = PromptLanguage.japanese,
  }) {
    final system = strategySystemPrompt(language);
    final user = strategyUserPrompt(
      theme: theme,
      desiredGoal: desiredGoal,
      undesiredGoal: undesiredGoal,
      matrix: matrix,
      language: language,
    );
    return '$system\n\n$user';
  }

  /// System prompt for Stage1 Step 9: 10 first-step candidates.
  static String firstStepSystemPrompt(PromptLanguage language) {
    switch (language) {
      case PromptLanguage.japanese:
        return '''
導入文・締め文不要。JSONのみ出力。
あなたは実行支援コーチです。ユーザーが決めた方策をもとに、この方策を始めるために、明日からできる、所要時間30分以内の行動を10個提案してください。

出力スキーマ（このJSONのみを返す）:
{
  "steps": [
    {"text": "具体的な行動（1文、30分以内で完了できる粒度）"}
  ]
}

ルール:
- steps は10件
- 各行動は明日から着手でき、所要時間30分以内で完了できる具体的な粒度にする
- 方策全体の完了を目指すものではなく、その最初の一歩として意味のある行動にする
- 各行動は内発的動機づけの３要素「自分で決められるか？」「成果が分かりやすいか？」「周りと繋がっているか？」をできるだけ満たす
''';
      case PromptLanguage.english:
        return '''
No preamble. Output JSON only.
You are an execution coach. Based on the strategy the user has already decided on, propose 10 actions that can start tomorrow and be completed within 30 minutes, to kick off that strategy.

Output schema (return this JSON only):
{
  "steps": [
    {"text": "A concrete action (1 sentence, completable within 30 minutes)"}
  ]
}

Rules:
- steps must contain exactly 10 items
- each action must be startable tomorrow and completable within 30 minutes
- these are meant as a meaningful first step, not an attempt to complete the whole strategy
- each action should, as much as possible, satisfy the three elements of intrinsic motivation: "Can you decide it yourself?", "Can you see your results clearly?", "Are you connected with others?"
- Write text in English
''';
      case PromptLanguage.vietnamese:
        return '''
Không viết lời mở đầu. Chỉ xuất JSON.
Bạn là huấn luyện viên hỗ trợ hành động. Dựa trên phương sách người dùng đã quyết định, hãy đề xuất 10 hành động có thể bắt đầu từ ngày mai và hoàn thành trong vòng 30 phút để khởi động phương sách đó.

Schema đầu ra (chỉ trả JSON này):
{
  "steps": [
    {"text": "Hành động cụ thể (1 câu, hoàn thành trong 30 phút)"}
  ]
}

Quy tắc:
- steps đúng 10 mục
- mỗi hành động phải bắt đầu được từ ngày mai và hoàn thành trong 30 phút
- đây là bước đầu có ý nghĩa, không phải hoàn thành toàn bộ phương sách
- mỗi hành động nên thỏa càng nhiều càng tốt 3 yếu tố của động lực nội tại: "Bạn có thể tự quyết định không?", "Bạn có thấy rõ thành quả không?", "Bạn có kết nối với mọi người không?"
- Viết text bằng tiếng Việt
''';
    }
  }

  static String firstStepUserPrompt({
    required String theme,
    required String desiredGoal,
    required String decidedStrategy,
    PromptLanguage language = PromptLanguage.japanese,
  }) {
    switch (language) {
      case PromptLanguage.japanese:
        return (StringBuffer()
              ..writeln('テーマ: $theme')
              ..writeln('在りたい姿: $desiredGoal')
              ..writeln('決めた方策: $decidedStrategy')
              ..writeln()
              ..writeln(
                '上記の方策をもとに、指示された条件とJSONスキーマに従って最初の一歩の候補を提案してください。',
              ))
            .toString()
            .trim();
      case PromptLanguage.english:
        return (StringBuffer()
              ..writeln('Theme: $theme')
              ..writeln('Desired outcome: $desiredGoal')
              ..writeln('Decided strategy: $decidedStrategy')
              ..writeln()
              ..writeln(
                'Using the above strategy, propose first-step candidates following the given conditions and JSON schema.',
              ))
            .toString()
            .trim();
      case PromptLanguage.vietnamese:
        return (StringBuffer()
              ..writeln('Chủ đề: $theme')
              ..writeln('Trạng thái mong muốn: $desiredGoal')
              ..writeln('Phương sách đã quyết: $decidedStrategy')
              ..writeln()
              ..writeln(
                'Dựa trên phương sách trên, hãy đề xuất các bước đầu theo điều kiện và schema JSON đã cho.',
              ))
            .toString()
            .trim();
    }
  }

  static String firstStepChromeAiPrompt({
    required String theme,
    required String desiredGoal,
    required String decidedStrategy,
    PromptLanguage language = PromptLanguage.japanese,
  }) {
    final system = firstStepSystemPrompt(language);
    final user = firstStepUserPrompt(
      theme: theme,
      desiredGoal: desiredGoal,
      decidedStrategy: decidedStrategy,
      language: language,
    );
    return '$system\n\n$user';
  }
}
