"""
Dual-Mode Chatbot Package
Provides chatbot with offline/online modes and conversation management
"""

from chatbot.dual_mode_chatbot import (
    DualModeChatbot,
    ChatMode,
    get_chatbot
)

from chatbot.conversation_manager import (
    ConversationManager,
    MessageRole,
    get_conversation_manager
)

__all__ = [
    'DualModeChatbot',
    'ChatMode',
    'get_chatbot',
    'ConversationManager',
    'MessageRole',
    'get_conversation_manager'
]
