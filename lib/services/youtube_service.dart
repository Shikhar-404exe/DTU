

library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class YouTubeVideo {
  final String videoId;
  final String title;
  final String description;
  final String thumbnail;
  final String channelTitle;
  final String channelId;
  final String publishedAt;
  final String url;
  final int? viewCount;
  final int? likeCount;
  final String? duration;

  YouTubeVideo({
    required this.videoId,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.channelTitle,
    required this.channelId,
    required this.publishedAt,
    required this.url,
    this.viewCount,
    this.likeCount,
    this.duration,
  });

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    return YouTubeVideo(
      videoId: json['video_id'] ?? json['id']?['videoId'] ?? '',
      title: json['title'] ?? json['snippet']?['title'] ?? '',
      description: json['description'] ?? json['snippet']?['description'] ?? '',
      thumbnail: json['thumbnail'] ??
          json['snippet']?['thumbnails']?['medium']?['url'] ??
          '',
      channelTitle:
          json['channel_title'] ?? json['snippet']?['channelTitle'] ?? '',
      channelId: json['channel_id'] ?? json['snippet']?['channelId'] ?? '',
      publishedAt:
          json['published_at'] ?? json['snippet']?['publishedAt'] ?? '',
      url: json['url'] ??
          'https://www.youtube.com/watch?v=${json['video_id'] ?? json['id']?['videoId'] ?? ''}',
      viewCount: json['view_count'],
      likeCount: json['like_count'],
      duration: json['duration'],
    );
  }

  factory YouTubeVideo.fromYouTubeApi(Map<String, dynamic> item) {
    final snippet = item['snippet'] ?? {};
    final id = item['id'];
    final videoId = id is String ? id : (id?['videoId'] ?? '');

    return YouTubeVideo(
      videoId: videoId,
      title: snippet['title'] ?? '',
      description: snippet['description'] ?? '',
      thumbnail: snippet['thumbnails']?['medium']?['url'] ??
          snippet['thumbnails']?['default']?['url'] ??
          '',
      channelTitle: snippet['channelTitle'] ?? '',
      channelId: snippet['channelId'] ?? '',
      publishedAt: snippet['publishedAt'] ?? '',
      url: 'https://www.youtube.com/watch?v=$videoId',
    );
  }
}

class YouTubeChannel {
  final String name;
  final String id;
  final String language;

  YouTubeChannel({
    required this.name,
    required this.id,
    required this.language,
  });

  factory YouTubeChannel.fromJson(Map<String, dynamic> json) {
    return YouTubeChannel(
      name: json['name'],
      id: json['id'],
      language: json['language'],
    );
  }

  String get channelUrl => 'https://www.youtube.com/channel/$id';
}

class YouTubeService {
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';
  static String get _apiKey => AppConstants.youtubeApiKey;

