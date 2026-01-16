"""
Study Assistant Agent - Agent #2
AI-powered study helper for homework, explanations, and problem solving
Works offline with cached content, enhanced online with Gemini API
"""

from typing import Dict, List, Optional
import google.generativeai as genai
from .base_agent import (
    BaseAgent, AgentMode, AgentCapability, AgentPriority, ToolIntegrationMixin
)

class StudyAssistantAgent(ToolIntegrationMixin, BaseAgent):
    """
    Intelligent study assistant
    Offline: Uses cached Q&A and syllabus content
    Online: Uses Gemini API for dynamic explanations
    """

    def __init__(self, gemini_api_key: str = None):
        super().__init__(
            agent_id="study_assistant",
            name="Study Assistant Agent",
            description="Helps with homework, explanations, problem solving, and study guidance",
            capabilities=[
                AgentCapability.TEXT_PROCESSING,
                AgentCapability.CONTENT_GENERATION,
                AgentCapability.ASSESSMENT
            ],
            priority=AgentPriority.HIGH,
            default_mode=AgentMode.AUTO
        )

        self.gemini_api_key = gemini_api_key
        self.model = None

        if gemini_api_key:
            try:
                genai.configure(api_key=gemini_api_key)
                self.model = genai.GenerativeModel('gemini-2.0-flash-exp')
                self.logger.info("Gemini model initialized for Study Assistant")
            except Exception as e:
                self.logger.error(f"Failed to initialize Gemini: {e}")

        self.study_keywords = [
            'explain', 'solve', 'how to', 'what is', 'why',
            'homework', 'problem', 'question', 'understand',
            'learn', 'teach', 'example', 'steps', 'solution'
        ]

        self.subjects = {
            'mathematics': ['math', 'algebra', 'geometry', 'calculus', 'equation', 'solve', 'calculate'],
            'science': ['science', 'physics', 'chemistry', 'biology', 'experiment', 'theory'],
            'social_science': ['history', 'geography', 'civics', 'politics', 'democracy'],
            'english': ['english', 'grammar', 'essay', 'literature', 'poem']
        }

    def can_handle(self, query: str, context: Dict = None) -> float:
        """Determine if this agent can handle the query"""
        query_lower = query.lower()

        if any(kw in query_lower for kw in self.study_keywords):
            return 0.95

        for subject_kws in self.subjects.values():
            if any(kw in query_lower for kw in subject_kws):
                return 0.8

        if query.strip().endswith('?'):
            return 0.6

        return 0.4

    def process_offline(self, query: str, context: Dict = None) -> Dict:
        """Process study query using offline knowledge base"""
        if not self.knowledge_base:
            return {
                'success': False,
                'error': 'Knowledge base not available',
                'message': 'Study assistant requires knowledge base for offline operation'
            }

        context = context or {}

        subject = self._detect_subject(query)
        if subject and not context.get('subject'):
            context['subject'] = subject

        results = self.knowledge_base.search(
            query=query,
            limit=3,
            subject=context.get('subject'),
            language=context.get('language', 'en')
        )

        if results and results[0]['similarity'] > 0.3:

            top_result = results[0]

            return {
                'success': True,
                'answer': top_result['answer'],
                'question': top_result['question'],
                'subject': top_result.get('subject', subject or 'General'),
                'confidence': top_result['similarity'],
                'mode': 'offline',
                'source': 'cached_knowledge',
                'explanation': 'This answer is from offline cached content.',
                'related_questions': [
                    r['question'] for r in results[1:3]
                ] if len(results) > 1 else []
            }

        return self._provide_offline_guidance(query, context, subject)

    def process_online(self, query: str, context: Dict = None) -> Dict:
        """Process study query using Gemini API"""
        if not self.model:

            self.logger.warning("Gemini API not available, falling back to offline mode")
            return self.process_offline(query, context)

        context = context or {}
        subject = self._detect_subject(query)
        grade_level = context.get('grade_level', '10')
        language = context.get('language', 'en')

        system_prompt = self._build_educational_prompt(subject, grade_level, language)

        try:

            full_prompt = f"{system_prompt}\n\nStudent Question: {query}"

            response = self.model.generate_content(full_prompt)
            answer = response.text

            related = self.knowledge_base.search(query, limit=3) if self.knowledge_base else []

            return {
                'success': True,
                'answer': answer,
                'question': query,
                'subject': subject or 'General',
                'grade_level': grade_level,
                'mode': 'online',
                'source': 'gemini_api',
                'confidence': 0.9,
                'explanation': 'This answer was generated by AI based on your question.',
                'related_content': [
                    {
                        'question': r['question'],
                        'subject': r.get('subject')
                    }
                    for r in related[:3]
                ] if related else []
            }

        except Exception as e:
            self.logger.error(f"Gemini API error: {e}")

            offline_response = self.process_offline(query, context)
            offline_response['note'] = 'Online AI unavailable, using cached content'
            return offline_response

    def _detect_subject(self, query: str) -> Optional[str]:
        """Detect subject from query keywords"""
        query_lower = query.lower()

        for subject, keywords in self.subjects.items():
            if any(kw in query_lower for kw in keywords):

                return subject.replace('_', ' ').title()

        return None

    def _build_educational_prompt(self, subject: str, grade_level: str, language: str) -> str:
        """Build educational system prompt for Gemini"""
        prompt = f"""You are a helpful study assistant for rural Indian students.

Context:
- Grade Level: {grade_level}
- Subject: {subject or 'General'}
- Language: {language}
- Target Audience: Rural students with varying literacy levels

Guidelines:
1. Provide clear, simple explanations suitable for grade {grade_level}
2. Use examples from everyday life and rural context when possible
3. Break down complex concepts into simple steps
4. Use Hindi/local language terms when relevant (but respond in {language})
5. Be encouraging and supportive
6. Provide practical study tips when appropriate
7. Keep explanations concise but comprehensive

For math problems:
- Show step-by-step solutions
- Explain the reasoning behind each step
- Provide formula when relevant

For science topics:
- Explain with real-world examples
- Relate to daily observations
- Mention practical applications

For other subjects:
- Provide clear definitions
- Use analogies and examples
- Relate to student's context"""

        return prompt

    def _provide_offline_guidance(self, query: str, context: Dict, subject: str) -> Dict:
        """Provide limited guidance when no cached answer available"""

        topics = []
        if self.knowledge_base and subject:
            syllabus_content = self.knowledge_base.get_syllabus_content(
                subject=subject,
                grade_level=context.get('grade_level')
            )
            topics = [item['topic'] for item in syllabus_content[:5]]

        return {
            'success': False,
            'message': 'Detailed answer not available offline. Connect to internet for AI-powered explanations.',
            'query': query,
            'subject': subject or 'Unknown',
            'available_offline': False,
            'suggestion': 'Try connecting to internet, or rephrase your question to match available topics.',
            'available_topics': topics,
            'tip': 'Offline mode works best for pre-loaded syllabus topics. Your question might require online AI assistance.'
        }

    def generate_practice_questions(self, topic: str, difficulty: str = 'medium',
                                   count: int = 5) -> Dict:
        """Generate practice questions for a topic (online only)"""
        if not self.model:
            return {
                'success': False,
                'error': 'Online mode required for generating practice questions'
            }

        try:
            prompt = f"""Generate {count} practice questions on the topic: {topic}
Difficulty level: {difficulty}
Format: Return questions numbered 1-{count}, each on a new line.
Make questions suitable for self-study and practice."""

            response = self.model.generate_content(prompt)
            questions_text = response.text

            questions = [
                q.strip()
                for q in questions_text.split('\n')
                if q.strip() and any(c.isdigit() for c in q[:3])
            ]

            return {
                'success': True,
                'topic': topic,
                'difficulty': difficulty,
                'questions': questions[:count],
                'count': len(questions),
                'note': 'Practice these questions to improve your understanding'
            }

        except Exception as e:
            self.logger.error(f"Error generating questions: {e}")
            return {
                'success': False,
                'error': str(e)
            }

    def get_study_tips(self, subject: str, context: Dict = None) -> Dict:
        """Get study tips for a subject"""
        tips_database = {
            'Mathematics': [
                'Practice daily - even 15 minutes helps',
                'Understand concepts before memorizing formulas',
                'Solve previous year questions',
                'Make a formula sheet for quick revision',
                'Learn from mistakes - review wrong answers'
            ],
            'Science': [
                'Connect theory with real-life examples',
                'Draw diagrams to understand concepts better',
                'Do experiments when possible',
                'Make notes in your own words',
                'Revise regularly with spaced repetition'
            ],
            'Social Science': [
                'Make timeline charts for history',
                'Use maps for geography topics',
                'Connect events with their causes and effects',
                'Make short notes for revision',
                'Practice answer writing'
            ],
            'English': [
                'Read daily - stories, newspapers, or books',
                'Practice writing short paragraphs',
                'Learn new words with their usage',
                'Speak English with friends for practice',
                'Listen to English content (audio/video)'
            ]
        }

        tips = tips_database.get(subject, [
            'Study regularly in short sessions',
            'Take breaks every 30-45 minutes',
            'Teach concepts to others to strengthen understanding',
            'Make your own notes',
            'Practice active recall'
        ])

        return {
            'success': True,
            'subject': subject,
            'tips': tips,
            'general_advice': 'Consistent daily practice is more effective than last-minute studying.'
        }
