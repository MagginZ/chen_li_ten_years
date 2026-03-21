import 'package:flutter/material.dart';
import '../../../ble/ble_controller.dart';

/// 歌单中的单曲
class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String? coverUrl;
  final bool isNowPlaying;

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.coverUrl,
    this.isNowPlaying = false,
  });
}

class MusicListController extends ChangeNotifier {
  static const String playlistName = 'Starlight World Tour 2024';

  static final List<MusicTrack> tracks = [
    const MusicTrack(
      id: '1',
      title: 'CYBER HEART',
      artist: 'NOVA-7',
      coverUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuANzCjHDCyceQG7b7Z087PcbymFFAao8TNqduqQfpCQAR-6fx2WsCDvLdSMJzBQigXULihTFQb9mkBnMDIPBcd4b5k1mtPJkrSH0T8TFx0bi2-QOsD6ASHGBXUCE1lEP02xsdWu8WQSS2X-744-NoHILQFbrZvOxNthRbvnng37ofJln290Wv6DlDVy-4bz_bRBHydGgQvAF2aKB4xxHasmv1VocYMeDHulZGvebwAtHZ3eXE3LRwomrkKGWXceCAt2XO6qOYNUJhHt',
      isNowPlaying: true,
    ),
    const MusicTrack(
      id: '2',
      title: 'NEON DREAMS',
      artist: 'LUNAR ECLIPSE',
      coverUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB5bPkJtXHYLQRhHc8hE3zM8kCxLAt998RNK5qEW6TV_2HSHbf76q-vWCd5QyzdEElLnp8fvEJ4g4gu65B9c2Fti_0BdYf9Zrjtk2iJ4ND7tr4ia60TrlG-86yFJLChH0SJdxlvRLC49pleAOoLpAiS-3qIjPR4UaeGpezMp-G-UdgVq8ORPz5TT2XmW3f7UAJaZN0hvdRTfznfrySd8oeIQl7VOwg7rvCYlXPLqjT1aEXGEvSp_tcBvkzlrLRcqzgweSScbi9cTRc1',
    ),
    const MusicTrack(
      id: '3',
      title: 'STADIUM ECHO',
      artist: 'THE VIBE COLLECTIVE',
      coverUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCyvlFpwbe8b-vQ6fDbAZ85zHvoPvTzIYT5sSTBqSBmr0ypEqBS3y9HMyAYQVHlhyXsPwG1pltqTkC097fUQSSxHZoYILtjhPV6LBJiYtwlL4dEYTahoeGKDNrz3ecn_bYkcfawpClrzJHILnlAMPyHT12nayEC3n8FSmAqdu3uIBAgvUYkTMlcudkMNUBLpE_zvrsRFzrcZZqqd4r4nOd6LIdxq_blh5IdRU9wDjUF-UqjrZDxpV46ItJTYlL8hHYLayurN1At4bwG',
    ),
    const MusicTrack(
      id: '4',
      title: 'BASSLINE RIOT',
      artist: 'VIRTUAL RIOT',
      coverUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAls3EVyC52rXHY48StQfew5tiuupg27kRNk7RILGyy19YPDn4dSKheBi7sp4R6sGnXvOIez4UBJEIZb9U5tFbtUhkRDcEMhUFDf4rtYc7cbJa0gEyHQOUfG0vAeZD-e6dTvgQXKky4F2OWLSq52UBTc2B7yWf1g96dWl_vzZ7AT08xe8miZbPgu7bUBV9y8Q0yXtnyjM-OwzOfIxk06yasupxJpsoqqFlJHPyaj16jH2VwyyqZ0n-RK-TX94RgucLuamyGdcswZmpj',
    ),
    const MusicTrack(
      id: '5',
      title: 'GLOW STICK ANTHEM',
      artist: 'FANDOM CORE',
      coverUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB__aFk4DK_tcZ3Bmj0e01ZqnPEEG9KSmssKgtZLRJl3GG-npISuox0TcFP1Ubu7XG0pA9HkdQP-WnCWujs7BTeV2RiT-iDAm18kVqPBMe40uP4OZAnLSZS-W1WRJMU49EHandKJWf2RaWn2Vzi2OM_uP617DLBxLZAdRR0c3Row8iLDoNM4fxGLPoH5W7Pf_AcPK8jWis38VNQH6HoDf0snKKwNXd-0x9XoqdtxMbGwPVNenyntfpyxg10ka38ouZwnE0l1iWRxBT6',
    ),
  ];

  int _nowPlayingIndex = 0;

  List<MusicTrack> get displayTracks => tracks;
  int get nowPlayingIndex => _nowPlayingIndex;
  bool get syncEnabled => BleController.instance.autoSyncEnabled;

  void setNowPlayingIndex(int index) {
    _nowPlayingIndex = index;
    notifyListeners();
  }

  void toggleSync() {
    BleController.instance.setAutoSync(!BleController.instance.autoSyncEnabled);
    notifyListeners();
  }

  void selectTrack(int index) {
    _nowPlayingIndex = index;
    notifyListeners();
  }
}
