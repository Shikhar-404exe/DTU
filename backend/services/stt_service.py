"""
Speech-to-Text Service
Supports both Google Cloud STT (online) and device STT (offline)
"""

import os
import base64
from typing import Dict, Any, Optional, List
from enum import Enum

class STTProvider(Enum):
    """STT provider types"""
    GOOGLE_CLOUD = "google_cloud"
    DEVICE = "device"

class STTService:
    """
    Speech-to-Text service with online/offline support
    - Online: Google Cloud Speech-to-Text API
    - Offline: Device STT (handled by client)
    """

    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize STT service

        Args:
            api_key: Google Cloud API key (optional for offline mode)
        """
        self.api_key = api_key
        self.online_available = api_key is not None

        self.supported_languages = {
            'en-US': 'English (US)',
            'en-IN': 'English (India)',
            'hi-IN': 'Hindi',
            'pa-IN': 'Punjabi',
            'ta-IN': 'Tamil',
            'te-IN': 'Telugu',
            'bn-IN': 'Bengali',
            'mr-IN': 'Marathi',
            'gu-IN': 'Gujarati'
        }

    def recognize(
        self,
        audio_base64: str,
        language: str = 'en-IN',
        encoding: str = 'LINEAR16',
        sample_rate: int = 16000,
        use_online: bool = True
    ) -> Dict[str, Any]:
        """
        Convert speech to text

        Args:
            audio_base64: Base64-encoded audio data
            language: Language code (en-IN, hi-IN, etc.)
            encoding: Audio encoding (LINEAR16, MP3, OGG_OPUS)
            sample_rate: Sample rate in Hz
            use_online: Use Google Cloud STT if available

        Returns:
            Dictionary with transcription or instructions
        """
        if not audio_base64:
            return {
                'success': False,
                'error': 'No audio data provided'
            }

        if language not in self.supported_languages:
            return {
                'success': False,
                'error': f'Unsupported language: {language}',
                'supported_languages': list(self.supported_languages.keys())
            }

        if use_online and self.online_available:
            return self._recognize_google_cloud(
                audio_base64,
                language,
                encoding,
                sample_rate
            )

        return self._recognize_device(language)

    def _recognize_google_cloud(
        self,
        audio_base64: str,
        language: str,
        encoding: str,
        sample_rate: int
    ) -> Dict[str, Any]:
        """
        Recognize using Google Cloud Speech-to-Text API

        Args:
            audio_base64: Base64-encoded audio data
            language: Language code
            encoding: Audio encoding
            sample_rate: Sample rate

        Returns:
            Dictionary with transcription
        """
        try:

            import requests

            url = f"https://speech.googleapis.com/v1/speech:recognize?key={self.api_key}"

            encoding_map = {
                'LINEAR16': 'LINEAR16',
                'MP3': 'MP3',
                'OGG_OPUS': 'OGG_OPUS',
                'FLAC': 'FLAC',
                'WEBM_OPUS': 'WEBM_OPUS'
            }

            api_encoding = encoding_map.get(encoding.upper(), 'LINEAR16')

            payload = {
                "config": {
                    "encoding": api_encoding,
                    "sampleRateHertz": sample_rate,
                    "languageCode": language,
                    "enableAutomaticPunctuation": True,
                    "model": "default"
                },
                "audio": {
                    "content": audio_base64
                }
            }

            response = requests.post(url, json=payload, timeout=30)

            if response.status_code == 200:
                result = response.json()

                if 'results' in result and len(result['results']) > 0:
                    transcript = result['results'][0]['alternatives'][0]['transcript']
                    confidence = result['results'][0]['alternatives'][0].get('confidence', 0.0)

                    return {
                        'success': True,
                        'provider': 'google_cloud',
                        'transcript': transcript,
                        'confidence': confidence,
                        'language': language
                    }
                else:
                    return {
                        'success': False,
                        'error': 'No transcription results',
                        'fallback_to_device': True
                    }
            else:
                error_msg = response.json().get('error', {}).get('message', 'Unknown error')
                return {
                    'success': False,
                    'error': f'Google Cloud STT error: {error_msg}',
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
                'error': f'STT recognition failed: {str(e)}',
                'fallback_to_device': True
            }

    def _recognize_device(self, language: str) -> Dict[str, Any]:
        """
        Return instructions for device STT

        Args:
            language: Language code

        Returns:
            Dictionary with device STT instructions
        """
        return {
            'success': True,
            'provider': 'device',
            'instruction': 'use_device_stt',
            'language': language,
            'note': 'Client should use device STT engine (speech_to_text or platform STT)'
        }

    def get_supported_languages(self) -> List[Dict[str, str]]:
        """Get list of supported languages"""
        return [
            {'code': code, 'name': name}
            for code, name in self.supported_languages.items()
        ]

    def health_check(self) -> Dict[str, str]:
        """Check STT service health"""
        return {
            'stt_service': 'healthy',
            'google_cloud_stt': 'available' if self.online_available else 'unavailable',
            'device_stt': 'available',
            'supported_languages': len(self.supported_languages)
        }

_stt_service = None

def get_stt_service(api_key: Optional[str] = None) -> STTService:
    """Get singleton STT service instance"""
    global _stt_service
    if _stt_service is None:
        _stt_service = STTService(api_key)
    return _stt_service
