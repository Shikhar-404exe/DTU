"""
Dual-Mode Chatbot Implementation
Supports offline (KB-based) and online (AI-powered) modes
"""

import os
from typing import Dict, Any, List, Optional, AsyncIterator
from enum import Enum
from datetime import datetime

from agents import get_orchestrator, AgentMode
from tools import get_knowledge_base
from chatbot.conversation_manager import (
    get_conversation_manager,
    MessageRole,
    ConversationManager
)

class ChatMode(Enum):
    """Chat operation mode"""
    OFFLINE = "offline"
    ONLINE = "online"
    AUTO = "auto"

class DualModeChatbot:
    """
    Dual-mode chatbot with conversation management
    - Offline: Uses knowledge base and cached responses
    - Online: Uses AI orchestrator with multiple agents
    - Auto: Tries online, falls back to offline
    """

    def __init__(
        self,
        config: Optional[Dict[str, str]] = None,
        conversation_db: str = "conversations.db"
    ):
        """
        Initialize chatbot

        Args:
            config: API configuration (gemini_api_key, etc.)
            conversation_db: Path to conversation database
        """
        self.config = config or {}
        self.orchestrator = get_orchestrator(self.config)
        self.knowledge_base = get_knowledge_base()
        self.conversation_manager = get_conversation_manager(conversation_db)

        from tools import get_cache_manager, get_syllabus_parser
        self.orchestrator.init_tools(
            knowledge_base=self.knowledge_base,
            cache_manager=get_cache_manager(),
            syllabus_parser=get_syllabus_parser()
        )

        self.default_mode = ChatMode.AUTO
        self.stats = {
            'total_queries': 0,
            'offline_responses': 0,
            'online_responses': 0,
            'failed_responses': 0
        }

    def create_session(
        self,
        user_id: str,
        mode: ChatMode = ChatMode.AUTO,
        metadata: Optional[Dict] = None
    ) -> str:
        """
        Create new chat session

        Args:
            user_id: User identifier
            mode: Chat mode (offline/online/auto)
            metadata: Session metadata

        Returns:
            session_id: New session identifier
        """
        return self.conversation_manager.create_session(
            user_id=user_id,
            mode=mode.value,
            metadata=metadata
        )

    def chat(
        self,
        session_id: str,
        user_message: str,
        context: Optional[Dict[str, Any]] = None,
        mode: Optional[ChatMode] = None
    ) -> Dict[str, Any]:
        """
        Process chat message

        Args:
            session_id: Session identifier
            user_message: User's message
            context: Additional context (language, subject, etc.)
            mode: Override chat mode for this message

        Returns:
            Response dictionary with answer and metadata
        """
        self.stats['total_queries'] += 1

        session = self.conversation_manager.get_session_info(session_id)
        if not session:
            return {
                'success': False,
                'error': 'Invalid session ID',
                'session_id': session_id
            }

        chat_mode = mode or ChatMode(session.get('mode', 'auto'))

        self.conversation_manager.add_message(
            session_id=session_id,
            role=MessageRole.USER,
            content=user_message
        )

        conversation_history = self.conversation_manager.get_recent_context(
            session_id=session_id,
            max_messages=10
        )

        full_context = context or {}
        full_context['conversation_history'] = conversation_history

        response = None

        if chat_mode == ChatMode.OFFLINE:
            response = self._process_offline(user_message, full_context)
            self.stats['offline_responses'] += 1

        elif chat_mode == ChatMode.ONLINE:
            response = self._process_online(user_message, full_context)
            if response.get('success'):
                self.stats['online_responses'] += 1
            else:
                self.stats['failed_responses'] += 1

        else:

            full_context['has_internet'] = True
            response = self._process_online(user_message, full_context)

            if not response.get('success'):

                full_context['has_internet'] = False
                response = self._process_offline(user_message, full_context)
                response['fallback'] = True
                self.stats['offline_responses'] += 1
            else:
                self.stats['online_responses'] += 1

        if response.get('success'):
            answer = response.get('answer', response.get('message', ''))
            self.conversation_manager.add_message(
                session_id=session_id,
                role=MessageRole.ASSISTANT,
                content=answer,
                agent_id=response.get('agent_id'),
                mode=response.get('mode'),
                metadata={
                    'response_time_ms': response.get('response_time_ms'),
                    'confidence': response.get('confidence')
                }
            )
        else:
            self.stats['failed_responses'] += 1

        response['session_id'] = session_id
        response['timestamp'] = datetime.now().isoformat()

        return response

    def _process_offline(
        self,
        query: str,
        context: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Process query in offline mode
        RESTRICTION: Only handles app-related questions in offline mode
        Educational queries require internet connection

        Args:
            query: User query
            context: Query context

        Returns:
            Response dictionary
        """

        context['has_internet'] = False
        context['mode'] = AgentMode.OFFLINE

        app_keywords = [
            'app', 'help', 'how to use', 'feature', 'guide',
            'navigation', 'scan', 'share', 'qr', 'timetable',
            'notes', 'offline', 'settings', 'language'
        ]

        query_lower = query.lower()
        is_app_query = any(keyword in query_lower for keyword in app_keywords)

        if is_app_query:

            kb_results = self.knowledge_base.search_app_faqs(query, limit=3)

            if kb_results:
                best_match = kb_results[0]

                return {
                    'success': True,
                    'answer': best_match['answer'],
                    'mode': 'offline',
                    'source': 'app_faq',
                    'confidence': best_match.get('similarity', 0),
                    'agent_id': 'offline_kb',
                    'agent_name': 'App Help',
                    'response_time_ms': 0,
                    'category': 'app_help'
                }

        language = context.get('language', 'en')
        internet_messages = {
            'en': '🌐 I need internet connection to answer educational questions. In offline mode, I can only help with:\n\n✅ How to use the app\n✅ App features and navigation\n✅ Settings and preferences\n✅ QR code sharing\n✅ Notes and timetable\n\nPlease connect to internet for study help!',
            'hi': '🌐 शैक्षिक प्रश्नों का उत्तर देने के लिए मुझे इंटरनेट कनेक्शन चाहिए। ऑफ़लाइन मोड में, मैं केवल इनमें मदद कर सकता हूं:\n\n✅ ऐप का उपयोग कैसे करें\n✅ ऐप सुविधाएं और नेविगेशन\n✅ सेटिंग्स और प्राथमिकताएं\n✅ QR कोड साझाकरण\n✅ नोट्स और टाइमटेबल\n\nअध्ययन सहायता के लिए कृपया इंटरनेट से कनेक्ट करें!',
            'pa': '🌐 ਮੈਨੂੰ ਵਿਦਿਅਕ ਸਵਾਲਾਂ ਦੇ ਜਵਾਬ ਦੇਣ ਲਈ ਇੰਟਰਨੈੱਟ ਕਨੈਕਸ਼ਨ ਦੀ ਲੋੜ ਹੈ। ਔਫਲਾਈਨ ਮੋਡ ਵਿੱਚ, ਮੈਂ ਸਿਰਫ਼ ਇਹਨਾਂ ਵਿੱਚ ਮਦਦ ਕਰ ਸਕਦਾ ਹਾਂ:\n\n✅ ਐਪ ਦੀ ਵਰਤੋਂ ਕਿਵੇਂ ਕਰੀਏ\n✅ ਐਪ ਵਿਸ਼ੇਸ਼ਤਾਵਾਂ\n✅ ਸੈਟਿੰਗਜ਼\n✅ QR ਕੋਡ ਸਾਂਝਾਕਰਨ\n✅ ਨੋਟਸ ਅਤੇ ਟਾਈਮਟੇਬਲ\n\nਅਧਿਐਨ ਮਦਦ ਲਈ ਕਿਰਪਾ ਕਰਕੇ ਇੰਟਰਨੈੱਟ ਨਾਲ ਕਨੈਕਟ ਕਰੋ!'
        }

        return {
            'success': False,
            'requires_internet': True,
            'mode': 'offline',
            'message': internet_messages.get(language, internet_messages['en']),
            'query_type': 'educational',
            'suggestion': 'Connect to internet for AI-powered study assistance',
            'offline_help_available': True
        }

    def _process_online(
        self,
        query: str,
        context: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Process query in online mode
        Uses AI orchestrator with all agents

        Args:
            query: User query
            context: Query context

        Returns:
            Response dictionary
        """

        if not self.config.get('gemini_api_key'):
            return {
                'success': False,
                'error': 'No API key configured for online mode',
                'mode': 'online'
            }

        context['has_internet'] = True
        context['mode'] = AgentMode.ONLINE

        response = self.orchestrator.process_query(query, context)
        response['source'] = 'ai_orchestrator'

        return response

    async def chat_stream(
        self,
        session_id: str,
        user_message: str,
        context: Optional[Dict[str, Any]] = None,
        mode: Optional[ChatMode] = None
    ) -> AsyncIterator[str]:
        """
        Process chat message with streaming response
        (For online mode with AI models)

        Args:
            session_id: Session identifier
            user_message: User's message
            context: Additional context
            mode: Chat mode

        Yields:
            Response chunks
        """

        self.conversation_manager.add_message(
            session_id=session_id,
            role=MessageRole.USER,
            content=user_message
        )

        session = self.conversation_manager.get_session_info(session_id)
        chat_mode = mode or ChatMode(session.get('mode', 'auto'))

        response = self.chat(session_id, user_message, context, chat_mode)

        if response.get('success'):
            answer = response.get('answer', response.get('message', ''))

            words = answer.split()
            for i, word in enumerate(words):
                yield word + (' ' if i < len(words) - 1 else '')
        else:
            yield f"Error: {response.get('error', 'Failed to process request')}"

    def get_session_history(
        self,
        session_id: str,
        limit: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """Get conversation history for session"""
        return self.conversation_manager.get_conversation_history(
            session_id=session_id,
            limit=limit,
            include_metadata=True
        )

    def get_user_sessions(
        self,
        user_id: str,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """Get user's chat sessions"""
        return self.conversation_manager.get_user_sessions(
            user_id=user_id,
            limit=limit
        )

    def delete_session(self, session_id: str):
        """Delete chat session"""
        self.conversation_manager.delete_session(session_id)

    def update_session_title(self, session_id: str, title: str):
        """Update session title"""
        self.conversation_manager.update_session_title(session_id, title)

    def search_conversations(
        self,
        user_id: str,
        query: str,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """Search user's conversation history"""
        return self.conversation_manager.search_messages(
            user_id=user_id,
            query=query,
            limit=limit
        )

    def get_stats(self) -> Dict[str, Any]:
        """Get chatbot statistics"""
        orchestrator_stats = self.orchestrator.get_stats()

        return {
            'chatbot': self.stats.copy(),
            'orchestrator': orchestrator_stats,
            'mode_distribution': {
                'offline': self.stats['offline_responses'],
                'online': self.stats['online_responses'],
                'failed': self.stats['failed_responses']
            }
        }

    def health_check(self) -> Dict[str, str]:
        """Check chatbot health"""
        health = {
            'chatbot': 'healthy',
            'conversation_db': 'available',
            'knowledge_base': 'available',
            'orchestrator': 'healthy'
        }

        orchestrator_health = self.orchestrator.health_check()
        if orchestrator_health.get('orchestrator') != 'healthy':
            health['orchestrator'] = 'unhealthy'
            health['chatbot'] = 'degraded'

        return health

_chatbot = None

def get_chatbot(
    config: Optional[Dict[str, str]] = None,
    conversation_db: str = "conversations.db"
) -> DualModeChatbot:
    """Get singleton chatbot instance"""
    global _chatbot
    if _chatbot is None:
        _chatbot = DualModeChatbot(config, conversation_db)
    return _chatbot
