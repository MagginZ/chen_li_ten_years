import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_container.dart';
import 'controller/music_controller.dart';
import 'controller/music_list_controller.dart';
import 'event/music_list_event.dart';

/// 歌单列表页：搜索、分页、播放
class MusicListScreen extends StatefulWidget {
  const MusicListScreen({
    super.key,
    required this.controller,
    required this.playback,
    required this.onCoverTap,
    required this.onRowOpenDetail,
  });

  final MusicListController controller;
  final MusicController playback;
  final Future<void> Function(MusicTrack track, int index) onCoverTap;
  final Future<void> Function(MusicTrack track, int index) onRowOpenDetail;

  @override
  State<MusicListScreen> createState() => _MusicListScreenState();
}

class _MusicListScreenState extends State<MusicListScreen> {
  late final MusicListEvent _event;

  @override
  void initState() {
    super.initState();
    _event = MusicListEvent(widget.controller);
    widget.controller.loadPlaylist();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, widget.playback]),
      builder: (context, _) {
        final tracks = widget.controller.displayTracks;
        if (tracks.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: widget.controller.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : Center(child: TextButton(onPressed: () => widget.controller.retry(), child: const Text('重试加载'))),
          );
        }
        final nowPlaying = widget.controller.nowPlayingIndex < tracks.length
            ? tracks[widget.controller.nowPlayingIndex]
            : null;
        final nowPlayingIdx = widget.controller.nowPlayingIndex;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              Positioned(
                top: -80,
                right: -80,
                child: RepaintBoundary(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 44,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.controller.isLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: CustomScrollView(
                    slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    SliverToBoxAdapter(
                      child: _SearchBar(
                        initialKeyword: widget.controller.searchKeyword,
                        onSearch: (kw) => widget.controller.search(kw),
                        isLoading: widget.controller.isLoading,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _PlaylistHeader(
                          controller: widget.controller,
                          event: _event,
                        ),
                      ),
                    ),
                    if (widget.controller.error != null) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber, color: AppColors.error),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '歌单加载失败，使用默认列表',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.onErrorContainer,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => widget.controller.retry(),
                                  child: const Text('重试'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    if (nowPlaying != null)
                      SliverToBoxAdapter(
                        child: _NowPlayingBento(track: nowPlaying),
                      ),
                    if (nowPlaying != null) const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    SliverList.separated(
                      itemCount: tracks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final track = tracks[i];
                        final isNowPlaying = i == nowPlayingIdx;
                        return _TrackListItem(
                          track: track,
                          isNowPlaying: isNowPlaying,
                          isPlaying: widget.playback.isPlaying && isNowPlaying,
                          onCoverTap: () {
                            widget.onCoverTap(track, i);
                          },
                          onRowTap: () {
                            widget.onRowOpenDetail(track, i);
                          },
                        );
                      },
                    ),
                    if (widget.controller.hasMore)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 24),
                          child: SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: widget.controller.isLoadingMore ? null : () => widget.controller.loadMore(),
                              child: widget.controller.isLoadingMore
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('加载更多'),
                            ),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlaylistHeader extends StatelessWidget {
  const _PlaylistHeader({
    required this.controller,
    required this.event,
  });

  final MusicListController controller;
  final MusicListEvent event;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '歌单',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '搜索: ${controller.searchKeyword}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '灯光同步',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => event.toggleSync(),
                child: Container(
                  width: 56,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Align(
                      alignment: controller.syncEnabled
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.6),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({
    required this.initialKeyword,
    required this.onSearch,
    required this.isLoading,
  });

  final String initialKeyword;
  final void Function(String keyword) onSearch;
  final bool isLoading;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialKeyword);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: '搜索歌手或歌曲...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixIcon: widget.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onSubmitted: (v) => widget.onSearch(v),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => widget.onSearch(_textController.text),
            icon: const Icon(Icons.search),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _NowPlayingBento extends StatelessWidget {
  const _NowPlayingBento({required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
                    fit: StackFit.expand,
                    children: [
            _TrackCoverImage(url: track.coverUrl),
            GradientDecoration(
              colors: [
                Colors.transparent,
                AppColors.black.withValues(alpha: 0.8),
              ],
            ),
            Positioned(
              left: 16,
              bottom: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '正在播放',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    track.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackCoverImage extends StatelessWidget {
  const _TrackCoverImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: AppColors.surfaceContainerHigh,
        child: Center(
          child: Icon(Icons.music_note, size: 48, color: AppColors.primary),
        ),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.8),
              AppColors.tertiary.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Center(
          child: Icon(Icons.album, size: 64, color: AppColors.white.withValues(alpha: 0.5)),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.surfaceContainerHigh,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class GradientDecoration extends StatelessWidget {
  const GradientDecoration({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
        ),
      ),
    );
  }
}

class _TrackListItem extends StatelessWidget {
  const _TrackListItem({
    required this.track,
    required this.isNowPlaying,
    required this.isPlaying,
    required this.onCoverTap,
    required this.onRowTap,
  });

  final MusicTrack track;
  final bool isNowPlaying;
  /// 当前行是否为列表选中项且播放器正在播放（用于封面与均衡器动效）
  final bool isPlaying;
  final VoidCallback onCoverTap;
  final VoidCallback onRowTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isNowPlaying
          ? AppColors.surfaceContainerHigh
          : AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isNowPlaying
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.55),
                  width: 1,
                )
              : null,
          boxShadow: isNowPlaying
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onCoverTap,
              behavior: HitTestBehavior.opaque,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _TrackCoverImage(url: track.coverUrl),
                      if (isNowPlaying)
                        Container(
                          color: AppColors.black.withValues(alpha: 0.4),
                          child: Center(
                            child: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRowTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                track.title,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: isNowPlaying
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isNowPlaying
                                          ? AppColors.primary
                                          : AppColors.onSurface,
                                      letterSpacing: 0.5,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                track.artist,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isNowPlaying)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _EqualizerBars(active: isPlaying),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.more_vert,
                                color: AppColors.onSurfaceVariant,
                                size: 24,
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow,
                                color: AppColors.onSurfaceVariant,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.more_vert,
                                color: AppColors.onSurfaceVariant,
                                size: 24,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 播放中时的简易均衡器条动画（暂停时为静态低条）
class _EqualizerBars extends StatefulWidget {
  const _EqualizerBars({required this.active});

  final bool active;

  @override
  State<_EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<_EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && oldWidget.active) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 18,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = widget.active ? _controller.value : 0.0;
          double barH(int phaseSteps) {
            final wave = 0.5 + 0.5 * math.sin(t * math.pi * 2 + phaseSteps * 0.9);
            return (4 + 12 * wave).clamp(4.0, 16.0);
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _eqBar(barH(0)),
              _eqBar(barH(2)),
              _eqBar(barH(4)),
            ],
          );
        },
      ),
    );
  }

  Widget _eqBar(double h) {
    return Container(
      width: 4,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