  static Future<Map<String, dynamic>> searchVideos({
    required String query,
    int maxResults = 10,
    String language = 'en',
    String duration = 'any',
    String order = 'relevance',
    bool useOnline = true,
  }) async {
    try {

      final searchQuery = '$query educational tutorial learning';

      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'part': 'snippet',
        'q': searchQuery,
        'type': 'video',
        'maxResults': maxResults.toString(),
        'order': order,
        'relevanceLanguage': language,
        'safeSearch': 'strict',
        'videoCategoryId': '27',
        'key': _apiKey,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List? ?? [];

        final videos = items
            .where((item) => item['id']?['videoId'] != null)
            .map((item) => YouTubeVideo.fromYouTubeApi(item))
            .toList();

        return {
          'success': true,
          'provider': 'online',
          'videos': videos,
          'result_count': videos.length,
        };
      } else {

        return _getOfflineRecommendations(query);
      }
    } catch (e) {
      print('YouTube API error: $e');

      return _getOfflineRecommendations(query);
    }
  }

  static Map<String, dynamic> _getOfflineRecommendations(String query) {
    final subject = _detectSubject(query);
    final channels = _getChannelsForSubject(subject);

    return {
      'success': true,
      'provider': 'offline',
      'channels': channels,
      'detected_subject': subject,
      'note':
          'Showing recommended educational channels. Connect to internet for video search.',
    };
  }

  static String _detectSubject(String query) {
    final q = query.toLowerCase();
    if (q.contains('math') ||
        q.contains('algebra') ||
        q.contains('geometry') ||
        q.contains('calculus')) {
      return 'Mathematics';
    } else if (q.contains('physics') ||
        q.contains('force') ||
        q.contains('energy') ||
        q.contains('motion')) {
      return 'Physics';
    } else if (q.contains('chemistry') ||
        q.contains('chemical') ||
        q.contains('element') ||
        q.contains('reaction')) {
      return 'Chemistry';
    } else if (q.contains('biology') ||
        q.contains('cell') ||
        q.contains('organism') ||
        q.contains('life')) {
      return 'Biology';
    } else if (q.contains('history') ||
        q.contains('war') ||
        q.contains('civilization') ||
        q.contains('empire')) {
      return 'History';
    } else if (q.contains('english') ||
        q.contains('grammar') ||
        q.contains('literature')) {
      return 'English';
    } else if (q.contains('science')) {
      return 'Science';
    }
    return 'General';
  }

  static List<YouTubeChannel> _getChannelsForSubject(String subject) {
    final channelMap = {
      'Mathematics': [
        YouTubeChannel(
            name: '3Blue1Brown',
            id: 'UCYO_jab_esuFRV4b17AJtAw',
            language: 'English'),
        YouTubeChannel(
            name: 'Khan Academy',
            id: 'UC4a-Gbdw7vOaccHmFo40b9g',
            language: 'English'),
        YouTubeChannel(
            name: 'Mathologer',
            id: 'UC1_uAIS3r8Vu6JjXWvastJg',
            language: 'English'),
      ],
      'Physics': [
        YouTubeChannel(
            name: 'Veritasium',
            id: 'UCHnyfMqiRRG1u-2MsSQLbXA',
            language: 'English'),
        YouTubeChannel(
            name: 'Physics Wallah',
            id: 'UCrC79Pu5C3w_gxRf30_XMQQ',
            language: 'Hindi'),
        YouTubeChannel(
            name: 'MinutePhysics',
            id: 'UCUHW94eEFW7hkUMVaZz4eDg',
            language: 'English'),
      ],
      'Chemistry': [
        YouTubeChannel(
            name: 'NileRed',
            id: 'UCFhXFikryT4aFcLkLw2LBLA',
            language: 'English'),
        YouTubeChannel(
            name: 'Periodic Videos',
            id: 'UCtESv1e7ntJaLJYKIO1FoYw',
            language: 'English'),
        YouTubeChannel(
            name: 'Chemistry Wallah',
            id: 'UCrC79Pu5C3w_gxRf30_XMQQ',
            language: 'Hindi'),
      ],
      'Biology': [
        YouTubeChannel(
            name: 'CrashCourse',
            id: 'UCX6b17PVsYBQ0ip5gyeme-Q',
            language: 'English'),
        YouTubeChannel(
            name: 'Amoeba Sisters',
            id: 'UCkckDgmFpBxTZAYp0Q8VHDw',
            language: 'English'),
        YouTubeChannel(
            name: 'Biology Wallah',
            id: 'UCrC79Pu5C3w_gxRf30_XMQQ',
            language: 'Hindi'),
      ],
      'Science': [
        YouTubeChannel(
            name: 'Kurzgesagt',
            id: 'UCsXVk37bltHxD1rDPwtNM8Q',
            language: 'English'),
        YouTubeChannel(
            name: 'SmarterEveryDay',
            id: 'UC6107grRI4m0o2-emgoDnAA',
            language: 'English'),
        YouTubeChannel(
            name: 'Vsauce',
            id: 'UC6nSFpj9HTCZ5t-N3Rm3-HA',
            language: 'English'),
      ],
      'History': [
        YouTubeChannel(
            name: 'OverSimplified',
            id: 'UCNIuvl7V8zACPpTmmNIqP2A',
            language: 'English'),
        YouTubeChannel(
            name: 'Extra Credits',
            id: 'UCCODtTcd5M1JavPCOr_Uydg',
            language: 'English'),
        YouTubeChannel(
            name: 'History Matters',
            id: 'UC22BdTgxefuvUivrjevzjOw',
            language: 'English'),
      ],
      'English': [
        YouTubeChannel(
            name: 'English with Lucy',
            id: 'UCz4tgANd4yy8Oe0iXCdSWfA',
            language: 'English'),
        YouTubeChannel(
            name: 'Learn English with TV Series',
            id: 'UCKgpamMlm872zkGDcBJHYDg',
            language: 'English'),
      ],
      'General': [
        YouTubeChannel(
            name: 'Khan Academy',
            id: 'UC4a-Gbdw7vOaccHmFo40b9g',
            language: 'English'),
        YouTubeChannel(
            name: 'TED-Ed',
            id: 'UCsooa4yRKGN_zEE8iknghZA',
            language: 'English'),
        YouTubeChannel(
            name: 'CrashCourse',
            id: 'UCX6b17PVsYBQ0ip5gyeme-Q',
            language: 'English'),
      ],
    };

    return channelMap[subject] ?? channelMap['General']!;
  }

  static Future<YouTubeVideo?> getVideoDetails(String videoId) async {
    try {
      final uri = Uri.parse('$_baseUrl/videos').replace(queryParameters: {
        'part': 'snippet,statistics,contentDetails',
        'id': videoId,
        'key': _apiKey,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List? ?? [];

        if (items.isNotEmpty) {
          final item = items.first;
          final snippet = item['snippet'] ?? {};
          final stats = item['statistics'] ?? {};
          final contentDetails = item['contentDetails'] ?? {};

          return YouTubeVideo(
            videoId: videoId,
            title: snippet['title'] ?? '',
            description: snippet['description'] ?? '',
            thumbnail: snippet['thumbnails']?['high']?['url'] ?? '',
            channelTitle: snippet['channelTitle'] ?? '',
            channelId: snippet['channelId'] ?? '',
            publishedAt: snippet['publishedAt'] ?? '',
            url: 'https://www.youtube.com/watch?v=$videoId',
            viewCount: int.tryParse(stats['viewCount']?.toString() ?? ''),
            likeCount: int.tryParse(stats['likeCount']?.toString() ?? ''),
            duration: contentDetails['duration'],
          );
        }
      }
      return null;
    } catch (e) {
      print('Error getting video details: $e');
      return null;
    }
  }

  static Future<List<YouTubeChannel>> getChannelRecommendations({
    String subject = 'General',
  }) async {
    return _getChannelsForSubject(subject);
  }

  static Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$_baseUrl/videos').replace(queryParameters: {
        'part': 'snippet',
        'chart': 'mostPopular',
        'maxResults': '1',
        'key': _apiKey,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('YouTube health check failed: $e');
      return false;
    }
  }

  static List<String> get subjects => [
        'General',
        'Science',
        'Mathematics',
        'English',
        'History',
        'Physics',
        'Chemistry',
        'Biology',
      ];
}
