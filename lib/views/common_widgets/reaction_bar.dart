import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:brevity/controller/cubit/theme/theme_cubit.dart';

enum ReactionType {
  like('👍'),
  dislike('👎');

  const ReactionType(this.emoji);
  final String emoji;
}

class ReactionData {
  final ReactionType type;
  final int count;
  final bool isSelected;

  const ReactionData({
    required this.type,
    required this.count,
    required this.isSelected,
  });

  ReactionData copyWith({
    ReactionType? type,
    int? count,
    bool? isSelected,
  }) {
    return ReactionData(
      type: type ?? this.type,
      count: count ?? this.count,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class ReactionBar extends StatefulWidget {
  final String articleId;
  final Function(ReactionType, bool)? onReactionTap;
  final List<ReactionData>? initialReactions;

  const ReactionBar({
    super.key,
    required this.articleId,
    this.onReactionTap,
    this.initialReactions,
  });

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  late Map<ReactionType, ReactionData> _reactions;

  @override
  void initState() {
    super.initState();
    _initializeReactions();
  }

  void _initializeReactions() {
    _reactions = {};

    // Initialize with provided reactions or defaults
    if (widget.initialReactions != null) {
      for (final reaction in widget.initialReactions!) {
        _reactions[reaction.type] = reaction;
      }
    }

    // Ensure all reaction types exist with defaults
    for (final type in ReactionType.values) {
      _reactions[type] ??= ReactionData(
        type: type,
        count: 0,
        isSelected: false,
      );
    }
  }

  void _handleReactionTap(ReactionType type) {
    final currentReaction = _reactions[type]!;
    final isCurrentlySelected = currentReaction.isSelected;

    setState(() {
      if (isCurrentlySelected) {
        // If tapping the already selected reaction, deselect it
        _reactions[type] = currentReaction.copyWith(
          isSelected: false,
          count: currentReaction.count - 1,
        );
        widget.onReactionTap?.call(type, false);
      } else {
        // Find and deselect any currently selected reaction
        ReactionType? previouslySelected;
        for (final entry in _reactions.entries) {
          if (entry.value.isSelected) {
            previouslySelected = entry.key;
            _reactions[entry.key] = entry.value.copyWith(
              isSelected: false,
              count: entry.value.count - 1,
            );
            break;
          }
        }

        // Select the new reaction
        _reactions[type] = currentReaction.copyWith(
          isSelected: true,
          count: currentReaction.count + 1,
        );

        // Callback for deselected reaction (if any)
        if (previouslySelected != null) {
          widget.onReactionTap?.call(previouslySelected, false);
        }

        // Callback for newly selected reaction
        widget.onReactionTap?.call(type, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = context.read<ThemeCubit>().currentTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ReactionButton(
          reaction: _reactions[ReactionType.like]!,
          onTap: () => _handleReactionTap(ReactionType.like),
          primaryColor: currentTheme.primaryColor,
        ),
        const Gap(16),
        _ReactionButton(
          reaction: _reactions[ReactionType.dislike]!,
          onTap: () => _handleReactionTap(ReactionType.dislike),
          primaryColor: currentTheme.primaryColor,
        ),
      ],
    );
  }
}

class _ReactionButton extends StatefulWidget {
  final ReactionData reaction;
  final VoidCallback onTap;
  final Color primaryColor;

  const _ReactionButton({
    required this.reaction,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _pressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _pressAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pressAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.reaction.isSelected
                      ? widget.primaryColor
                      : Colors.white.withOpacity(0.6),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.reaction.type.emoji,
                    style: TextStyle(
                      fontSize: 16,
                      shadows: widget.reaction.isSelected
                          ? [
                        Shadow(
                          blurRadius: 4,
                          color: widget.primaryColor.withOpacity(0.5),
                          offset: const Offset(0, 0),
                        ),
                      ]
                          : null,
                    ),
                  ),
                  if (widget.reaction.count > 0) ...[
                    const Gap(6),
                    Text(
                      widget.reaction.count > 999
                          ? '${(widget.reaction.count / 1000).toStringAsFixed(1)}k'
                          : widget.reaction.count.toString(),
                      style: TextStyle(
                        color: widget.reaction.isSelected
                            ? widget.primaryColor
                            : Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
