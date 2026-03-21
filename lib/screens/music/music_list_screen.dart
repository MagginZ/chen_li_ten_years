import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_container.dart';
import '../../ble/ble_controller.dart';
import 'controller/music_list_controller.dart';
import 'event/music_list_event.dart';
/// 歌单列表页：按 index.html 布局，使用主题色
class MusicListScreen extends StatefulWidget {
  const MusicListScreen({
    super.key,
    required this.onTrackTap,
  });

  final void Function(MusicTrack track) onTrackTap;

  @override
  State<MusicListScreen> createState() => _MusicListScreenState();
}

class _MusicListScreenState extends State<MusicListScreen> {
  late final MusicListController _controller;
  late final MusicListEvent _event;

  @override
  void initState() {
    super.initState();
    _controller = MusicListController();
    _event = MusicListEvent(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, BleController.instance]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // 顶部光晕
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 100,
                        spreadRadius: 40,
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Hero: PLAYLIST + Sync Light
                      _PlaylistHeader(
                        controller: _controller,
                        event: _event,
                      ),
                      const SizedBox(height: 32),
                      // Featured: Now Playing Bento
                      _NowPlayingBento(
                        track: MusicListController.tracks[_controller.nowPlayingIndex],
                        onShuffle: () {},
                        onFavorite: () {},
                      ),
                      const SizedBox(height: 24),
                      // Track List
                      _TrackListSection(
                        controller: _controller,
                        event: _event,
                        onTrackTap: widget.onTrackTap,
                      ),
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
                'PLAYLIST',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                MusicListController.playlistName,
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
                'SYNC LIGHT',
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

class _NowPlayingBento extends StatelessWidget {
  const _NowPlayingBento({
    required this.track,
    required this.onShuffle,
    required this.onFavorite,
  });

  final MusicTrack track;
  final VoidCallback onShuffle;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    // 用 AspectRatio 约束高度，避免 unbounded height 导致布局崩溃
    return AspectRatio(
      aspectRatio: 6 / 4,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 大图：Now Playing
          Expanded(
            flex: 4,
            child: AspectRatio(
                aspectRatio: 1,
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
                                'LIVE SYNC',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              track.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
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
              ),
            ),
          const SizedBox(width: 16),
          // 右侧按钮
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _BentoButton(
                    icon: Icons.shuffle,
                    color: AppColors.primary,
                    onTap: onShuffle,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _BentoButton(
                    icon: Icons.favorite,
                    color: AppColors.secondary,
                    onTap: onFavorite,
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _BentoButton extends StatelessWidget {
  const _BentoButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Center(
                child: Icon(icon, size: 40, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackListSection extends StatelessWidget {
  const _TrackListSection({
    required this.controller,
    required this.event,
    required this.onTrackTap,
  });

  final MusicListController controller;
  final MusicListEvent event;
  final void Function(MusicTrack track) onTrackTap;

  @override
  Widget build(BuildContext context) {
    final tracks = controller.displayTracks;
    final nowPlayingIdx = controller.nowPlayingIndex;

    return Column(
      children: List.generate(tracks.length, (i) {
        final track = tracks[i];
        final isNowPlaying = i == nowPlayingIdx;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _TrackListItem(
            track: track,
            isNowPlaying: isNowPlaying,
            onTap: () {
              event.selectTrack(i);
              onTrackTap(track);
            },
          ),
        );
      }),
    );
  }
}

class _TrackListItem extends StatelessWidget {
  const _TrackListItem({
    required this.track,
    required this.isNowPlaying,
    required this.onTap,
  });

  final MusicTrack track;
  final bool isNowPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isNowPlaying
          ? AppColors.surfaceContainerHigh
          : AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isNowPlaying
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 1,
                  )
                : null,
            boxShadow: isNowPlaying
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // 封面
              ClipRRect(
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
                              Icons.pause,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 标题
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight:
                            isNowPlaying ? FontWeight.bold : FontWeight.w500,
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
              // 右侧图标
              if (isNowPlaying)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildWaveform(context),
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
    );
  }

  Widget _buildWaveform(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _WaveBar(height: 8),
          _WaveBar(height: 12),
          _WaveBar(height: 6),
        ],
      ),
    );
  }
}

class _WaveBar extends StatelessWidget {
  const _WaveBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
