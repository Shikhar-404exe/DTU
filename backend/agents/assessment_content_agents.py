"""
Assessment & Content Discovery Agents - Agents #5 & #6
"""

from typing import Dict, List, Optional
import random
from .base_agent import (
    BaseAgent, AgentMode, AgentCapability, AgentPriority, ToolIntegrationMixin
)

class AssessmentAgent(ToolIntegrationMixin, BaseAgent):
    """
    Agent #5 - Assessment Agent
    Generates quizzes, evaluates answers, provides feedback
    """

    def __init__(self, gemini_model=None):
        super().__init__(
            agent_id="assessment",
            name="Assessment Agent",
            description="Generates quizzes, tests, and provides learning assessments",
            capabilities=[
                AgentCapability.ASSESSMENT,
                AgentCapability.CONTENT_GENERATION
            ],
            priority=AgentPriority.MEDIUM,
            default_mode=AgentMode.AUTO
        )

        self.model = gemini_model

        self.quiz_templates = {
            'Mathematics': {
                'easy': [
                    'What is 5 + 7?',
                    'Calculate the area of a square with side 4 cm',
                    'What is 3 × 8?',
                ],
                'medium': [
                    'Solve: 2x + 5 = 15',
                    'Find the perimeter of a rectangle with length 8 cm and width 5 cm',
                    'Calculate: (15 + 25) ÷ 4'
                ],
                'hard': [
                    'Solve the quadratic equation: x² - 5x + 6 = 0',
                    'Find the value of sin(30°)',
                    'Calculate the volume of a cylinder with radius 7 cm and height 10 cm'
                ]
            },
            'Science': {
                'easy': [
                    'What is the chemical symbol for water?',
                    'Name the process by which plants make food',
                    'What is the unit of force?'
                ],
                'medium': [
                    'Explain Newton\'s first law of motion',
                    'What is photosynthesis? Write the equation',
                    'Describe the structure of an atom'
                ],
                'hard': [
                    'Explain the difference between concave and convex lenses',
                    'Describe the working of a human heart',
                    'Explain how electricity is generated in a thermal power plant'
                ]
            }
        }

    def can_handle(self, query: str, context: Dict = None) -> float:
        """Determine if this agent can handle the query"""
        query_lower = query.lower()

        assessment_keywords = [
            'quiz', 'test', 'question', 'practice', 'mcq',
            'exam', 'assessment', 'evaluate', 'check answer'
        ]

        if any(kw in query_lower for kw in assessment_keywords):
            return 0.9

        return 0.2

    def process_offline(self, query: str, context: Dict = None) -> Dict:
        """Generate assessment using offline templates"""
        context = context or {}

        operation = context.get('operation', 'generate_quiz')

        if operation == 'generate_quiz':
            return self._generate_offline_quiz(context)
        elif operation == 'evaluate_answer':
            return self._evaluate_answer_basic(context)
        else:
            return {
                'success': False,
                'error': f'Operation {operation} not supported offline'
            }

    def process_online(self, query: str, context: Dict = None) -> Dict:
        """Generate assessment using AI"""
        context = context or {}
        operation = context.get('operation', 'generate_quiz')

        if operation == 'generate_quiz':
            return self._generate_ai_quiz(query, context)
        elif operation == 'evaluate_answer':
            return self._evaluate_answer_ai(context)
        else:

            return self.process_offline(query, context)

    def _generate_offline_quiz(self, context: Dict) -> Dict:
        """Generate quiz from pre-loaded templates"""
        subject = context.get('subject', 'Mathematics')
        difficulty = context.get('difficulty', 'medium')
        count = context.get('count', 5)

        if subject not in self.quiz_templates:
            available = list(self.quiz_templates.keys())
            return {
                'success': False,
                'error': f'Subject {subject} not available offline',
                'available_subjects': available
            }

        if difficulty not in self.quiz_templates[subject]:
            difficulty = 'medium'

        questions = self.quiz_templates[subject][difficulty]
        selected = random.sample(questions, min(count, len(questions)))

        return {
            'success': True,
            'subject': subject,
            'difficulty': difficulty,
            'question_count': len(selected),
            'questions': [
                {
                    'id': i + 1,
                    'question': q,
                    'type': 'short_answer'
                }
                for i, q in enumerate(selected)
            ],
            'mode': 'offline',
            'note': 'Questions from pre-loaded bank. Connect to internet for custom AI-generated quizzes.'
        }

    def _generate_ai_quiz(self, query: str, context: Dict) -> Dict:
        """Generate quiz using Gemini AI"""
        if not self.model:
            return self.process_offline(query, context)

        subject = context.get('subject', 'General')
        topic = context.get('topic', query)
        difficulty = context.get('difficulty', 'medium')
        count = context.get('count', 5)
        question_type = context.get('question_type', 'mcq')

        try:
            prompt = f"""Generate {count} {question_type} questions on the topic: {topic}
Subject: {subject}
Difficulty: {difficulty}

Format:
For MCQ: Question, 4 options (A, B, C, D), correct answer
For Short Answer: Question only

Make questions educational and appropriate for students."""

            response = self.model.generate_content(prompt)

            return {
                'success': True,
                'subject': subject,
                'topic': topic,
                'difficulty': difficulty,
                'question_count': count,
                'questions_text': response.text,
                'mode': 'online',
                'source': 'ai_generated',
                'note': 'AI-generated questions for practice'
            }

        except Exception as e:
            self.logger.error(f"AI quiz generation failed: {e}")
            return self.process_offline(query, context)

    def _evaluate_answer_basic(self, context: Dict) -> Dict:
        """Basic answer evaluation (offline)"""
        question = context.get('question', '')
        answer = context.get('answer', '')
        correct_answer = context.get('correct_answer')

        if not correct_answer:
            return {
                'success': False,
                'error': 'Correct answer required for offline evaluation'
            }

        is_correct = answer.lower().strip() == correct_answer.lower().strip()

        return {
            'success': True,
            'is_correct': is_correct,
            'your_answer': answer,
            'correct_answer': correct_answer if not is_correct else None,
            'feedback': 'Correct!' if is_correct else 'Incorrect. Please try again.',
            'mode': 'offline',
            'evaluation_method': 'exact_match'
        }

    def _evaluate_answer_ai(self, context: Dict) -> Dict:
        """AI-powered answer evaluation (online)"""
        if not self.model:
            return self._evaluate_answer_basic(context)

        question = context.get('question', '')
        answer = context.get('answer', '')

        try:
            prompt = f"""Evaluate this student answer:

Question: {question}
Student Answer: {answer}

Provide:
1. Is the answer correct? (Yes/No)
2. Brief feedback (encouraging if correct, helpful if incorrect)
3. If incorrect, give a hint without revealing the full answer

Keep response concise and student-friendly."""

            response = self.model.generate_content(prompt)

            return {
                'success': True,
                'evaluation': response.text,
                'mode': 'online',
                'source': 'ai_evaluation'
            }

        except Exception as e:
            self.logger.error(f"AI evaluation failed: {e}")
            return self._evaluate_answer_basic(context)

