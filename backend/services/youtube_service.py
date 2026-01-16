"""
YouTube Data API Service
Provides video search and recommendations for educational content
"""

import os
from typing import Dict, Any, Optional, List
from datetime import datetime, timedelta

class YouTubeService:
    """
    YouTube Data API v3 service for content discovery
    - Search videos by topic/subject
    - Get video details
    - Filter educational content
    - Curated channel recommendations (offline fallback)
    """

    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize YouTube service

        Args:
            api_key: YouTube Data API v3 key (optional for offline mode)
        """
        self.api_key = api_key
        self.online_available = api_key is not None

        self.educational_channels = {
            'Science': [
                {'name': 'Khan Academy', 'id': 'UC4a-Gbdw7vOaccHmFo40b9g', 'language': 'en'},
                {'name': 'Crash Course', 'id': 'UCX6b17PVsYBQ0ip5gyeme-Q', 'language': 'en'},
                {'name': 'Veritasium', 'id': 'UCHnyfMqiRRG1u-2MsSQLbXA', 'language': 'en'},
                {'name': 'Physics Wallah', 'id': 'UCeVMnSShP_Iviwkknt83cww', 'language': 'hi'},
            ],
            'Mathematics': [
                {'name': 'Khan Academy', 'id': 'UC4a-Gbdw7vOaccHmFo40b9g', 'language': 'en'},
                {'name': '3Blue1Brown', 'id': 'UCYO_jab_esuFRV4b17AJtAw', 'language': 'en'},
                {'name': 'Vedantu', 'id': 'UCHEg7jlYU-BFC8n_XKgHqbQ', 'language': 'hi'},
            ],
            'English': [
                {'name': 'EngVid', 'id': 'UCpvuCyYG3-', 'language': 'en'},
                {'name': 'BBC Learning English', 'id': 'UCHaHD477h-FeBbVh9Sh7syA', 'language': 'en'},
            ],
            'History': [
                {'name': 'Crash Course', 'id': 'UCX6b17PVsYBQ0ip5gyeme-Q', 'language': 'en'},
                {'name': 'Oversimplified', 'id': 'UCNIuvl7V8zACPpTmmNIqP2A', 'language': 'en'},
            ],
            'General': [
                {'name': 'Khan Academy', 'id': 'UC4a-Gbdw7vOaccHmFo40b9g', 'language': 'en'},
                {'name': 'CrashCourse', 'id': 'UCX6b17PVsYBQ0ip5gyeme-Q', 'language': 'en'},
                {'name': 'Unacademy', 'id': 'UCABe2FgVNv2hgBeMu2mySVg', 'language': 'hi'},
                {'name': "Byju's", 'id': 'UCF2JsMDcfUPcvMkTmx_BzfQ', 'language': 'hi'},
            ]
        }

    def search_videos(
        self,
        query: str,
        max_results: int = 10,
        language: str = 'en',
        duration: str = 'any',
        order: str = 'relevance',
        use_online: bool = True
    ) -> Dict[str, Any]:
        """
        Search for educational videos

        Args:
            query: Search query
            max_results: Maximum results to return
            language: Preferred language (en, hi, etc.)
            duration: Video duration filter (short/medium/long/any)
            order: Sort order (relevance/date/rating/viewCount)
            use_online: Use YouTube API if available

        Returns:
            Dictionary with video results
        """
        if not query or not query.strip():
            return {
                'success': False,
                'error': 'Empty search query'
            }

        if use_online and self.online_available:
            return self._search_youtube_api(query, max_results, language, duration, order)

        return self._search_offline(query, max_results)

    def _search_youtube_api(
        self,
        query: str,
        max_results: int,
        language: str,
        duration: str,
        order: str
    ) -> Dict[str, Any]:
        """
        Search using YouTube Data API

        Args:
            query: Search query
            max_results: Maximum results
            language: Language preference
            duration: Duration filter
            order: Sort order

        Returns:
            Dictionary with video results
        """
        try:

            import requests

            url = "https://www.googleapis.com/youtube/v3/search"

            duration_map = {
                'short': 'short',
                'medium': 'medium',
                'long': 'long',
                'any': None
            }

            params = {
                'key': self.api_key,
                'part': 'snippet',
                'q': f"{query} tutorial educational",
                'type': 'video',
                'maxResults': max_results,
                'order': order,
                'relevanceLanguage': language,
                'videoDefinition': 'any',
                'videoEmbeddable': 'true',
                'safeSearch': 'strict'
            }

            if duration != 'any' and duration in duration_map:
                params['videoDuration'] = duration_map[duration]

            response = requests.get(url, params=params, timeout=10)

            if response.status_code == 200:
                result = response.json()

                videos = []
                for item in result.get('items', []):
                    snippet = item.get('snippet', {})
                    video_id = item.get('id', {}).get('videoId')

                    if video_id:
                        videos.append({
                            'video_id': video_id,
                            'title': snippet.get('title', ''),
                            'description': snippet.get('description', ''),
                            'thumbnail': snippet.get('thumbnails', {}).get('medium', {}).get('url', ''),
                            'channel_title': snippet.get('channelTitle', ''),
                            'channel_id': snippet.get('channelId', ''),
                            'published_at': snippet.get('publishedAt', ''),
                            'url': f"https://www.youtube.com/watch?v={video_id}"
                        })

                return {
                    'success': True,
                    'provider': 'youtube_api',
                    'query': query,
                    'result_count': len(videos),
                    'videos': videos
                }
            else:
                error_msg = response.json().get('error', {}).get('message', 'Unknown error')
                return {
                    'success': False,
                    'error': f'YouTube API error: {error_msg}',
                    'fallback_to_offline': True
                }

        except ImportError:
            return {
                'success': False,
                'error': 'requests library not installed',
                'fallback_to_offline': True
            }
        except Exception as e:
            return {
                'success': False,
                'error': f'YouTube search failed: {str(e)}',
                'fallback_to_offline': True
            }

    def _search_offline(self, query: str, max_results: int) -> Dict[str, Any]:
        """
        Provide offline recommendations based on query

        Args:
            query: Search query
            max_results: Maximum results

        Returns:
            Dictionary with channel recommendations
        """

        subject = self._detect_subject(query)

        channels = self.educational_channels.get(subject, self.educational_channels['General'])

        return {
            'success': True,
            'provider': 'offline',
            'query': query,
            'detected_subject': subject,
            'recommended_channels': channels[:max_results],
            'note': 'Offline mode: Showing curated educational channels. Use online mode for specific video search.'
        }

    def _detect_subject(self, query: str) -> str:
        """Detect subject from query"""
        query_lower = query.lower()

        subject_keywords = {
            'Science': ['science', 'physics', 'chemistry', 'biology', 'photosynthesis', 'experiment'],
            'Mathematics': ['math', 'mathematics', 'algebra', 'geometry', 'calculus', 'equation'],
            'English': ['english', 'grammar', 'vocabulary', 'writing', 'literature'],
            'History': ['history', 'historical', 'ancient', 'medieval', 'war', 'civilization']
        }

        for subject, keywords in subject_keywords.items():
            if any(keyword in query_lower for keyword in keywords):
                return subject

        return 'General'

    def get_video_details(self, video_id: str) -> Dict[str, Any]:
        """
        Get detailed information about a video

        Args:
            video_id: YouTube video ID

        Returns:
            Dictionary with video details
        """
        if not self.online_available:
            return {
                'success': False,
                'error': 'YouTube API not available (offline mode)',
                'video_id': video_id
            }

        try:
            import requests

            url = "https://www.googleapis.com/youtube/v3/videos"
            params = {
                'key': self.api_key,
                'part': 'snippet,contentDetails,statistics',
                'id': video_id
            }

            response = requests.get(url, params=params, timeout=10)

            if response.status_code == 200:
                result = response.json()

                if result.get('items'):
                    item = result['items'][0]
                    snippet = item.get('snippet', {})
                    stats = item.get('statistics', {})
                    details = item.get('contentDetails', {})

                    return {
                        'success': True,
                        'video_id': video_id,
                        'title': snippet.get('title', ''),
                        'description': snippet.get('description', ''),
                        'channel_title': snippet.get('channelTitle', ''),
                        'published_at': snippet.get('publishedAt', ''),
                        'duration': details.get('duration', ''),
                        'view_count': stats.get('viewCount', 0),
                        'like_count': stats.get('likeCount', 0),
                        'comment_count': stats.get('commentCount', 0),
                        'thumbnail': snippet.get('thumbnails', {}).get('high', {}).get('url', ''),
                        'url': f"https://www.youtube.com/watch?v={video_id}"
                    }
                else:
                    return {
                        'success': False,
                        'error': 'Video not found'
                    }
            else:
                return {
                    'success': False,
                    'error': 'Failed to fetch video details'
                }

        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }

    def get_channel_recommendations(self, subject: str = 'General') -> List[Dict[str, str]]:
        """
        Get curated channel recommendations

        Args:
            subject: Subject area

        Returns:
            List of recommended channels
        """
        return self.educational_channels.get(subject, self.educational_channels['General'])

    def health_check(self) -> Dict[str, str]:
        """Check YouTube service health"""
        return {
            'youtube_service': 'healthy',
            'youtube_api': 'available' if self.online_available else 'unavailable',
            'offline_channels': len([ch for channels in self.educational_channels.values() for ch in channels])
        }

_youtube_service = None

def get_youtube_service(api_key: Optional[str] = None) -> YouTubeService:
    """Get singleton YouTube service instance"""
    global _youtube_service
    if _youtube_service is None:
        _youtube_service = YouTubeService(api_key)
    return _youtube_service
