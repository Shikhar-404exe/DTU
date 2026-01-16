

library;

import 'package:flutter/material.dart';
import '../services/youtube_service.dart';
import 'package:url_launcher/url_launcher.dart';

class YouTubeBrowserScreen extends StatefulWidget {
  const YouTubeBrowserScreen({super.key});

  @override
  State<YouTubeBrowserScreen> createState() => _YouTubeBrowserScreenState();
}

class _YouTubeBrowserScreenState extends State<YouTubeBrowserScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<YouTubeVideo> _videos = [];
  List<YouTubeChannel> _channels = [];
  bool _isLoading = false;
  bool _isOfflineMode = false;
  String _selectedSubject = 'General';
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadChannelRecommendations();
  }

  Future<void> _loadChannelRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    final channels = await YouTubeService.getChannelRecommendations(
      subject: _selectedSubject,
    );

    setState(() {
      _channels = channels;
      _isLoading = false;
    });
  }

  Future<void> _searchVideos() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _videos.clear();
      _channels.clear();
    });

    final result = await YouTubeService.searchVideos(
      query: query,
      maxResults: 20,
      language: _selectedLanguage,
      useOnline: true,
    );

    setState(() {
      _isLoading = false;

      if (result['success']) {
        if (result['provider'] == 'online' && result['videos'] != null) {
          _videos = result['videos'];
          _isOfflineMode = false;
        } else if (result['provider'] == 'offline' &&
            result['channels'] != null) {
          _channels = result['channels'];
          _isOfflineMode = true;
        }
      } else {
        _showError('Failed to search: ${result['error']}');
      }
    });
  }

  Future<void> _openVideo(String videoId) async {
    final url = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showError('Could not open video');
    }
  }

  Future<void> _openChannel(String channelId) async {
    final url = Uri.parse('https://www.youtube.com/channel/$channelId');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showError('Could not open channel');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Educational Videos'),
        actions: [

          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (lang) {
              setState(() {
                _selectedLanguage = lang;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'en', child: Text('English')),
              const PopupMenuItem(value: 'hi', child: Text('Hindi')),
              const PopupMenuItem(value: 'pa', child: Text('Punjabi')),
            ],
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.subject),
            onSelected: (subject) {
              setState(() {
                _selectedSubject = subject;
              });
              _loadChannelRecommendations();
            },
            itemBuilder: (context) => YouTubeService.subjects
                .map((s) => PopupMenuItem(value: s, child: Text(s)))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for videos...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _searchVideos(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchVideos,
                ),
              ],
            ),
          ),

          if (_isOfflineMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange[100],
              child: Row(
                children: [
                  Icon(Icons.cloud_off, color: Colors.orange[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline mode: Showing recommended channels',
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _videos.isNotEmpty
                    ? _buildVideoList()
                    : _channels.isNotEmpty
                        ? _buildChannelList()
                        : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => _openVideo(video.videoId),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    video.thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.video_library, size: 64),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        video.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(Icons.account_circle, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            video.channelTitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                      if (video.viewCount != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${_formatNumber(video.viewCount!)} views',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChannelList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _channels.length,
      itemBuilder: (context, index) {
        final channel = _channels[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.video_library),
            ),
            title: Text(
              channel.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Language: ${channel.language}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _openChannel(channel.id),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Search for educational videos',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'or browse recommended channels',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
