"""
Text-to-Speech Service
Supports both Google Cloud TTS (online) and device TTS (offline)
"""

import os
import base64
from typing import Dict, Any, Optional, List
from enum import Enum

class TTSProvider(Enum):
    """TTS provider types"""
    GOOGLE_CLOUD = "google_cloud"
    DEVICE = "device"

class TTSService:
    """
    Text-to-Speech service with online/offline support
    - Online: Google Cloud TTS API
    - Offline: Device TTS (handled by client)
    """

    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize TTS service

        Args:
            api_key: Google Cloud API key (optional for offline mode)
        """
        self.api_key = api_key
        self.online_available = api_key is not None

        self.supported_languages = {
            'en': {'name': 'English', 'voices': ['en-US-Standard-A', 'en-US-Standard-B', 'en-IN-Standard-A']},
            'hi': {'name': 'Hindi', 'voices': ['hi-IN-Standard-A', 'hi-IN-Standard-B']},
            'pa': {'name': 'Punjabi', 'voices': ['pa-IN-Standard-A']},
            'ta': {'name': 'Tamil', 'voices': ['ta-IN-Standard-A']},
            'te': {'name': 'Telugu', 'voices': ['te-IN-Standard-A']},
            'bn': {'name': 'Bengali', 'voices': ['bn-IN-Standard-A']},
            'mr': {'name': 'Marathi', 'voices': ['mr-IN-Standard-A']},
            'gu': {'name': 'Gujarati', 'voices': ['gu-IN-Standard-A']}
        }

    def synthesize(
        self,
        text: str,
        language: str = 'en',
        voice: Optional[str] = None,
        speed: float = 1.0,
        pitch: float = 0.0,
        use_online: bool = True
    ) -> Dict[str, Any]:
        """
        Convert text to speech

        Args:
            text: Text to synthesize
            language: Language code (en, hi, pa, etc.)
            voice: Specific voice name (optional)
            speed: Speech rate (0.25 to 4.0)
            pitch: Voice pitch (-20.0 to 20.0)
            use_online: Use Google Cloud TTS if available

        Returns:
            Dictionary with audio data or instructions
        """
        if not text or not text.strip():
            return {
                'success': False,
                'error': 'Empty text provided'
            }

        if language not in self.supported_languages:
            return {
                'success': False,
                'error': f'Unsupported language: {language}',
                'supported_languages': list(self.supported_languages.keys())
            }

        if use_online and self.online_available:
            return self._synthesize_google_cloud(text, language, voice, speed, pitch)

        return self._synthesize_device(text, language, speed, pitch)

    def _synthesize_google_cloud(
        self,
        text: str,
        language: str,
        voice: Optional[str],
        speed: float,
        pitch: float
    ) -> Dict[str, Any]:
        """
        Synthesize using Google Cloud TTS API

        Args:
            text: Text to synthesize
            language: Language code
            voice: Voice name
            speed: Speech rate
            pitch: Voice pitch

        Returns:
            Dictionary with audio data
        """
        try:

            import requests

            if not voice:
                voice = self.supported_languages[language]['voices'][0]

            url = f"https://texttospeech.googleapis.com/v1/text:synthesize?key={self.api_key}"

            payload = {
                "input": {"text": text},
                "voice": {
                    "languageCode": language if '-' not in language else language.split('-')[0] + '-' + language.split('-')[1].upper(),
                    "name": voice
                },
                "audioConfig": {
                    "audioEncoding": "MP3",
                    "speakingRate": speed,
                    "pitch": pitch
                }
            }

            response = requests.post(url, json=payload, timeout=10)

            if response.status_code == 200:
                result = response.json()
                audio_content = result.get('audioContent')

                return {
                    'success': True,
                    'provider': 'google_cloud',
                    'audio_base64': audio_content,
                    'format': 'mp3',
                    'language': language,
                    'voice': voice,
                    'text_length': len(text)
                }
            else:
                error_msg = response.json().get('error', {}).get('message', 'Unknown error')
                return {
                    'success': False,
                    'error': f'Google Cloud TTS error: {error_msg}',
                    'fallback_to_device': True
                }

        except ImportError:
            return {
                'success': False,
                'error': 'requests library not installed',
                'fallback_to_device': True
            }
        except Exception as e:
            return {
                'success': False,
                'error': f'TTS synthesis failed: {str(e)}',
                'fallback_to_device': True
            }

    def _synthesize_device(
        self,
        text: str,
        language: str,
        speed: float,
        pitch: float
    ) -> Dict[str, Any]:
        """
        Return instructions for device TTS

        Args:
            text: Text to synthesize
            language: Language code
            speed: Speech rate
            pitch: Voice pitch

        Returns:
            Dictionary with device TTS instructions
        """
        return {
            'success': True,
            'provider': 'device',
            'instruction': 'use_device_tts',
            'text': text,
            'language': language,
            'speed': speed,
            'pitch': pitch,
            'note': 'Client should use device TTS engine (flutter_tts or platform TTS)'
        }

    def get_voices(self, language: Optional[str] = None) -> List[Dict[str, Any]]:
        """
        Get available voices

        Args:
            language: Optional language filter

        Returns:
            List of available voices
        """
        if language:
            if language not in self.supported_languages:
                return []

            lang_info = self.supported_languages[language]
            return [
                {
                    'language': language,
                    'language_name': lang_info['name'],
                    'voice': voice,
                    'provider': 'google_cloud' if self.online_available else 'device'
                }
                for voice in lang_info['voices']
            ]

        voices = []
        for lang_code, lang_info in self.supported_languages.items():
            for voice in lang_info['voices']:
                voices.append({
                    'language': lang_code,
                    'language_name': lang_info['name'],
                    'voice': voice,
                    'provider': 'google_cloud' if self.online_available else 'device'
                })

        return voices

    def health_check(self) -> Dict[str, str]:
        """Check TTS service health"""
        return {
            'tts_service': 'healthy',
            'google_cloud_tts': 'available' if self.online_available else 'unavailable',
            'device_tts': 'available',
            'supported_languages': len(self.supported_languages)
        }

_tts_service = None

def get_tts_service(api_key: Optional[str] = None) -> TTSService:
    """Get singleton TTS service instance"""
    global _tts_service
    if _tts_service is None:
        _tts_service = TTSService(api_key)
    return _tts_service
