"""
Base Agent Architecture
Provides abstract base class for all AI agents with dual-mode support (offline/online)
"""

from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Any
from enum import Enum
import logging
from datetime import datetime

class AgentMode(Enum):
    """Agent operation modes"""
    OFFLINE = "offline"
    ONLINE = "online"
    AUTO = "auto"

class AgentCapability(Enum):
    """Agent capabilities"""
    TEXT_PROCESSING = "text_processing"
    VOICE_PROCESSING = "voice_processing"
    IMAGE_PROCESSING = "image_processing"
    VIDEO_RECOMMENDATION = "video_recommendation"
    CONTENT_GENERATION = "content_generation"
    LEARNING_PATH = "learning_path"
    ASSESSMENT = "assessment"
    TRANSLATION = "translation"
    ACCESSIBILITY = "accessibility"

class AgentPriority(Enum):
    """Agent priority levels for orchestration"""
    CRITICAL = 1
    HIGH = 2
    MEDIUM = 3
    LOW = 4

class BaseAgent(ABC):
    """
    Abstract base class for all AI agents
    Provides common functionality for offline/online operation
    """

    def __init__(self,
                 agent_id: str,
                 name: str,
                 description: str,
                 capabilities: List[AgentCapability],
                 priority: AgentPriority = AgentPriority.MEDIUM,
                 default_mode: AgentMode = AgentMode.AUTO):
        """
        Initialize base agent

        Args:
            agent_id: Unique identifier for the agent
            name: Human-readable name
            description: Agent purpose and functionality
            capabilities: List of agent capabilities
            priority: Agent priority level
            default_mode: Default operation mode
        """
        self.agent_id = agent_id
        self.name = name
        self.description = description
        self.capabilities = capabilities
        self.priority = priority
        self.default_mode = default_mode
        self.current_mode = default_mode
        self.logger = logging.getLogger(f"Agent.{agent_id}")

        self.stats = {
            'total_requests': 0,
            'offline_requests': 0,
            'online_requests': 0,
            'successful_responses': 0,
            'failed_responses': 0,
            'avg_response_time_ms': 0,
            'last_used': None
        }

    def set_mode(self, mode: AgentMode):
        """Set agent operation mode"""
        self.current_mode = mode
        self.logger.info(f"Agent {self.name} switched to {mode.value} mode")

    def can_handle(self, query: str, context: Dict = None) -> float:
        """
        Determine if this agent can handle the query

        Args:
            query: User query
            context: Additional context

        Returns:
            Confidence score (0.0 to 1.0)
        """

        return 0.0

    @abstractmethod
    def process_offline(self, query: str, context: Dict = None) -> Dict:
        """
        Process query in offline mode

        Args:
            query: User query
            context: Additional context

        Returns:
            Response dictionary
        """
        pass

    @abstractmethod
    def process_online(self, query: str, context: Dict = None) -> Dict:
        """
        Process query in online mode

        Args:
            query: User query
            context: Additional context

        Returns:
            Response dictionary
        """
        pass

    def process(self, query: str, context: Dict = None, mode: AgentMode = None) -> Dict:
        """
        Main processing method - routes to offline/online based on mode

        Args:
            query: User query
            context: Additional context
            mode: Override operation mode

        Returns:
            Response dictionary
        """
        start_time = datetime.now()

        self.stats['total_requests'] += 1
        self.stats['last_used'] = start_time.isoformat()

        active_mode = mode if mode else self.current_mode

        if active_mode == AgentMode.AUTO:
            has_internet = self._check_connectivity(context)
            active_mode = AgentMode.ONLINE if has_internet else AgentMode.OFFLINE

        try:

            if active_mode == AgentMode.OFFLINE:
                self.stats['offline_requests'] += 1
                response = self.process_offline(query, context)
            else:
                self.stats['online_requests'] += 1
                response = self.process_online(query, context)

            response['agent_id'] = self.agent_id
            response['agent_name'] = self.name
            response['mode'] = active_mode.value
            response['timestamp'] = datetime.now().isoformat()

            self.stats['successful_responses'] += 1

            elapsed = (datetime.now() - start_time).total_seconds() * 1000
            self._update_avg_response_time(elapsed)
            response['response_time_ms'] = round(elapsed, 2)

            return response

        except Exception as e:
            self.stats['failed_responses'] += 1
            self.logger.error(f"Agent {self.name} processing error: {e}")

            return {
                'success': False,
                'error': str(e),
                'agent_id': self.agent_id,
                'agent_name': self.name,
                'mode': active_mode.value,
                'timestamp': datetime.now().isoformat()
            }

    def _check_connectivity(self, context: Dict = None) -> bool:
        """
        Check internet connectivity

        Args:
            context: May contain connectivity info

        Returns:
            True if online, False if offline
        """
        if context and 'has_internet' in context:
            return context['has_internet']

        return False

    def _update_avg_response_time(self, new_time_ms: float):
        """Update average response time"""
        current_avg = self.stats['avg_response_time_ms']
        total = self.stats['successful_responses']

        if total == 1:
            self.stats['avg_response_time_ms'] = new_time_ms
        else:

            self.stats['avg_response_time_ms'] = (
                (current_avg * (total - 1) + new_time_ms) / total
            )

    def get_info(self) -> Dict:
        """Get agent information"""
        return {
            'agent_id': self.agent_id,
            'name': self.name,
            'description': self.description,
            'capabilities': [cap.value for cap in self.capabilities],
            'priority': self.priority.value,
            'current_mode': self.current_mode.value,
            'stats': self.stats
        }

    def reset_stats(self):
        """Reset agent statistics"""
        self.stats = {
            'total_requests': 0,
            'offline_requests': 0,
            'online_requests': 0,
            'successful_responses': 0,
            'failed_responses': 0,
            'avg_response_time_ms': 0,
            'last_used': None
        }

class ToolIntegrationMixin:
    """Mixin for agents that use custom tools"""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.knowledge_base = None
        self.cache_manager = None
        self.syllabus_parser = None

    def init_tools(self, kb=None, cache=None, parser=None):
        """Initialize custom tools"""
        self.knowledge_base = kb
        self.cache_manager = cache
        self.syllabus_parser = parser

    def has_tool_access(self) -> bool:
        """Check if tools are available"""
        return any([
            self.knowledge_base is not None,
            self.cache_manager is not None,
            self.syllabus_parser is not None
        ])
