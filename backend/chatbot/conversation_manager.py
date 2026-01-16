"""
Conversation History Manager for Dual-Mode Chatbot
Manages conversation persistence with SQLite for offline capability
"""

import sqlite3
import json
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict, Optional, Any
from enum import Enum

class MessageRole(Enum):
    """Message role in conversation"""
    USER = "user"
    ASSISTANT = "assistant"
    SYSTEM = "system"

class ConversationManager:
    """
    Manages conversation history with SQLite persistence
    Supports offline storage and retrieval of chat sessions
    """

    def __init__(self, db_path: str = "conversations.db"):
        """
        Initialize conversation manager

        Args:
            db_path: Path to SQLite database file
        """
        self.db_path = Path(db_path)
        self._init_database()

    def _init_database(self):
        """Initialize database schema"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS sessions (
                session_id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                title TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                message_count INTEGER DEFAULT 0,
                mode TEXT DEFAULT 'auto',
                metadata TEXT
            )
        """)

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS messages (
                message_id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT NOT NULL,
                role TEXT NOT NULL,
                content TEXT NOT NULL,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                agent_id TEXT,
                mode TEXT,
                metadata TEXT,
                FOREIGN KEY (session_id) REFERENCES sessions(session_id)
            )
        """)

        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_sessions_user
            ON sessions(user_id, updated_at DESC)
        """)

        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_messages_session
            ON messages(session_id, timestamp)
        """)

        conn.commit()
        conn.close()

    def create_session(
        self,
        user_id: str,
        title: Optional[str] = None,
        mode: str = 'auto',
        metadata: Optional[Dict] = None
    ) -> str:
        """
        Create new conversation session

        Args:
            user_id: User identifier
            title: Session title (auto-generated if None)
            mode: Chat mode (offline/online/auto)
            metadata: Additional session metadata

        Returns:
            session_id: Unique session identifier
        """
        session_id = f"{user_id}_{datetime.now().strftime('%Y%m%d_%H%M%S_%f')}"

        if title is None:
            title = f"Chat - {datetime.now().strftime('%b %d, %Y %I:%M %p')}"

        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO sessions (session_id, user_id, title, mode, metadata)
            VALUES (?, ?, ?, ?, ?)
        """, (
            session_id,
            user_id,
            title,
            mode,
            json.dumps(metadata) if metadata else None
        ))

        conn.commit()
        conn.close()

        return session_id

    def add_message(
        self,
        session_id: str,
        role: MessageRole,
        content: str,
        agent_id: Optional[str] = None,
        mode: Optional[str] = None,
        metadata: Optional[Dict] = None
    ) -> int:
        """
        Add message to conversation

        Args:
            session_id: Session identifier
            role: Message role (user/assistant/system)
            content: Message content
            agent_id: Agent that generated response (if assistant)
            mode: Processing mode used
            metadata: Additional message metadata

        Returns:
            message_id: Unique message identifier
        """
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO messages (session_id, role, content, agent_id, mode, metadata)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            session_id,
            role.value,
            content,
            agent_id,
            mode,
            json.dumps(metadata) if metadata else None
        ))

        message_id = cursor.lastrowid

        cursor.execute("""
            UPDATE sessions
            SET updated_at = CURRENT_TIMESTAMP,
                message_count = message_count + 1
            WHERE session_id = ?
        """, (session_id,))

        conn.commit()
        conn.close()

        return message_id

    def get_conversation_history(
        self,
        session_id: str,
        limit: Optional[int] = None,
        include_metadata: bool = False
    ) -> List[Dict[str, Any]]:
        """
        Get conversation history for session

        Args:
            session_id: Session identifier
            limit: Maximum number of messages (None for all)
            include_metadata: Include message metadata

        Returns:
            List of messages with role and content
        """
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        query = """
            SELECT message_id, role, content, timestamp, agent_id, mode, metadata
            FROM messages
            WHERE session_id = ?
            ORDER BY timestamp ASC
        """

        if limit:
            query += f" LIMIT {limit}"

        cursor.execute(query, (session_id,))
        rows = cursor.fetchall()
        conn.close()

        messages = []
        for row in rows:
            message = {
                'message_id': row[0],
                'role': row[1],
                'content': row[2],
                'timestamp': row[3]
            }

            if include_metadata:
                message.update({
                    'agent_id': row[4],
                    'mode': row[5],
                    'metadata': json.loads(row[6]) if row[6] else None
                })

            messages.append(message)

        return messages

    def get_recent_context(
        self,
        session_id: str,
        max_messages: int = 10
    ) -> List[Dict[str, str]]:
        """
        Get recent messages for context (formatted for AI)

        Args:
            session_id: Session identifier
            max_messages: Maximum number of recent messages

        Returns:
            List of messages with role and content only
        """
        messages = self.get_conversation_history(session_id, limit=max_messages)
        return [
            {'role': msg['role'], 'content': msg['content']}
            for msg in messages
        ]

    def get_user_sessions(
        self,
        user_id: str,
        limit: int = 50,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Get user's conversation sessions

        Args:
            user_id: User identifier
            limit: Maximum sessions to return
            offset: Pagination offset

        Returns:
            List of sessions with metadata
        """
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute("""
            SELECT session_id, title, created_at, updated_at,
                   message_count, mode, metadata
            FROM sessions
            WHERE user_id = ?
            ORDER BY updated_at DESC
            LIMIT ? OFFSET ?
        """, (user_id, limit, offset))

        rows = cursor.fetchall()
        conn.close()

        sessions = []
        for row in rows:
            sessions.append({
                'session_id': row[0],
                'title': row[1],
                'created_at': row[2],
                'updated_at': row[3],
                'message_count': row[4],
                'mode': row[5],
                'metadata': json.loads(row[6]) if row[6] else None
            })

        return sessions

    def update_session_title(self, session_id: str, title: str):
        """Update session title"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute("""
            UPDATE sessions SET title = ? WHERE session_id = ?
        """, (title, session_id))

        conn.commit()
        conn.close()

    def delete_session(self, session_id: str):
        """Delete session and all messages"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute("DELETE FROM messages WHERE session_id = ?", (session_id,))
        cursor.execute("DELETE FROM sessions WHERE session_id = ?", (session_id,))

        conn.commit()
        conn.close()

    def cleanup_old_sessions(self, days: int = 90):
        """
        Delete sessions older than specified days

        Args:
            days: Age threshold in days
        """
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

        cursor.execute("""
            DELETE FROM messages WHERE session_id IN (
                SELECT session_id FROM sessions
                WHERE updated_at < ?
            )
        """, (cutoff_date,))

        cursor.execute("""
            DELETE FROM sessions WHERE updated_at < ?
        """, (cutoff_date,))

        deleted_count = cursor.rowcount
        conn.commit()
        conn.close()

        return deleted_count

    def get_session_info(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Get session information"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute("""
            SELECT session_id, user_id, title, created_at, updated_at,
                   message_count, mode, metadata
            FROM sessions
            WHERE session_id = ?
        """, (session_id,))

        row = cursor.fetchone()
        conn.close()

        if not row:
            return None

        return {
            'session_id': row[0],
            'user_id': row[1],
            'title': row[2],
            'created_at': row[3],
            'updated_at': row[4],
            'message_count': row[5],
            'mode': row[6],
            'metadata': json.loads(row[7]) if row[7] else None
        }

    def search_messages(
        self,
        user_id: str,
        query: str,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """
        Search messages by content

        Args:
            user_id: User identifier
            query: Search query
            limit: Maximum results

        Returns:
            List of matching messages with session info
        """
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute("""
            SELECT m.message_id, m.session_id, m.role, m.content,
                   m.timestamp, s.title
            FROM messages m
            JOIN sessions s ON m.session_id = s.session_id
            WHERE s.user_id = ? AND m.content LIKE ?
            ORDER BY m.timestamp DESC
            LIMIT ?
        """, (user_id, f"%{query}%", limit))

        rows = cursor.fetchall()
        conn.close()

        results = []
        for row in rows:
            results.append({
                'message_id': row[0],
                'session_id': row[1],
                'role': row[2],
                'content': row[3],
                'timestamp': row[4],
                'session_title': row[5]
            })

        return results

_conversation_manager = None

def get_conversation_manager(db_path: str = "conversations.db") -> ConversationManager:
    """Get singleton conversation manager instance"""
    global _conversation_manager
    if _conversation_manager is None:
        _conversation_manager = ConversationManager(db_path)
    return _conversation_manager
