"""
Study Path Planner & Accessibility Agents - Agents #7 & #8
"""

from typing import Dict, List, Optional
from .base_agent import (
    BaseAgent, AgentMode, AgentCapability, AgentPriority, ToolIntegrationMixin
)

class StudyPathPlannerAgent(ToolIntegrationMixin, BaseAgent):
    """
    Agent #7 - Study Path Planner Agent
    Creates personalized learning paths based on syllabus and user progress
    """

    def __init__(self):
        super().__init__(
            agent_id="study_path_planner",
            name="Study Path Planner Agent",
            description="Creates personalized study plans and learning paths based on syllabus",
            capabilities=[
                AgentCapability.LEARNING_PATH,
                AgentCapability.CONTENT_GENERATION
            ],
            priority=AgentPriority.MEDIUM,
            default_mode=AgentMode.AUTO
        )

    def can_handle(self, query: str, context: Dict = None) -> float:
        """Determine if this agent can handle the query"""
        query_lower = query.lower()

        planning_keywords = [
            'study plan', 'learning path', 'syllabus', 'schedule',
            'prepare for', 'roadmap', 'study schedule', 'planning',
            'what to study', 'study order', 'curriculum'
        ]

        if any(kw in query_lower for kw in planning_keywords):
            return 0.95

        return 0.2

    def process_offline(self, query: str, context: Dict = None) -> Dict:
        """Create study path using syllabus parser"""
        if not self.syllabus_parser:
            return {
                'success': False,
                'error': 'Syllabus parser not available'
            }

        context = context or {}
        user_id = context.get('user_id', 'default_user')
        subject = context.get('subject')
        grade_level = context.get('grade_level', '10')

        if not subject:
            return {
                'success': False,
                'error': 'Subject required for creating study path',
                'available_subjects': ['Science', 'Mathematics', 'Social Science']
            }

        topics = self.syllabus_parser.get_syllabus_topics(
            subject=subject,
            grade_level=grade_level
        )

        if not topics:
            return {
                'success': False,
                'error': f'No syllabus found for {subject} Grade {grade_level}',
                'suggestion': 'Try different subject or connect to internet for more content'
            }

        existing_paths = self._get_user_paths(user_id, subject)

        if existing_paths:
            return {
                'success': True,
                'has_existing_path': True,
                'paths': existing_paths,
                'message': 'You already have study paths for this subject',
                'action': 'continue_existing_or_create_new'
            }

        return self._create_new_study_path(user_id, subject, grade_level, topics, context)

    def process_online(self, query: str, context: Dict = None) -> Dict:
        """
        Create study path with additional online features
        For now, same as offline since core logic is in syllabus parser
        """
        return self.process_offline(query, context)

    def _get_user_paths(self, user_id: str, subject: str = None) -> List[Dict]:
        """Get existing study paths for user"""
        if not self.syllabus_parser:
            return []

        return []

    def _create_new_study_path(self, user_id: str, subject: str,
                               grade_level: str, topics: List[Dict],
                               context: Dict) -> Dict:
        """Create a new personalized study path"""

        available_hours_per_week = context.get('available_hours', 10)
        target_weeks = context.get('target_weeks', 12)

        path_result = self.syllabus_parser.generate_optimal_study_path(
            user_id=user_id,
            subject=subject,
            grade_level=grade_level,
            available_hours_per_week=available_hours_per_week,
            target_weeks=target_weeks
        )

        if 'error' in path_result:
            return {
                'success': False,
                'error': path_result['error']
            }

        path_details = self.syllabus_parser.get_study_path_details(path_result['path_id'])

        return {
            'success': True,
            'study_path': {
                'path_id': path_result['path_id'],
                'subject': subject,
                'grade_level': grade_level,
                'total_topics': path_result['total_topics'],
                'duration_weeks': target_weeks,
                'estimated_hours': path_result['estimated_hours'],
                'topics': path_details['items']
            },
            'next_steps': {
                'action': 'start_learning',
                'next_topic': path_details['items'][0] if path_details['items'] else None,
                'recommendation': 'Begin with the first topic in your study path'
            },
            'mode': 'offline'
        }

    def get_next_topic(self, user_id: str, path_id: int) -> Dict:
        """Get the next topic user should study"""
        if not self.syllabus_parser:
            return {
                'success': False,
                'error': 'Syllabus parser not available'
            }

        next_topic = self.syllabus_parser.get_next_topic_to_study(user_id, path_id)

        if not next_topic:
            return {
                'success': True,
                'completed': True,
                'message': 'Congratulations! You have completed this study path!',
                'suggestion': 'Review topics or start a new subject'
            }

        return {
            'success': True,
            'next_topic': {
                'topic': next_topic['topic'],
                'subtopics': next_topic.get('subtopics', []),
                'difficulty': next_topic.get('difficulty', 'medium'),
                'estimated_hours': next_topic.get('estimated_hours', 2),
                'description': next_topic.get('description', '')
            },
            'progress': {
                'sequence_order': next_topic['sequence_order'],
                'status': next_topic['status']
            }
        }

    def update_progress(self, user_id: str, path_id: int, topic: str,
                       status: str, time_spent: int = 0) -> Dict:
        """Update user's progress on a topic"""
        if not self.syllabus_parser:
            return {
                'success': False,
                'error': 'Syllabus parser not available'
            }

        from tools.syllabus_parser import TopicStatus
        status_map = {
            'completed': TopicStatus.COMPLETED,
            'in_progress': TopicStatus.IN_PROGRESS,
            'not_started': TopicStatus.NOT_STARTED
        }

        topic_status = status_map.get(status, TopicStatus.IN_PROGRESS)

        path_details = self.syllabus_parser.get_study_path_details(path_id)
        subject = path_details.get('subject', 'Unknown')

        self.syllabus_parser.update_topic_progress(
            user_id=user_id,
            subject=subject,
            topic=topic,
            status=topic_status,
            time_spent_minutes=time_spent,
            mastery_level=3 if status == 'completed' else None
        )

        updated_path = self.syllabus_parser.get_study_path_details(path_id)

        return {
            'success': True,
            'message': f'Progress updated for: {topic}',
            'progress_percentage': updated_path.get('progress_percentage', 0),
            'completed_topics': updated_path.get('completed_topics', 0),
            'total_topics': updated_path.get('total_topics', 0)
        }

    def get_review_topics(self, user_id: str, subject: str = None) -> Dict:
        """Get topics due for review (spaced repetition)"""
        if not self.syllabus_parser:
            return {
                'success': False,
                'error': 'Syllabus parser not available'
            }

        review_topics = self.syllabus_parser.get_topics_due_for_review(
            user_id=user_id,
            subject=subject
        )

        return {
            'success': True,
            'review_count': len(review_topics),
            'topics': [
                {
                    'topic': t['topic'],
                    'subject': t['subject'],
                    'last_studied': t['last_studied'],
                    'mastery_level': t['mastery_level']
                }
                for t in review_topics
            ],
            'recommendation': 'Review these topics to strengthen your understanding' if review_topics else 'No topics due for review'
        }

