import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// A compact vertical A–Z fast-scroll rail (à la Muzio Player).
///
/// It auto-reveals while the host list is scrolling (or while the rail is being
/// dragged) and fades out shortly after activity stops.
///
/// Performance notes:
/// * The rail of letters is laid out once. Dragging only rebuilds the active
///   index via a [ValueNotifier], so the letter [Text]s are not recreated and
///   the host list is never rebuilt — it's just scrolled.
/// * Letter → list-position mapping is O(1): each letter owns a fixed
///   [letterExtent] slice, so the touched index is `dy ~/ letterExtent`.
class AlphabetScrollbar extends StatefulWidget {
  const AlphabetScrollbar({
    super.key,
    required this.letters,
    required this.onLetterSelected,
    required this.controller,
    this.width = 16.0,
    this.letterExtent = 16.0,
  });

  /// Letters to show, already de-duplicated and in display order.
  final List<String> letters;

  /// Called with the touched letter on tap and during a drag.
  final ValueChanged<String> onLetterSelected;

  /// Scroll controller of the host list. The rail is visible only while this
  /// controller reports scroll activity (plus a short lingering delay).
  final ScrollController controller;

  /// Width of the rail.
  final double width;

  /// Fixed height per letter; keeps the touch→index mapping exact.
  final double letterExtent;

  @override
  State<AlphabetScrollbar> createState() => _AlphabetScrollbarState();
}

class _AlphabetScrollbarState extends State<AlphabetScrollbar> {
  // Drives the active-letter highlight + the floating bubble only.
  final ValueNotifier<int?> _activeIndex = ValueNotifier<int?>(null);

  // Drives the show/hide fade only.
  final ValueNotifier<bool> _visible = ValueNotifier<bool>(false);

  Timer? _hideTimer;
  bool _dragging = false;

  static const Duration _lingerDuration = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_reveal);
  }

  @override
  void didUpdateWidget(covariant AlphabetScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_reveal);
      widget.controller.addListener(_reveal);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_reveal);
    _activeIndex.dispose();
    _visible.dispose();
    super.dispose();
  }

  // Show the rail and (re)arm the hide timer. Cheap to call on every scroll
  // tick: the notifier only fires when the value actually changes.
  void _reveal() {
    _visible.value = true;
    _hideTimer?.cancel();
    _hideTimer = Timer(_lingerDuration, () {
      if (!_dragging) _visible.value = false;
    });
  }

  void _select(double dy) {
    if (widget.letters.isEmpty) return;
    final index =
        (dy ~/ widget.letterExtent).clamp(0, widget.letters.length - 1);
    if (index != _activeIndex.value) {
      _activeIndex.value = index;
      widget.onLetterSelected(widget.letters[index]);
      HapticFeedback.selectionClick();
    }
  }

  void _startDrag(double dy) {
    _dragging = true;
    _reveal();
    _select(dy);
  }

  void _endDrag() {
    _dragging = false;
    _activeIndex.value = null;
    _reveal();
  }

  @override
  Widget build(BuildContext context) {
    Orientation orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.landscape) {
      return const SizedBox.shrink();
    }
    if (widget.letters.isEmpty) return const SizedBox.shrink();

    return ValueListenableBuilder<bool>(
      valueListenable: _visible,
      builder: (context, visible, child) {
        return IgnorePointer(
          ignoring: !visible,
          child: AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _startDrag(d.localPosition.dy),
        onTapUp: (_) => _endDrag(),
        onVerticalDragStart: (d) => _startDrag(d.localPosition.dy),
        onVerticalDragUpdate: (d) => _select(d.localPosition.dy),
        onVerticalDragEnd: (_) => _endDrag(),
        onVerticalDragCancel: _endDrag,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _Rail(
              letters: widget.letters,
              width: widget.width,
              letterExtent: widget.letterExtent,
              activeIndex: _activeIndex,
            ),
            _Bubble(
              letters: widget.letters,
              letterExtent: widget.letterExtent,
              activeIndex: _activeIndex,
            ),
          ],
        ),
      ),
    );
  }
}

/// The compact rail. Each letter occupies a fixed [letterExtent] slice so the
/// touch mapping stays exact and the rail wraps its content height.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.letters,
    required this.width,
    required this.letterExtent,
    required this.activeIndex,
  });

  final List<String> letters;
  final double width;
  final double letterExtent;
  final ValueNotifier<int?> activeIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(width / 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(letters.length, (i) {
          return SizedBox(
            height: letterExtent,
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
                          isActive ? FontWeight.bold : FontWeight.w600,
                      color: Colors.white,
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
    required this.letterExtent,
    required this.activeIndex,
  });

  final List<String> letters;
  final double letterExtent;
  final ValueNotifier<int?> activeIndex;

  static const double _size = 48.0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: activeIndex,
      builder: (context, active, _) {
        if (active == null) return const SizedBox.shrink();

        final centerY = (active + 0.5) * letterExtent;
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
