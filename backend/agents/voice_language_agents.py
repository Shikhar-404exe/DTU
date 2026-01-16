"""
Voice Interface Agent - Agent #3
Handles voice input/output with TTS and STT
Provides voice-first accessibility for low-literacy users
"""

from typing import Dict, List, Optional
from .base_agent import (
    BaseAgent, AgentMode, AgentCapability, AgentPriority
)

class VoiceInterfaceAgent(BaseAgent):
    """
    Voice interface agent for speech-to-text and text-to-speech
    Offline: Uses on-device TTS (where available)
    Online: Uses Google Cloud TTS/STT APIs for better quality
    """

    def __init__(self, google_cloud_key: str = None):
        super().__init__(
            agent_id="voice_interface",
            name="Voice Interface Agent",
            description="Handles voice input and output for accessibility and low-literacy users",
            capabilities=[
                AgentCapability.VOICE_PROCESSING,
                AgentCapability.TEXT_PROCESSING,
                AgentCapability.ACCESSIBILITY
            ],
            priority=AgentPriority.HIGH,
            default_mode=AgentMode.AUTO
        )

        self.google_cloud_key = google_cloud_key

        self.supported_languages = {
            'en': {'name': 'English', 'code': 'en-IN', 'available_offline': True},
            'hi': {'name': 'Hindi', 'code': 'hi-IN', 'available_offline': True},
            'pa': {'name': 'Punjabi', 'code': 'pa-IN', 'available_offline': False}
        }

    def can_handle(self, query: str, context: Dict = None) -> float:
        """Determine if this agent should handle the request"""
        context = context or {}

        if context.get('voice_input') or context.get('requires_voice_output'):
            return 1.0

        query_lower = query.lower()
        voice_keywords = ['speak', 'listen', 'voice', 'audio', 'say', 'hear', 'read aloud']

        if any(kw in query_lower for kw in voice_keywords):
            return 0.9

        return 0.0

    def process_offline(self, query: str, context: Dict = None) -> Dict:
        """
        Process voice operations in offline mode
        Uses device TTS capabilities
        """
        context = context or {}
        operation = context.get('operation', 'tts')
        language = context.get('language', 'en')

        if operation == 'tts':
            return self._text_to_speech_offline(query, language, context)
        elif operation == 'stt':
            return self._speech_to_text_offline(query, language, context)
        else:
            return {
                'success': False,
                'error': f'Unknown operation: {operation}'
            }

    def process_online(self, query: str, context: Dict = None) -> Dict:
        """
        Process voice operations in online mode
        Uses Google Cloud TTS/STT APIs
        """
        context = context or {}
        operation = context.get('operation', 'tts')
        language = context.get('language', 'en')

        if operation == 'tts':
            return self._text_to_speech_online(query, language, context)
        elif operation == 'stt':
            return self._speech_to_text_online(query, language, context)
        else:
            return {
                'success': False,
                'error': f'Unknown operation: {operation}'
            }

    def _text_to_speech_offline(self, text: str, language: str, context: Dict) -> Dict:
        """
        Generate audio from text using device TTS
        In real implementation, this would use native mobile TTS
        """
        if language not in self.supported_languages:
            return {
                'success': False,
                'error': f'Language {language} not supported offline',
                'supported_languages': list(self.supported_languages.keys())
            }

        lang_info = self.supported_languages[language]

        if not lang_info['available_offline']:
            return {
                'success': False,
                'error': f'{lang_info["name"]} TTS requires internet connection',
                'suggestion': 'Connect to internet or switch to English/Hindi'
            }

        return {
            'success': True,
            'operation': 'tts',
            'mode': 'offline',
            'text': text,
            'language': language,
            'language_code': lang_info['code'],
            'audio_format': 'device_native',
            'instruction': 'use_device_tts',
            'settings': {
                'speed': context.get('speech_rate', 1.0),
                'pitch': context.get('pitch', 1.0),
                'volume': context.get('volume', 1.0)
            }
        }

    def _text_to_speech_online(self, text: str, language: str, context: Dict) -> Dict:
        """
        Generate audio from text using Google Cloud TTS
        Higher quality than device TTS
        """
        if language not in self.supported_languages:
            return {
                'success': False,
                'error': f'Language {language} not supported',
                'supported_languages': list(self.supported_languages.keys())
            }

        lang_info = self.supported_languages[language]

        return {
            'success': True,
            'operation': 'tts',
            'mode': 'online',
            'text': text,
            'language': language,
            'language_code': lang_info['code'],
            'audio_format': 'mp3',
            'instruction': 'use_google_tts',
            'api_endpoint': 'https://texttospeech.googleapis.com/v1/text:synthesize',
            'settings': {
                'speed': context.get('speech_rate', 1.0),
                'pitch': context.get('pitch', 0),
                'voice_type': context.get('voice_type', 'neutral'),
                'gender': context.get('gender', 'female')
            },
            'quality': 'high',
            'note': 'Using Google Cloud TTS for better quality'
        }

    def _speech_to_text_offline(self, audio_data: str, language: str, context: Dict) -> Dict:
        """
        Convert speech to text using device STT
        Limited accuracy, but works offline
        """
        lang_info = self.supported_languages.get(language, self.supported_languages['en'])

        return {
            'success': True,
            'operation': 'stt',
            'mode': 'offline',
            'language': language,
            'language_code': lang_info['code'],
            'instruction': 'use_device_stt',
            'settings': {
                'continuous': context.get('continuous', False),
                'interim_results': context.get('interim_results', True),
                'max_alternatives': 1
            },
            'note': 'Device STT may have limited accuracy. Connect to internet for better results.'
        }

    def _speech_to_text_online(self, audio_data: str, language: str, context: Dict) -> Dict:
        """
        Convert speech to text using Google Cloud STT
        Better accuracy and language support
        """
        lang_info = self.supported_languages.get(language, self.supported_languages['en'])

        return {
            'success': True,
            'operation': 'stt',
            'mode': 'online',
            'language': language,
            'language_code': lang_info['code'],
            'instruction': 'use_google_stt',
            'api_endpoint': 'https://speech.googleapis.com/v1/speech:recognize',
            'settings': {
                'continuous': context.get('continuous', False),
                'interim_results': context.get('interim_results', True),
                'max_alternatives': 3,
                'profanity_filter': True,
                'enable_word_time_offsets': False,
                'enable_automatic_punctuation': True
            },
            'quality': 'high',
            'note': 'Using Google Cloud STT for accurate recognition'
        }

    def get_supported_languages(self) -> Dict:
        """Get list of supported languages with offline availability"""
        return {
            'languages': self.supported_languages,
            'recommendation': 'Hindi and English work best offline'
        }

    def configure_voice_settings(self, settings: Dict) -> Dict:
        """Configure voice settings for user preference"""
        valid_settings = {}

        if 'speech_rate' in settings:
            rate = max(0.5, min(2.0, settings['speech_rate']))
            valid_settings['speech_rate'] = rate

        if 'pitch' in settings:
            valid_settings['pitch'] = settings['pitch']

        if 'volume' in settings:
            volume = max(0.0, min(1.0, settings['volume']))
            valid_settings['volume'] = volume

        if 'gender' in settings:
            if settings['gender'] in ['male', 'female', 'neutral']:
                valid_settings['gender'] = settings['gender']

        return {
            'success': True,
            'settings': valid_settings,
            'message': 'Voice settings updated'
        }