class AccessibilityAgent(BaseAgent):
    """
    Agent #8 - Accessibility Agent
    Provides accessibility features for users with disabilities
    """

    def __init__(self):
        super().__init__(
            agent_id="accessibility",
            name="Accessibility Agent",
            description="Provides accessibility support including screen reader, captions, and visual aids",
            capabilities=[
                AgentCapability.ACCESSIBILITY,
                AgentCapability.TEXT_PROCESSING,
                AgentCapability.VOICE_PROCESSING
            ],
            priority=AgentPriority.CRITICAL,
            default_mode=AgentMode.OFFLINE
        )

        self.features = {
            'screen_reader': {
                'name': 'Screen Reader Support',
                'description': 'Text-to-speech for all content',
                'available_offline': True
            },
            'high_contrast': {
                'name': 'High Contrast Mode',
                'description': 'Enhanced visibility with high contrast themes',
                'available_offline': True
            },
            'large_text': {
                'name': 'Large Text',
                'description': 'Increased font size for better readability',
                'available_offline': True
            },
            'captions': {
                'name': 'Closed Captions',
                'description': 'Captions for audio/video content',
                'available_offline': False
            },
            'voice_navigation': {
                'name': 'Voice Navigation',
                'description': 'Navigate app using voice commands',
                'available_offline': True
            },
            'color_blind_mode': {
                'name': 'Color Blind Friendly',
                'description': 'Color schemes for color blindness',
                'available_offline': True
            }
        }

    def can_handle(self, query: str, context: Dict = None) -> float:
        """Determine if this agent can handle the query"""
        context = context or {}

        if context.get('accessibility_mode'):
            return 1.0

        query_lower = query.lower()
        accessibility_keywords = [
            'accessibility', 'screen reader', 'high contrast',
            'large text', 'voice navigation', 'captions',
            'color blind', 'disability', 'visual aid'
        ]

        if any(kw in query_lower for kw in accessibility_keywords):
            return 0.95

        return 0.0

    def process_offline(self, query: str, context: Dict = None) -> Dict:
        """Process accessibility requests offline"""
        context = context or {}
        operation = context.get('operation', 'get_features')

        if operation == 'get_features':
            return self._get_accessibility_features()
        elif operation == 'enable_feature':
            return self._enable_feature(context.get('feature'))
        elif operation == 'format_content':
            return self._format_for_accessibility(query, context)
        else:
            return {
                'success': False,
                'error': f'Unknown operation: {operation}'
            }

    def process_online(self, query: str, context: Dict = None) -> Dict:
        """
        Process accessibility requests online
        Same as offline for most features
        """
        return self.process_offline(query, context)

    def _get_accessibility_features(self) -> Dict:
        """Get list of available accessibility features"""
        return {
            'success': True,
            'features': self.features,
            'recommendation': 'Enable features based on your needs',
            'quick_access': [
                'screen_reader',
                'large_text',
                'high_contrast'
            ]
        }

    def _enable_feature(self, feature_name: str) -> Dict:
        """Enable an accessibility feature"""
        if not feature_name or feature_name not in self.features:
            return {
                'success': False,
                'error': f'Feature {feature_name} not found',
                'available_features': list(self.features.keys())
            }

        feature = self.features[feature_name]

        return {
            'success': True,
            'feature': feature_name,
            'name': feature['name'],
            'description': feature['description'],
            'enabled': True,
            'settings': self._get_feature_settings(feature_name)
        }

    def _get_feature_settings(self, feature_name: str) -> Dict:
        """Get settings for an accessibility feature"""
        settings = {
            'screen_reader': {
                'speech_rate': 1.0,
                'pitch': 1.0,
                'volume': 1.0,
                'auto_read': False
            },
            'high_contrast': {
                'theme': 'dark',
                'contrast_level': 'high'
            },
            'large_text': {
                'font_scale': 1.5,
                'minimum_size': 18
            },
            'voice_navigation': {
                'activation_phrase': 'Hello App',
                'continuous_listening': False
            },
            'color_blind_mode': {
                'mode': 'deuteranopia',
                'options': ['protanopia', 'deuteranopia', 'tritanopia']
            }
        }

        return settings.get(feature_name, {})

    def _format_for_accessibility(self, content: str, context: Dict) -> Dict:
        """Format content for accessibility"""
        features_enabled = context.get('enabled_features', [])

        formatted_content = content
        accessibility_metadata = {}

        if 'screen_reader' in features_enabled:
            accessibility_metadata['screen_reader_text'] = self._generate_screen_reader_text(content)

        if 'images' in context:
            accessibility_metadata['alt_texts'] = [
                'Educational diagram' for _ in context['images']
            ]

        accessibility_metadata['structure'] = {
            'has_headings': content.count('#') > 0,
            'has_lists': '-' in content or '*' in content,
            'word_count': len(content.split())
        }

        return {
            'success': True,
            'original_content': content,
            'formatted_content': formatted_content,
            'accessibility_metadata': accessibility_metadata,
            'recommendations': self._get_content_recommendations(content)
        }

    def _generate_screen_reader_text(self, content: str) -> str:
        """Generate optimized text for screen readers"""

        text = content.replace('#', '').replace('*', '').replace('_', '')

        text = text.replace('.', '. ')
        text = text.replace(',', ', ')

        return text.strip()

    def _get_content_recommendations(self, content: str) -> List[str]:
        """Get recommendations for improving accessibility"""
        recommendations = []

        if len(content) > 500:
            recommendations.append('Consider breaking long content into smaller sections')

        if content.isupper():
            recommendations.append('Avoid all caps text for better readability')

        words = content.split()
        complex_words = [w for w in words if len(w) > 12]
        if len(complex_words) > 5:
            recommendations.append('Consider simplifying complex words')

        return recommendations if recommendations else ['Content is well-formatted for accessibility']
