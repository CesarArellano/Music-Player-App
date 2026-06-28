import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// A vertical A–Z fast-scroll rail (à la Muzio Player).
///
/// Performance notes:
/// * The rail of letters is laid out once. Dragging only rebuilds the active
///   index via a [ValueNotifier], so the letter [Text]s are not recreated and
///   the host list is never rebuilt — it's just scrolled.
/// * Letter → list-position mapping is O(1): each letter owns a fixed slice of
///   the rail height, so the touched index is `dy ~/ sliceHeight`.
class AlphabetScrollbar extends StatefulWidget {
  const AlphabetScrollbar({
    super.key,
    required this.letters,
    required this.onLetterSelected,
    this.width = 24.0,
  });

  /// Letters to show, already de-duplicated and in display order.
  final List<String> letters;

  /// Called with the touched letter on tap and during a drag.
  final ValueChanged<String> onLetterSelected;

  /// Width of the rail.
  final double width;

  @override
  State<AlphabetScrollbar> createState() => _AlphabetScrollbarState();
}

class _AlphabetScrollbarState extends State<AlphabetScrollbar> {
  // Drives the active-letter highlight + the floating bubble only.
  final ValueNotifier<int?> _activeIndex = ValueNotifier<int?>(null);

  double _sliceHeight = 0;

  @override
  void dispose() {
    _activeIndex.dispose();
    super.dispose();
  }

  void _select(double dy) {
    if (widget.letters.isEmpty || _sliceHeight <= 0) return;
    final index =
        (dy ~/ _sliceHeight).clamp(0, widget.letters.length - 1);
    if (index != _activeIndex.value) {
      _activeIndex.value = index;
      widget.onLetterSelected(widget.letters[index]);
      HapticFeedback.selectionClick();
    }
  }

  void _clear() => _activeIndex.value = null;

  @override
  Widget build(BuildContext context) {
    if (widget.letters.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        _sliceHeight = constraints.maxHeight / widget.letters.length;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _select(d.localPosition.dy),
          onTapUp: (_) => _clear(),
          onVerticalDragStart: (d) => _select(d.localPosition.dy),
          onVerticalDragUpdate: (d) => _select(d.localPosition.dy),
          onVerticalDragEnd: (_) => _clear(),
          onVerticalDragCancel: _clear,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _Rail(
                letters: widget.letters,
                width: widget.width,
                sliceHeight: _sliceHeight,
                activeIndex: _activeIndex,
              ),
              _Bubble(
                letters: widget.letters,
                sliceHeight: _sliceHeight,
                activeIndex: _activeIndex,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The always-on rail. Each letter occupies a fixed [sliceHeight] slice so the
/// touch mapping stays exact.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.letters,
    required this.width,
    required this.sliceHeight,
    required this.activeIndex,
  });

  final List<String> letters;
  final double width;
  final double sliceHeight;
  final ValueNotifier<int?> activeIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(width / 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(letters.length, (i) {
          return SizedBox(
            height: sliceHeight,
            child: Center(
              child: ValueListenableBuilder<int?>(
                valueListenable: activeIndex,
                builder: (context, active, _) {
                  final isActive = active == i;
                  return Text(
                    letters[i],
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.0,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive
                          ? AppTheme.accentColor
                          : AppTheme.lightTextColor,
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// The floating pill that shows the current letter, centred on the touched
/// slice and offset to the left of the rail.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.letters,
    required this.sliceHeight,
    required this.activeIndex,
  });

  final List<String> letters;
  final double sliceHeight;
  final ValueNotifier<int?> activeIndex;

  static const double _size = 48.0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: activeIndex,
      builder: (context, active, _) {
        if (active == null) return const SizedBox.shrink();

        final centerY = (active + 0.5) * sliceHeight;
        return Positioned(
          right: 34,
          top: centerY - _size / 2,
          child: Container(
            width: _size + 16,
            height: _size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              borderRadius: BorderRadius.circular(_size / 2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8),
              ],
            ),
            child: Text(
              letters[active],
              style: const TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