class LanguageSupportAgent(BaseAgent):
    """
    Agent #4 - Language Support Agent
    Handles translation and local language support
    """

    def __init__(self):
        super().__init__(
            agent_id="language_support",
            name="Language Support Agent",
            description="Provides translation and multi-language support for rural users",
            capabilities=[
                AgentCapability.TRANSLATION,
                AgentCapability.TEXT_PROCESSING
            ],
            priority=AgentPriority.HIGH,
            default_mode=AgentMode.AUTO
        )

        self.languages = {
            'en': 'English',
            'hi': 'Hindi',
            'pa': 'Punjabi'
        }

        self.ui_translations = {
            'hi': {
                'home': 'होम',
                'notes': 'नोट्स',
                'timetable': 'समय सारणी',
                'profile': 'प्रोफ़ाइल',
                'settings': 'सेटिंग्स',
                'help': 'मदद',
                'scan': 'स्कैन करें',
                'share': 'शेयर करें',
                'save': 'सहेजें',
                'cancel': 'रद्द करें'
            },
            'pa': {
                'home': 'ਘਰ',
                'notes': 'ਨੋਟਸ',
                'timetable': 'ਸਮਾਂ ਸਾਰਣੀ',
                'profile': 'ਪ੍ਰੋਫਾਈਲ',
                'settings': 'ਸੈਟਿੰਗਜ਼',
                'help': 'ਮਦਦ',
                'scan': 'ਸਕੈਨ',
                'share': 'ਸਾਂਝਾ',
                'save': 'ਸੰਭਾਲੋ',
                'cancel': 'ਰੱਦ'
            }
        }

    def can_handle(self, query: str, context: Dict = None) -> float:
        """Determine if this agent should handle the request"""
        context = context or {}

        if context.get('requires_translation'):
            return 1.0

        query_lower = query.lower()
        translation_keywords = [
            'translate', 'meaning in', 'hindi me', 'punjabi me',
            'क्या मतलब', 'किसे कहते हैं', 'ਕੀ ਹੈ'
        ]

        if any(kw in query_lower for kw in translation_keywords):
            return 0.95

        return 0.0

    def process_offline(self, query: str, context: Dict = None) -> Dict:
        """Process translation using offline dictionary"""
        context = context or {}
        source_lang = context.get('source_language', 'en')
        target_lang = context.get('target_language', 'hi')

        if context.get('ui_element'):
            return self._translate_ui_element(query, target_lang)

        return {
            'success': False,
            'message': 'Full translation requires internet connection',
            'source_text': query,
            'source_language': source_lang,
            'target_language': target_lang,
            'suggestion': 'Connect to internet for complete translation',
            'available_offline': 'Only UI elements can be translated offline'
        }

    def process_online(self, query: str, context: Dict = None) -> Dict:
        """Process translation using online API"""
        context = context or {}
        source_lang = context.get('source_language', 'en')
        target_lang = context.get('target_language', 'hi')

        return {
            'success': True,
            'source_text': query,
            'source_language': source_lang,
            'target_language': target_lang,
            'translated_text': f'[Translation of: {query}]',
            'mode': 'online',
            'instruction': 'use_google_translate',
            'api_endpoint': 'https://translation.googleapis.com/language/translate/v2'
        }

    def _translate_ui_element(self, text: str, target_lang: str) -> Dict:
        """Translate UI elements using offline dictionary"""
        text_lower = text.lower().strip()

        if target_lang in self.ui_translations:
            translations = self.ui_translations[target_lang]

            if text_lower in translations:
                return {
                    'success': True,
                    'original': text,
                    'translated': translations[text_lower],
                    'language': target_lang,
                    'mode': 'offline'
                }

        return {
            'success': False,
            'error': f'UI element "{text}" not found in offline dictionary',
            'available_elements': list(self.ui_translations.get(target_lang, {}).keys())
        }

    def get_ui_translations(self, language: str) -> Dict:
        """Get all UI translations for a language"""
        if language not in self.ui_translations:
            return {
                'success': False,
                'error': f'Language {language} not supported',
                'supported': list(self.ui_translations.keys())
            }

        return {
            'success': True,
            'language': language,
            'translations': self.ui_translations[language]
        }
