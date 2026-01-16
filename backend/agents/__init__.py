
"""
Multi-Agent AI System for Rural Education
Contains 8 specialized agents coordinated by an orchestrator
"""

from .base_agent import (
    BaseAgent, AgentMode, AgentCapability, AgentPriority, ToolIntegrationMixin
)
from .offline_knowledge_agent import OfflineKnowledgeAgent
from .study_assistant_agent import StudyAssistantAgent
from .voice_language_agents import VoiceInterfaceAgent, LanguageSupportAgent
from .assessment_content_agents import AssessmentAgent, ContentDiscoveryAgent
from .study_path_accessibility_agents import StudyPathPlannerAgent, AccessibilityAgent
from .offline_photomath_agent import OfflinePhotoMathAgent
from .orchestrator import AgentOrchestrator, get_orchestrator

__all__ = [

    'BaseAgent',
    'AgentMode',
    'AgentCapability',
    'AgentPriority',
    'ToolIntegrationMixin',

    'OfflineKnowledgeAgent',
    'StudyAssistantAgent',
    'VoiceInterfaceAgent',
    'LanguageSupportAgent',
    'AssessmentAgent',
    'ContentDiscoveryAgent',
    'StudyPathPlannerAgent',
    'AccessibilityAgent',
    'OfflinePhotoMathAgent',

    'AgentOrchestrator',
    'get_orchestrator',
]
