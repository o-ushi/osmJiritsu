import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// One captured idea rendered as a chat-style bubble in the idea-dump list.
/// Deliberately has no category chrome — step 2 is a judgment-free dump,
/// classification happens later.
///
/// Give each bubble a `ValueKey(idea.id)` when building it in a list: the
/// fade/slide-in below plays once per `State`, so a stable key makes it
/// play exactly once as each new idea appears rather than replaying on
/// every rebuild.
class IdeaBubbleCard extends StatefulWidget {
  final String text;
  final VoidCallback onDelete;

  const IdeaBubbleCard({super.key, required this.text, required this.onDelete});

  @override
  State<IdeaBubbleCard> createState() => _IdeaBubbleCardState();
}

class _IdeaBubbleCardState extends State<IdeaBubbleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(curved),
        child: _Bubble(text: widget.text, onDelete: widget.onDelete),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final VoidCallback onDelete;

  const _Bubble({required this.text, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.only(
            left: 18,
            top: 12,
            bottom: 12,
            right: 8,
          ),
          decoration: BoxDecoration(
            color: AppPalette.cardFill,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFFB8C7C1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
