"""
Agent Orchestrator - Central coordinator for all AI agents
Routes queries to appropriate agents and manages multi-agent collaboration
"""

from typing import Dict, List, Optional, Tuple
import logging
from datetime import datetime

from .base_agent import BaseAgent, AgentMode, AgentPriority
from .offline_knowledge_agent import OfflineKnowledgeAgent
from .study_assistant_agent import StudyAssistantAgent
from .voice_language_agents import VoiceInterfaceAgent, LanguageSupportAgent
from .assessment_content_agents import AssessmentAgent, ContentDiscoveryAgent
from .study_path_accessibility_agents import StudyPathPlannerAgent, AccessibilityAgent

class AgentOrchestrator:
    """
    Central orchestrator for managing all AI agents
    Handles query routing, agent selection, and response coordination
    """

    def __init__(self, config: Dict = None):
        """
        Initialize agent orchestrator

        Args:
            config: Configuration dictionary with API keys and settings
        """
        self.config = config or {}
        self.logger = logging.getLogger("AgentOrchestrator")

        self.agents: Dict[str, BaseAgent] = {}
        self._initialize_agents()

        self.knowledge_base = None
        self.cache_manager = None
        self.syllabus_parser = None

        self.stats = {
            'total_queries': 0,
            'successful_responses': 0,
            'failed_responses': 0,
            'agent_usage': {},
            'avg_response_time_ms': 0
        }

    def _initialize_agents(self):
        """Initialize all 8 agents"""
        self.logger.info("Initializing agents...")

        self.agents['offline_knowledge'] = OfflineKnowledgeAgent()

        gemini_key = self.config.get('gemini_api_key')
        self.agents['study_assistant'] = StudyAssistantAgent(gemini_api_key=gemini_key)

        google_cloud_key = self.config.get('google_cloud_key')
        self.agents['voice_interface'] = VoiceInterfaceAgent(google_cloud_key=google_cloud_key)

        self.agents['language_support'] = LanguageSupportAgent()

        if gemini_key:
            import google.generativeai as genai
            genai.configure(api_key=gemini_key)
            model = genai.GenerativeModel('gemini-2.0-flash-exp')
            self.agents['assessment'] = AssessmentAgent(gemini_model=model)
        else:
            self.agents['assessment'] = AssessmentAgent()

        youtube_key = self.config.get('youtube_api_key')
        self.agents['content_discovery'] = ContentDiscoveryAgent(youtube_api_key=youtube_key)

        self.agents['study_path_planner'] = StudyPathPlannerAgent()

        self.agents['accessibility'] = AccessibilityAgent()

        self.logger.info(f"✅ Initialized {len(self.agents)} agents")

    def init_tools(self, knowledge_base=None, cache_manager=None, syllabus_parser=None):
        """Initialize custom tools and distribute to agents"""
        self.knowledge_base = knowledge_base
        self.cache_manager = cache_manager
        self.syllabus_parser = syllabus_parser

        tool_users = [
            'offline_knowledge',
            'study_assistant',
            'assessment',
            'content_discovery',
            'study_path_planner'
        ]

        for agent_id in tool_users:
            if agent_id in self.agents:
                agent = self.agents[agent_id]
                if hasattr(agent, 'init_tools'):
                    agent.init_tools(
                        kb=knowledge_base,
                        cache=cache_manager,
                        parser=syllabus_parser
                    )

        self.logger.info("✅ Custom tools distributed to agents")

    def process_query(self, query: str, context: Dict = None) -> Dict:
        """
        Main entry point for processing user queries

        Args:
            query: User query text
            context: Additional context (user_id, language, mode, etc.)

        Returns:
            Response dictionary from selected agent
        """
        start_time = datetime.now()
        self.stats['total_queries'] += 1

        context = context or {}

        try:

            selected_agents = self._select_agents(query, context)

            if not selected_agents:
                return self._default_response(query, context)

            primary_agent_id, confidence = selected_agents[0]
            primary_agent = self.agents[primary_agent_id]

            self.logger.info(f"Selected agent: {primary_agent.name} (confidence: {confidence:.2f})")

            response = primary_agent.process(query, context)

            if len(selected_agents) > 1 and response.get('success'):
                response = self._enhance_response(response, selected_agents[1:], query, context)

            if response.get('success'):
                self.stats['successful_responses'] += 1
            else:
                self.stats['failed_responses'] += 1

            self._update_agent_usage(primary_agent_id)

            elapsed = (datetime.now() - start_time).total_seconds() * 1000
            response['total_response_time_ms'] = round(elapsed, 2)

            return response

        except Exception as e:
            self.logger.error(f"Error processing query: {e}")
            self.stats['failed_responses'] += 1

            return {
                'success': False,
                'error': str(e),
                'message': 'An error occurred while processing your request',
                'timestamp': datetime.now().isoformat()
            }

    def _select_agents(self, query: str, context: Dict) -> List[Tuple[str, float]]:
        """
        Select appropriate agents for handling the query

        Returns:
            List of (agent_id, confidence) tuples sorted by confidence
        """
        agent_scores = []

        for agent_id, agent in self.agents.items():
            confidence = agent.can_handle(query, context)
            if confidence > 0:
                agent_scores.append((agent_id, confidence, agent.priority.value))

        agent_scores.sort(key=lambda x: (-x[1], x[2]))

        return [(agent_id, conf) for agent_id, conf, _ in agent_scores[:3]]

    def _default_response(self, query: str, context: Dict) -> Dict:
        """Provide default response when no agent can handle the query"""

        fallback_agent = self.agents['offline_knowledge']

        self.logger.info("Using offline knowledge agent as fallback")

        response = fallback_agent.process(query, context)
        response['is_fallback'] = True

        return response

    def _enhance_response(self, primary_response: Dict,
                         secondary_agents: List[Tuple[str, float]],
                         query: str, context: Dict) -> Dict:
        """
        Enhance primary response with insights from secondary agents
        """
        enhancements = {}

        for agent_id, confidence in secondary_agents[:2]:
            agent = self.agents[agent_id]

            try:

                if agent_id == 'content_discovery' and confidence > 0.5:

                    video_context = context.copy()
                    video_context['subject'] = primary_response.get('subject')
                    video_response = agent.process(query, video_context)

                    if video_response.get('success'):
                        enhancements['recommended_videos'] = video_response

                elif agent_id == 'study_path_planner' and confidence > 0.5:

                    enhancements['study_path_available'] = True

                elif agent_id == 'assessment' and confidence > 0.5:

                    enhancements['practice_available'] = True

            except Exception as e:
                self.logger.warning(f"Enhancement from {agent_id} failed: {e}")

        if enhancements:
            primary_response['enhancements'] = enhancements

        return primary_response

    def _update_agent_usage(self, agent_id: str):
        """Update agent usage statistics"""
        if agent_id not in self.stats['agent_usage']:
            self.stats['agent_usage'][agent_id] = 0
        self.stats['agent_usage'][agent_id] += 1

    def get_agent(self, agent_id: str) -> Optional[BaseAgent]:
        """Get a specific agent by ID"""
        return self.agents.get(agent_id)

    def list_agents(self) -> List[Dict]:
        """Get information about all available agents"""
        return [
            agent.get_info()
            for agent in self.agents.values()
        ]

    def get_agent_by_capability(self, capability: str) -> List[BaseAgent]:
        """Get all agents with a specific capability"""
        matching_agents = []

        for agent in self.agents.values():
            if any(cap.value == capability for cap in agent.capabilities):
                matching_agents.append(agent)

        return matching_agents

    def set_mode(self, mode: AgentMode, agent_ids: List[str] = None):
        """Set operation mode for agents"""
        target_agents = agent_ids if agent_ids else list(self.agents.keys())

        for agent_id in target_agents:
            if agent_id in self.agents:
                self.agents[agent_id].set_mode(mode)

        self.logger.info(f"Set mode to {mode.value} for {len(target_agents)} agents")

    def get_stats(self) -> Dict:
        """Get orchestrator statistics"""
        return {
            'total_queries': self.stats['total_queries'],
            'successful_responses': self.stats['successful_responses'],
            'failed_responses': self.stats['failed_responses'],
            'success_rate': (
                self.stats['successful_responses'] / self.stats['total_queries'] * 100
                if self.stats['total_queries'] > 0 else 0
            ),
            'agent_usage': self.stats['agent_usage'],
            'total_agents': len(self.agents),
            'agents': [
                {
                    'id': agent_id,
                    'name': agent.name,
                    'usage_count': self.stats['agent_usage'].get(agent_id, 0)
                }
                for agent_id, agent in self.agents.items()
            ]
        }

    def health_check(self) -> Dict:
        """Check health status of all agents and tools"""
        health = {
            'orchestrator': 'healthy',
            'agents': {},
            'tools': {}
        }

        for agent_id, agent in self.agents.items():
            try:

                info = agent.get_info()
                health['agents'][agent_id] = 'healthy' if info else 'unhealthy'
            except Exception as e:
                health['agents'][agent_id] = f'unhealthy: {e}'

        health['tools']['knowledge_base'] = 'available' if self.knowledge_base else 'not_initialized'
        health['tools']['cache_manager'] = 'available' if self.cache_manager else 'not_initialized'
        health['tools']['syllabus_parser'] = 'available' if self.syllabus_parser else 'not_initialized'

        return health

_orchestrator_instance = None

def get_orchestrator(config: Dict = None) -> AgentOrchestrator:
    """Get or create orchestrator instance"""
    global _orchestrator_instance
    if _orchestrator_instance is None:
        _orchestrator_instance = AgentOrchestrator(config)
    return _orchestrator_instance
