"""
Offline Knowledge Agent - Agent #1
Provides cached responses from offline knowledge base
Critical priority - must work without internet
"""

from typing import Dict, List, Optional
from .base_agent import (
    BaseAgent, AgentMode, AgentCapability, AgentPriority, ToolIntegrationMixin
)

class OfflineKnowledgeAgent(ToolIntegrationMixin, BaseAgent):
    """
    Agent for offline knowledge retrieval
    Uses cached Q&A, app FAQs, and syllabus content
    """

    def __init__(self):
        super().__init__(
            agent_id="offline_knowledge",
            name="Offline Knowledge Agent",
            description="Provides instant responses from cached knowledge base. Works completely offline.",
            capabilities=[
                AgentCapability.TEXT_PROCESSING,
                AgentCapability.CONTENT_GENERATION
            ],
            priority=AgentPriority.CRITICAL,
            default_mode=AgentMode.OFFLINE
        )

        self.app_keywords = [
            'how to use', 'help', 'guide', 'app', 'feature',
            'navigation', 'settings', 'scan', 'share', 'qr',
            'timetable', 'notes', 'offline'
        ]

        self.education_keywords = [
            'what is', 'explain', 'definition', 'formula',
            'theorem', 'law', 'principle', 'concept'
        ]

    def can_handle(self, query: str, context: Dict = None) -> float:
        """Determine if this agent can handle the query"""
        query_lower = query.lower()

        if any(kw in query_lower for kw in self.app_keywords):
            return 0.9

        if any(kw in query_lower for kw in self.education_keywords):
            return 0.7

        return 0.3

    def process_offline(self, query: str, context: Dict = None) -> Dict:
        """Process query using offline knowledge base"""
        if not self.knowledge_base:
            return {
                'success': False,
                'error': 'Knowledge base not initialized',
                'message': 'Offline knowledge agent requires knowledge base access'
            }

        context = context or {}
        language = context.get('language', 'en')

        if self._is_app_query(query):
            return self._handle_app_query(query, language)

        return {
            'success': False,
            'requires_internet': True,
            'message': self._get_internet_required_message(language),
            'query_type': 'educational',
            'suggestion': 'Please connect to internet to get answers to educational questions.',
            'offline_features': [
                'App usage help and FAQs',
                'How to use app features',
                'Navigation guidance',
                'Settings and preferences'
            ]
        }

    def process_online(self, query: str, context: Dict = None) -> Dict:
        """
        In online mode, still use offline knowledge as it's faster
        But can be enhanced with live data if needed
        """

        return self.process_offline(query, context)

    def _is_app_query(self, query: str) -> bool:
        """Determine if query is about app functionality"""
        query_lower = query.lower()
        return any(kw in query_lower for kw in self.app_keywords)

    def _handle_app_query(self, query: str, language: str = 'en') -> Dict:
        """Handle app-related queries using FAQs"""

        faqs = self.knowledge_base.search_app_faqs(query, limit=3, language=language)

        if not faqs:
            return {
                'success': False,
                'message': 'No matching app help found. Try rephrasing your question.',
                'suggestions': [
                    'How do I use this app?',
                    'Can I use this app offline?',
                    'How do I scan notes?'
                ]
            }

        top_faq = faqs[0]

        return {
            'success': True,
            'answer': top_faq['answer'],
            'question': top_faq['question'],
            'category': top_faq.get('category', 'app_help'),
            'source': 'offline_faq',
            'confidence': 0.95,
            'alternative_results': [
                {
                    'question': faq['question'],
                    'answer': faq['answer']
                }
                for faq in faqs[1:3]
            ] if len(faqs) > 1 else []
        }

    def _handle_educational_query(self, query: str, context: Dict, language: str = 'en') -> Dict:
        """Handle educational queries using knowledge base"""

        subject = context.get('subject')
        grade_level = context.get('grade_level')

        results = self.knowledge_base.search(
            query=query,
            limit=3,
            language=language,
            subject=subject
        )

        if not results:

            return self._search_syllabus_content(query, subject, grade_level, language)

        top_result = results[0]

        return {
            'success': True,
            'answer': top_result['answer'],
            'question': top_result['question'],
            'subject': top_result.get('subject', 'General'),
            'grade_level': top_result.get('grade_level', 'All'),
            'source': 'offline_knowledge',
            'confidence': top_result['similarity'],
            'alternative_results': [
                {
                    'question': r['question'],
                    'answer': r['answer'],
                    'confidence': r['similarity']
                }
                for r in results[1:3]
            ] if len(results) > 1 else []
        }

    def _search_syllabus_content(self, query: str, subject: str,
                                 grade_level: str, language: str) -> Dict:
        """Search syllabus content as fallback"""
        syllabus_items = self.knowledge_base.get_syllabus_content(
            subject=subject,
            grade_level=grade_level,
            language=language
        )

        if not syllabus_items:
            return {
                'success': False,
                'message': 'No matching content found offline. Try being more specific or check your internet connection for online search.',
                'query': query,
                'available_subjects': self._get_available_subjects()
            }

        query_words = set(query.lower().split())

        matched_items = []
        for item in syllabus_items:
            topic_words = set(item['topic'].lower().split())
            content_words = set(item['content'].lower().split())

            match_score = len(query_words & (topic_words | content_words))
            if match_score > 0:
                matched_items.append((match_score, item))

        if not matched_items:
            return {
                'success': False,
                'message': 'Topic not found in syllabus content.',
                'available_topics': [item['topic'] for item in syllabus_items[:5]]
            }

        matched_items.sort(reverse=True, key=lambda x: x[0])
        best_match = matched_items[0][1]

        return {
            'success': True,
            'topic': best_match['topic'],
            'content': best_match['content'],
            'subject': best_match['subject'],
            'grade_level': best_match['grade_level'],
            'difficulty': best_match.get('difficulty', 'medium'),
            'source': 'syllabus_content',
            'confidence': min(matched_items[0][0] / 3, 1.0),
            'related_topics': [
                item[1]['topic']
                for item in matched_items[1:4]
            ]
        }

    def _get_available_subjects(self) -> List[str]:
        """Get list of available subjects"""
        if not self.knowledge_base:
            return []

        return ['Science', 'Mathematics', 'Social Science', 'English', 'Hindi']

    def _get_internet_required_message(self, language: str = 'en') -> str:
        """Get 'internet required' message in user's language"""
        messages = {
            'en': '🌐 Internet connection required for educational questions. I can only help with app usage questions in offline mode.',
            'hi': '🌐 शैक्षिक प्रश्नों के लिए इंटरनेट कनेक्शन आवश्यक है। ऑफ़लाइन मोड में मैं केवल ऐप उपयोग प्रश्नों में मदद कर सकता हूं।',
            'pa': '🌐 ਵਿਦਿਅਕ ਸਵਾਲਾਂ ਲਈ ਇੰਟਰਨੈੱਟ ਕਨੈਕਸ਼ਨ ਲੋੜੀਂਦਾ ਹੈ। ਔਫਲਾਈਨ ਮੋਡ ਵਿੱਚ ਮੈਂ ਸਿਰਫ਼ ਐਪ ਵਰਤੋਂ ਸਵਾਲਾਂ ਵਿੱਚ ਮਦਦ ਕਰ ਸਕਦਾ ਹਾਂ।',
            'bn': '🌐 শিক্ষামূলক প্রশ্নের জন্য ইন্টারনেট সংযোগ প্রয়োজন। অফলাইন মোডে আমি শুধুমাত্র অ্যাপ ব্যবহারের প্রশ্নে সাহায্য করতে পারি।',
            'ta': '🌐 கல்வி கேள்விகளுக்கு இணைய இணைப்பு தேவை. ஆஃப்லைன் பயன்முறையில் நான் ஆப் பயன்பாட்டு கேள்விகளில் மட்டுமே உதவ முடியும்.',
            'te': '🌐 విద్యా ప్రశ్నలకు ఇంటర్నెట్ కనెక్షన్ అవసరం. ఆఫ్‌లైన్ మోడ్‌లో నేను యాప్ వినియోగ ప్రశ్నలలో మాత్రమే సహాయం చేయగలను।',
            'mr': '🌐 शैक्षणिक प्रश्नांसाठी इंटरनेट कनेक्शन आवश्यक आहे. ऑफलाइन मोडमध्ये मी फक्त अॅप वापर प्रश्नांमध्ये मदत करू शकतो।',
            'gu': '🌐 શૈક્ષણિક પ્રશ્નો માટે ઇન્ટરનેટ કનેક્શન જરૂરી છે. ઓફલાઇન મોડમાં હું ફક્ત એપ્લિકેશન ઉપયોગ પ્રશ્નોમાં મદદ કરી શકું છું।'
        }
        return messages.get(language, messages['en'])

    def get_cached_topics(self, subject: str = None, grade_level: str = None) -> List[Dict]:
        """Get all cached topics for a subject/grade"""
        if not self.knowledge_base:
            return []

        return self.knowledge_base.get_syllabus_content(
            subject=subject,
            grade_level=grade_level
        )

    def get_stats(self) -> Dict:
        """Get agent statistics including KB stats"""
        agent_stats = self.get_info()

        if self.knowledge_base:
            kb_stats = self.knowledge_base.get_stats()
            agent_stats['knowledge_base'] = kb_stats

        return agent_stats
