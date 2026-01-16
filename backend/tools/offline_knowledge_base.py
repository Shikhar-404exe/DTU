"""
Offline Knowledge Base Tool - Custom Tool #1
Provides semantic search and cached Q&A for offline operation
Uses SQLite for storage and lightweight embeddings for search
"""

import sqlite3
import json
import os
from typing import List, Dict, Optional, Tuple
from datetime import datetime
import hashlib
import numpy as np
from pathlib import Path

class OfflineKnowledgeBase:
    """
    Custom Tool for offline knowledge management
    - Stores Q&A pairs, educational content, app FAQs
    - Semantic search using lightweight embeddings
    - Works completely offline
    """

    def __init__(self, db_path: str = "knowledge_base.db"):
        """Initialize the offline knowledge base"""
        self.db_path = db_path
        self.conn = None
        self.setup_database()

    def setup_database(self):
        """Create database tables if they don't exist"""
        self.conn = sqlite3.connect(self.db_path, check_same_thread=False)
        self.conn.row_factory = sqlite3.Row
        cursor = self.conn.cursor()

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS knowledge (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                question TEXT NOT NULL,
                answer TEXT NOT NULL,
                category TEXT,
                language TEXT DEFAULT 'en',
                subject TEXT,
                grade_level TEXT,
                keywords TEXT,
                embedding TEXT,
                usage_count INTEGER DEFAULT 0,
                last_accessed TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS app_faqs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                question TEXT NOT NULL,
                answer TEXT NOT NULL,
                category TEXT,
                language TEXT DEFAULT 'en',
                keywords TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS syllabus_content (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                subject TEXT NOT NULL,
                grade_level TEXT NOT NULL,
                topic TEXT NOT NULL,
                subtopic TEXT,
                content TEXT NOT NULL,
                difficulty TEXT,
                language TEXT DEFAULT 'en',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS cache_metadata (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                content_type TEXT NOT NULL,
                content_id TEXT NOT NULL,
                data TEXT NOT NULL,
                expires_at TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(content_type, content_id)
            )
        """)

        cursor.execute("CREATE INDEX IF NOT EXISTS idx_category ON knowledge(category)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_subject ON knowledge(subject)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_language ON knowledge(language)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_keywords ON knowledge(keywords)")

        self.conn.commit()

    def simple_embedding(self, text: str) -> List[float]:
        """
        Create a simple embedding for semantic search
        Uses character n-grams and word frequency (lightweight, works offline)
        """

        text = text.lower().strip()
        words = text.split()

        embedding = [0.0] * 100

        for i, word in enumerate(words[:20]):
            hash_val = int(hashlib.md5(word.encode()).hexdigest(), 16)
            idx = hash_val % 100
            embedding[idx] += 1.0 / (i + 1)

        for i in range(len(text) - 2):
            trigram = text[i:i+3]
            hash_val = int(hashlib.md5(trigram.encode()).hexdigest(), 16)
            idx = hash_val % 100
            embedding[idx] += 0.5

        magnitude = sum(x * x for x in embedding) ** 0.5
        if magnitude > 0:
            embedding = [x / magnitude for x in embedding]

        return embedding

    def cosine_similarity(self, vec1: List[float], vec2: List[float]) -> float:
        """Calculate cosine similarity between two vectors"""
        if len(vec1) != len(vec2):
            return 0.0

        dot_product = sum(a * b for a, b in zip(vec1, vec2))
        return dot_product

    def add_knowledge(self, question: str, answer: str, category: str = "general",
                     language: str = "en", subject: str = None, grade_level: str = None,
                     keywords: str = None) -> int:
        """Add a new Q&A pair to the knowledge base"""
        cursor = self.conn.cursor()

        embedding = self.simple_embedding(question + " " + answer)
        embedding_str = json.dumps(embedding)

        cursor.execute("""
            INSERT INTO knowledge (question, answer, category, language, subject,
                                  grade_level, keywords, embedding)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (question, answer, category, language, subject, grade_level,
              keywords, embedding_str))

        self.conn.commit()
        return cursor.lastrowid

    def add_app_faq(self, question: str, answer: str, category: str = "app_help",
                   language: str = "en", keywords: str = None) -> int:
        """Add an app FAQ"""
        cursor = self.conn.cursor()
        cursor.execute("""
            INSERT INTO app_faqs (question, answer, category, language, keywords)
            VALUES (?, ?, ?, ?, ?)
        """, (question, answer, category, language, keywords))
        self.conn.commit()
        return cursor.lastrowid

    def add_syllabus_content(self, subject: str, grade_level: str, topic: str,
                            content: str, subtopic: str = None, difficulty: str = "medium",
                            language: str = "en") -> int:
        """Add syllabus content"""
        cursor = self.conn.cursor()
        cursor.execute("""
            INSERT INTO syllabus_content (subject, grade_level, topic, subtopic,
                                         content, difficulty, language)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (subject, grade_level, topic, subtopic, content, difficulty, language))
        self.conn.commit()
        return cursor.lastrowid

    def search(self, query: str, limit: int = 5, category: str = None,
               language: str = None, subject: str = None) -> List[Dict]:
        """
        Semantic search in the knowledge base
        Returns most relevant Q&A pairs
        """
        cursor = self.conn.cursor()

        sql = "SELECT * FROM knowledge WHERE 1=1"
        params = []

        if category:
            sql += " AND category = ?"
            params.append(category)
        if language:
            sql += " AND language = ?"
            params.append(language)
        if subject:
            sql += " AND subject = ?"
            params.append(subject)

        cursor.execute(sql, params)
        entries = cursor.fetchall()

        if not entries:
            return []

        query_embedding = self.simple_embedding(query)

        results = []
        for entry in entries:
            entry_dict = dict(entry)

            if entry_dict['embedding']:
                entry_embedding = json.loads(entry_dict['embedding'])
                similarity = self.cosine_similarity(query_embedding, entry_embedding)
                entry_dict['similarity'] = similarity
                results.append(entry_dict)

        results.sort(key=lambda x: x['similarity'], reverse=True)

        if results:
            top_id = results[0]['id']
            cursor.execute("""
                UPDATE knowledge
                SET usage_count = usage_count + 1, last_accessed = ?
                WHERE id = ?
            """, (datetime.now(), top_id))
            self.conn.commit()

        return results[:limit]

    def search_app_faqs(self, query: str, limit: int = 3, language: str = None) -> List[Dict]:
        """Search app FAQs using keyword matching"""
        cursor = self.conn.cursor()

        sql = """
            SELECT * FROM app_faqs
            WHERE question LIKE ? OR answer LIKE ? OR keywords LIKE ?
        """
        params = [f"%{query}%", f"%{query}%", f"%{query}%"]

        if language:
            sql += " AND language = ?"
            params.append(language)

        sql += " LIMIT ?"
        params.append(limit)

        cursor.execute(sql, params)
        results = [dict(row) for row in cursor.fetchall()]

        return results

    def get_syllabus_content(self, subject: str = None, grade_level: str = None,
                            topic: str = None, language: str = None) -> List[Dict]:
        """Retrieve syllabus content by filters"""
        cursor = self.conn.cursor()

        sql = "SELECT * FROM syllabus_content WHERE 1=1"
        params = []

        if subject:
            sql += " AND subject = ?"
            params.append(subject)
        if grade_level:
            sql += " AND grade_level = ?"
            params.append(grade_level)
        if topic:
            sql += " AND topic LIKE ?"
            params.append(f"%{topic}%")
        if language:
            sql += " AND language = ?"
            params.append(language)

        cursor.execute(sql, params)
        return [dict(row) for row in cursor.fetchall()]

    def cache_content(self, content_type: str, content_id: str, data: Dict,
                     expires_hours: int = 24):
        """Cache any content for offline use"""
        cursor = self.conn.cursor()

        expires_at = datetime.now().timestamp() + (expires_hours * 3600)
        data_str = json.dumps(data)

        cursor.execute("""
            INSERT OR REPLACE INTO cache_metadata
            (content_type, content_id, data, expires_at)
            VALUES (?, ?, ?, ?)
        """, (content_type, content_id, data_str, expires_at))

        self.conn.commit()

    def get_cached_content(self, content_type: str, content_id: str) -> Optional[Dict]:
        """Retrieve cached content if not expired"""
        cursor = self.conn.cursor()

        cursor.execute("""
            SELECT data, expires_at FROM cache_metadata
            WHERE content_type = ? AND content_id = ?
        """, (content_type, content_id))

        result = cursor.fetchone()
        if not result:
            return None

        if result['expires_at'] and result['expires_at'] < datetime.now().timestamp():
            return None

        return json.loads(result['data'])

    def get_stats(self) -> Dict:
        """Get knowledge base statistics"""
        cursor = self.conn.cursor()

        stats = {}

        cursor.execute("SELECT COUNT(*) as count FROM knowledge")
        stats['total_knowledge'] = cursor.fetchone()['count']

        cursor.execute("SELECT COUNT(*) as count FROM app_faqs")
        stats['total_faqs'] = cursor.fetchone()['count']

        cursor.execute("SELECT COUNT(*) as count FROM syllabus_content")
        stats['total_syllabus'] = cursor.fetchone()['count']

        cursor.execute("SELECT COUNT(*) as count FROM cache_metadata")
        stats['cached_items'] = cursor.fetchone()['count']

        cursor.execute("""
            SELECT category, COUNT(*) as count
            FROM knowledge
            GROUP BY category
        """)
        stats['by_category'] = {row['category']: row['count']
                               for row in cursor.fetchall()}

        return stats

    def close(self):
        """Close database connection"""
        if self.conn:
            self.conn.close()

_kb_instance = None

def get_knowledge_base(db_path: str = "knowledge_base.db") -> OfflineKnowledgeBase:
    """Get or create knowledge base instance"""
    global _kb_instance
    if _kb_instance is None:
        _kb_instance = OfflineKnowledgeBase(db_path)
    return _kb_instance
