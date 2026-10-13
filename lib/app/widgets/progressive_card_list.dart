import 'dart:async';

import 'package:flutter/material.dart';

import '../app_ui_tokens.dart';

/// Reveals five cards per scroll boundary; offscreen elements remain lazy.
/// The current BE returns complete lists, so this does not paginate HTTP reads.
class ProgressiveCardList extends StatefulWidget {
  const ProgressiveCardList({
    super.key,
    this.header = const [],
    required this.items,
    this.resetKey,
    this.padding,
    this.resetScroll = true,
  });
  final List<Widget> header, items;
  final Object? resetKey;
  final EdgeInsetsGeometry? padding;
  final bool resetScroll;

  @override
  State<ProgressiveCardList> createState() => _ProgressiveCardListState();
}

class _ProgressiveCardListState extends State<ProgressiveCardList> {
  static const _batchSize = 5;
  static const _loadingDuration = Duration(milliseconds: 700);
  final _scroll = ScrollController();
  final _viewportKey = GlobalKey();
  final _footerKey = GlobalKey();
  int _visible = _batchSize;
  int _revision = 0;
  bool _showTop = false;
  bool _updateScheduled = false;
  bool _morePending = false;
  bool _loading = false;
  Timer? _loadingTimer;

  bool get _footerReached {
    final footer = _footerKey.currentContext?.findRenderObject();
    final viewport = _viewportKey.currentContext?.findRenderObject();
    if (footer is! RenderBox ||
        viewport is! RenderBox ||
        !footer.attached ||
        !viewport.attached ||
        !footer.hasSize ||
        !viewport.hasSize) {
      return false;
    }
    final top = footer.localToGlobal(Offset.zero, ancestor: viewport).dy;
    return top >= 0 && top + footer.size.height <= viewport.size.height;
  }

  void _loadNext() {
    if (_loading || _visible >= widget.items.length) return;
    setState(() => _loading = true);
    final revision = _revision;
    // Count the delay from the frame that actually displays the indicator.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || revision != _revision) return;
      _loadingTimer = Timer(_loadingDuration, () {
        if (!mounted || revision != _revision) return;
        setState(() {
          _visible = (_visible + _batchSize).clamp(0, widget.items.length);
          _loading = false;
        });
      });
    });
  }

  @override
  void didUpdateWidget(covariant ProgressiveCardList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetKey != widget.resetKey) {
      _revision++;
      _loadingTimer?.cancel();
      _loading = false;
      _visible = _batchSize;
      _morePending = false;
      if (widget.resetScroll) {
        _showTop = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              _scroll.hasClients &&
              _scroll.position.hasContentDimensions) {
            _scroll.jumpTo(0);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = _visible.clamp(0, widget.items.length);
    final hasMore = count < widget.items.length;
    final nextCount = (widget.items.length - count).clamp(0, _batchSize);
    return Stack(
      key: _viewportKey,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (event) {
            if (event.depth != 0 || event.metrics.axis != Axis.vertical) {
              return false;
            }
            final show = event.metrics.pixels > 240;
            final forward = switch (event) {
              ScrollUpdateNotification() => (event.scrollDelta ?? 0) > 0,
              OverscrollNotification() => event.overscroll > 0,
              _ => false,
            };
            // An estimated scroll extent can change as variable-height cards
            // are built. Reveal only after the actual last card is reached.
            final more = forward && !_loading && _footerReached && hasMore;
            _morePending = _morePending || more;
            if ((show != _showTop || more) && !_updateScheduled) {
              _updateScheduled = true;
              final revision = _revision;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateScheduled = false;
                if (!mounted || revision != _revision) return;
                final loadMore = _morePending && _footerReached;
                setState(() {
                  _showTop =
                      _scroll.hasClients &&
                      _scroll.position.hasPixels &&
                      _scroll.offset > 240;
                  _morePending = false;
                });
                if (loadMore) _loadNext();
              });
            }
            return false;
          },
          child: ListView.builder(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: widget.padding ?? AppSpacing.pagePadding(context),
            itemCount: widget.header.length + count + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < widget.header.length) return widget.header[index];
              final card = index - widget.header.length;
              if (card < count) return widget.items[card];
              return Padding(
                key: _footerKey,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  height: 48,
                  child: _loading
                      ? Semantics(
                          liveRegion: true,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('불러오는 중…', style: AppTypography.helper),
                            ],
                          ),
                        )
                      : TextButton.icon(
                          onPressed: _loadNext,
                          icon: const Icon(Icons.expand_more),
                          label: Text('다음 $nextCount개 더 보기'),
                        ),
                ),
              );
            },
          ),
        ),
        if (_showTop)
          Positioned(
            right: 12,
            top: 8,
            child: Material(
              elevation: 4,
              color: AppColors.surface,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: '맨 위로',
                color: AppColors.primary,
                onPressed: () => _scroll.animateTo(
                  0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                ),
                icon: const Icon(Icons.vertical_align_top),
              ),
            ),
          ),
      ],
    );
  }
}
