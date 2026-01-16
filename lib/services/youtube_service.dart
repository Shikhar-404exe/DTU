/// YouTube Service
/// Handles educational video search and recommendations

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

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
      videoId: json['video_id'],
      title: json['title'],
      description: json['description'] ?? '',
      thumbnail: json['thumbnail'],
      channelTitle: json['channel_title'],
      channelId: json['channel_id'],
      publishedAt: json['published_at'],
      url: json['url'],
      viewCount: json['view_count'],
      likeCount: json['like_count'],
      duration: json['duration'],
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
  static Future<Map<String, dynamic>> searchVideos({
    required String query,
    int maxResults = 10,
    String language = 'en',
    String duration = 'any',
    String order = 'relevance',
    bool useOnline = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiConfig.youtubeSearch}'),
            headers: ApiConfig.headers,
            body: jsonEncode({
              'query': query,
              'max_results': maxResults,
              'language': language,
              'duration': duration,
              'order': order,
              'use_online': useOnline,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success']) {
          // Online results with videos
          if (data['provider'] == 'youtube_api' && data['videos'] != null) {
            final videos = (data['videos'] as List)
                .map((v) => YouTubeVideo.fromJson(v))
                .toList();

            return {
              'success': true,
              'provider': 'online',
              'videos': videos,
              'result_count': videos.length,
            };
          }

          // Offline results with channel recommendations
          if (data['provider'] == 'offline' &&
              data['recommended_channels'] != null) {
            final channels = (data['recommended_channels'] as List)
                .map((c) => YouTubeChannel.fromJson(c))
                .toList();

            return {
              'success': true,
              'provider': 'offline',
              'channels': channels,
              'detected_subject': data['detected_subject'],
              'note': data['note'],
            };
          }
        }

        return {'success': false, 'error': data['error'] ?? 'Unknown error'};
      } else {
        return {'success': false, 'error': 'API request failed'};
      }
    } catch (e) {
      print('Error searching videos: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<YouTubeVideo?> getVideoDetails(String videoId) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '${ApiConfig.currentBaseUrl}${ApiConfig.youtubeVideo(videoId)}'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success']) {
          return YouTubeVideo.fromJson(data);
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
    try {
      final response = await http
          .get(
            Uri.parse(
                '${ApiConfig.currentBaseUrl}${ApiConfig.youtubeChannels(subject)}'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success']) {
          return (data['channels'] as List)
              .map((c) => YouTubeChannel.fromJson(c))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting channels: $e');
      return [];
    }
  }

  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.currentBaseUrl}${ApiConfig.youtubeHealth}'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.timeout);

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