class ContentDiscoveryAgent(ToolIntegrationMixin, BaseAgent):
    """
    Agent #6 - Content Discovery Agent
    Recommends YouTube videos and educational content
    """

    def __init__(self, youtube_api_key: str = None):
        super().__init__(
            agent_id="content_discovery",
            name="Content Discovery Agent",
            description="Discovers and recommends educational videos and content",
            capabilities=[
                AgentCapability.VIDEO_RECOMMENDATION,
                AgentCapability.CONTENT_GENERATION
            ],
            priority=AgentPriority.MEDIUM,
            default_mode=AgentMode.AUTO
        )

        self.youtube_api_key = youtube_api_key

        self.cached_channels = {
            'Mathematics': [
                'Khan Academy',
                'Vedantu',
                'Unacademy',
                'Physics Wallah'
            ],
            'Science': [
                'Khan Academy',
                'Crash Course',
                'Vedantu',
                'Byju\'s'
            ],
            'Social Science': [
                'Unacademy',
                'Study IQ',
                'Khan Academy'
            ]
        }

    def can_handle(self, query: str, context: Dict = None) -> float:
        """Determine if this agent can handle the query"""
        query_lower = query.lower()

        content_keywords = [
            'video', 'youtube', 'watch', 'learn from',
            'recommend', 'tutorial', 'lecture', 'explanation'
        ]

        if any(kw in query_lower for kw in content_keywords):
            return 0.85

        return 0.3

    def process_offline(self, query: str, context: Dict = None) -> Dict:
        """Provide cached video recommendations"""
        context = context or {}
        subject = context.get('subject', 'Mathematics')

        channels = self.cached_channels.get(subject, self.cached_channels['Mathematics'])

        cached_videos = []
        if self.cache_manager:
            cached = self.cache_manager.get_cached_content('youtube_recommendations', subject)
            if cached:
                cached_videos = cached.get('parsed_data', {}).get('videos', [])

        return {
            'success': True,
            'subject': subject,
            'recommended_channels': channels,
            'cached_videos': cached_videos,
            'mode': 'offline',
            'note': 'Showing cached recommendations. Connect to internet for latest videos.',
            'suggestion': f'Search for "{subject} tutorial" on YouTube when online'
        }

    def process_online(self, query: str, context: Dict = None) -> Dict:
        """Search and recommend YouTube videos"""
        if not self.youtube_api_key:
            return self.process_offline(query, context)

        context = context or {}
        subject = context.get('subject')
        topic = context.get('topic', query)
        max_results = context.get('max_results', 10)

        return {
            'success': True,
            'query': topic,
            'subject': subject,
            'mode': 'online',
            'instruction': 'use_youtube_api',
            'api_endpoint': 'https://www.googleapis.com/youtube/v3/search',
            'parameters': {
                'q': f'{topic} tutorial educational',
                'part': 'snippet',
                'maxResults': max_results,
                'type': 'video',
                'videoCategoryId': '27',
                'relevanceLanguage': context.get('language', 'en'),
                'safeSearch': 'strict'
            },
            'cache_instructions': {
                'cache_results': True,
                'cache_duration_hours': 24,
                'cache_key': f'youtube_{subject}_{topic}'
            }
        }

    def cache_video_recommendations(self, subject: str, videos: List[Dict]) -> Dict:
        """Cache video recommendations for offline access"""
        if not self.cache_manager:
            return {'success': False, 'error': 'Cache manager not available'}

        self.cache_manager.save_downloaded_content(
            content_type='youtube_recommendations',
            content_id=subject,
            data={'videos': videos, 'subject': subject},
            expires_hours=48
        )

        return {
            'success': True,
            'cached_count': len(videos),
            'subject': subject
        }
