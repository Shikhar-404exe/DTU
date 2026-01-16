"""
Syllabus Parser & Study Path Generator - Custom Tool #3
Parses educational syllabus and generates structured learning paths
Extracts topics, creates dependencies, and builds personalized study plans
"""

import json
import re
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
from enum import Enum
import sqlite3

class Difficulty(Enum):
    """Difficulty levels for topics"""
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"

class TopicStatus(Enum):
    """Learning status for topics"""
    NOT_STARTED = "not_started"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    NEEDS_REVIEW = "needs_review"

class SyllabusParser:
    """
    Custom Tool for syllabus parsing and study path generation
    - Extracts topics and subtopics from syllabus text
    - Creates topic dependencies and prerequisites
    - Generates personalized learning paths
    """

    def __init__(self, db_path: str = "syllabus_data.db"):
        """Initialize syllabus parser"""
        self.db_path = db_path
        self.conn = None
        self.setup_database()

    def setup_database(self):
        """Create database tables for syllabus and study paths"""
        self.conn = sqlite3.connect(self.db_path, check_same_thread=False)
        self.conn.row_factory = sqlite3.Row
        cursor = self.conn.cursor()

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS parsed_syllabus (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                subject TEXT NOT NULL,
                grade_level TEXT NOT NULL,
                board TEXT,
                topic TEXT NOT NULL,
                subtopics TEXT,
                description TEXT,
                difficulty TEXT,
                estimated_hours REAL,
                prerequisites TEXT,
                keywords TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS study_paths (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT NOT NULL,
                path_name TEXT NOT NULL,
                subject TEXT NOT NULL,
                grade_level TEXT NOT NULL,
                total_topics INTEGER,
                completed_topics INTEGER DEFAULT 0,
                start_date TIMESTAMP,
                target_end_date TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS study_path_items (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                path_id INTEGER NOT NULL,
                topic_id INTEGER NOT NULL,
                sequence_order INTEGER NOT NULL,
                status TEXT DEFAULT 'not_started',
                progress_percentage INTEGER DEFAULT 0,
                time_spent_minutes INTEGER DEFAULT 0,
                started_at TIMESTAMP,
                completed_at TIMESTAMP,
                notes TEXT,
                FOREIGN KEY (path_id) REFERENCES study_paths(id),
                FOREIGN KEY (topic_id) REFERENCES parsed_syllabus(id)
            )
        """)

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS user_progress (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT NOT NULL,
                subject TEXT NOT NULL,
                topic TEXT NOT NULL,
                status TEXT DEFAULT 'not_started',
                mastery_level INTEGER DEFAULT 0,
                last_studied TIMESTAMP,
                review_due_date TIMESTAMP,
                study_sessions INTEGER DEFAULT 0,
                total_time_minutes INTEGER DEFAULT 0,
                UNIQUE(user_id, subject, topic)
            )
        """)

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS topic_dependencies (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                topic_id INTEGER NOT NULL,
                prerequisite_topic_id INTEGER NOT NULL,
                dependency_type TEXT,
                FOREIGN KEY (topic_id) REFERENCES parsed_syllabus(id),
                FOREIGN KEY (prerequisite_topic_id) REFERENCES parsed_syllabus(id)
            )
        """)

        cursor.execute("CREATE INDEX IF NOT EXISTS idx_subject_grade ON parsed_syllabus(subject, grade_level)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_user_paths ON study_paths(user_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_user_progress ON user_progress(user_id, subject)")

        self.conn.commit()

    def parse_syllabus_text(self, syllabus_text: str, subject: str,
                          grade_level: str, board: str = "CBSE") -> List[Dict]:
        """
        Parse syllabus text and extract topics/subtopics
        Supports various formats (numbered lists, bullet points, etc.)
        """
        topics = []
        lines = syllabus_text.strip().split('\n')

        current_topic = None
        current_subtopics = []

        topic_patterns = [
            r'^(\d+\.?\d*)\s+(.+)$',
            r'^([A-Z]\.)\s+(.+)$',
            r'^-\s*(.+)$',
            r'^\*\s*(.+)$',
            r'^•\s*(.+)$',
        ]

        for line in lines:
            line = line.strip()
            if not line:

                if current_topic:
                    topics.append({
                        'topic': current_topic,
                        'subtopics': current_subtopics.copy()
                    })
                    current_topic = None
                    current_subtopics = []
                continue

            is_topic = False
            for pattern in topic_patterns:
                match = re.match(pattern, line)
                if match:

                    if current_topic:
                        topics.append({
                            'topic': current_topic,
                            'subtopics': current_subtopics.copy()
                        })

                    if len(match.groups()) == 2:
                        current_topic = match.group(2).strip()
                    else:
                        current_topic = match.group(1).strip()
                    current_subtopics = []
                    is_topic = True
                    break

            if not is_topic and current_topic:
                current_subtopics.append(line)

        if current_topic:
            topics.append({
                'topic': current_topic,
                'subtopics': current_subtopics
            })

        parsed_topics = []
        for topic_data in topics:
            topic_id = self.add_syllabus_topic(
                subject=subject,
                grade_level=grade_level,
                board=board,
                topic=topic_data['topic'],
                subtopics=topic_data['subtopics']
            )
            parsed_topics.append({
                'id': topic_id,
                **topic_data
            })

        return parsed_topics

    def add_syllabus_topic(self, subject: str, grade_level: str, topic: str,
                          board: str = "CBSE", subtopics: List[str] = None,
                          description: str = None, difficulty: str = None,
                          estimated_hours: float = None, prerequisites: List[str] = None) -> int:
        """Add a topic to the syllabus database"""
        cursor = self.conn.cursor()

        subtopics_str = json.dumps(subtopics) if subtopics else None
        prerequisites_str = json.dumps(prerequisites) if prerequisites else None

        cursor.execute("""
            INSERT INTO parsed_syllabus
            (subject, grade_level, board, topic, subtopics, description,
             difficulty, estimated_hours, prerequisites)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (subject, grade_level, board, topic, subtopics_str, description,
              difficulty, estimated_hours, prerequisites_str))

        self.conn.commit()
        return cursor.lastrowid

    def get_syllabus_topics(self, subject: str = None, grade_level: str = None,
                           board: str = None) -> List[Dict]:
        """Get syllabus topics by filters"""
        cursor = self.conn.cursor()

        sql = "SELECT * FROM parsed_syllabus WHERE 1=1"
        params = []

        if subject:
            sql += " AND subject = ?"
            params.append(subject)
        if grade_level:
            sql += " AND grade_level = ?"
            params.append(grade_level)
        if board:
            sql += " AND board = ?"
            params.append(board)

        sql += " ORDER BY id"

        cursor.execute(sql, params)
        topics = []

        for row in cursor.fetchall():
            topic_dict = dict(row)

            if topic_dict['subtopics']:
                topic_dict['subtopics'] = json.loads(topic_dict['subtopics'])
            if topic_dict['prerequisites']:
                topic_dict['prerequisites'] = json.loads(topic_dict['prerequisites'])
            topics.append(topic_dict)

        return topics

    def create_study_path(self, user_id: str, path_name: str, subject: str,
                         grade_level: str, topic_ids: List[int],
                         duration_days: int = 90) -> int:
        """Create a personalized study path for a user"""
        cursor = self.conn.cursor()

        start_date = datetime.now()
        target_end_date = start_date + timedelta(days=duration_days)

        cursor.execute("""
            INSERT INTO study_paths
            (user_id, path_name, subject, grade_level, total_topics,
             start_date, target_end_date)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (user_id, path_name, subject, grade_level, len(topic_ids),
              start_date, target_end_date))

        path_id = cursor.lastrowid

        for order, topic_id in enumerate(topic_ids, start=1):
            cursor.execute("""
                INSERT INTO study_path_items
                (path_id, topic_id, sequence_order)
                VALUES (?, ?, ?)
            """, (path_id, topic_id, order))

        self.conn.commit()
        return path_id

    def generate_optimal_study_path(self, user_id: str, subject: str,
                                   grade_level: str, available_hours_per_week: float = 10,
                                   target_weeks: int = 12) -> Dict:
        """
        Generate an optimal study path considering:
        - Topic dependencies
        - User's current progress
        - Available time
        - Difficulty levels
        """

        topics = self.get_syllabus_topics(subject, grade_level)

        if not topics:
            return {'error': 'No topics found for this subject/grade'}

        cursor = self.conn.cursor()
        cursor.execute("""
            SELECT topic, status, mastery_level
            FROM user_progress
            WHERE user_id = ? AND subject = ?
        """, (user_id, subject))

        progress_map = {row['topic']: row for row in cursor.fetchall()}

        sorted_topics = []
        completed_topics = set()

        for topic in topics:
            if progress_map.get(topic['topic'], {}).get('status') == 'completed':
                completed_topics.add(topic['topic'])
                continue

            has_prereq = topic.get('prerequisites') and len(topic['prerequisites']) > 0
            is_beginner = topic.get('difficulty') == Difficulty.BEGINNER.value

            if not has_prereq and is_beginner:
                sorted_topics.append(topic)

        remaining = [t for t in topics if t not in sorted_topics
                    and t['topic'] not in completed_topics]

        max_iterations = len(remaining) + 1
        iteration = 0

        while remaining and iteration < max_iterations:
            iteration += 1
            added_this_round = []

            for topic in remaining:
                prereqs = topic.get('prerequisites', [])
                if not prereqs or all(p in completed_topics or
                                     any(t['topic'] == p for t in sorted_topics)
                                     for p in prereqs):
                    sorted_topics.append(topic)
                    added_this_round.append(topic)

            remaining = [t for t in remaining if t not in added_this_round]

        sorted_topics.extend(remaining)

        total_available_hours = available_hours_per_week * target_weeks
        topic_ids = [t['id'] for t in sorted_topics]

        path_id = self.create_study_path(
            user_id=user_id,
            path_name=f"{subject} - {grade_level} Complete Path",
            subject=subject,
            grade_level=grade_level,
            topic_ids=topic_ids,
            duration_days=target_weeks * 7
        )

        return {
            'path_id': path_id,
            'total_topics': len(sorted_topics),
            'estimated_hours': total_available_hours,
            'weeks': target_weeks,
            'topics': sorted_topics
        }

    def update_topic_progress(self, user_id: str, subject: str, topic: str,
                             status: TopicStatus, time_spent_minutes: int = 0,
                             mastery_level: int = None):
        """Update user's progress on a topic"""
        cursor = self.conn.cursor()

        review_due_date = None
        if status == TopicStatus.COMPLETED and mastery_level:

            days_until_review = mastery_level * 7
            review_due_date = datetime.now() + timedelta(days=days_until_review)

        cursor.execute("""
            INSERT INTO user_progress
            (user_id, subject, topic, status, mastery_level, last_studied,
             review_due_date, study_sessions, total_time_minutes)
            VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)
            ON CONFLICT(user_id, subject, topic) DO UPDATE SET
                status = excluded.status,
                mastery_level = excluded.mastery_level,
                last_studied = excluded.last_studied,
                review_due_date = excluded.review_due_date,
                study_sessions = study_sessions + 1,
                total_time_minutes = total_time_minutes + excluded.total_time_minutes
        """, (user_id, subject, topic, status.value, mastery_level,
              datetime.now(), review_due_date, time_spent_minutes))

        self.conn.commit()

    def get_user_progress(self, user_id: str, subject: str = None) -> List[Dict]:
        """Get user's learning progress"""
        cursor = self.conn.cursor()

        sql = "SELECT * FROM user_progress WHERE user_id = ?"
        params = [user_id]

        if subject:
            sql += " AND subject = ?"
            params.append(subject)

        sql += " ORDER BY last_studied DESC"

        cursor.execute(sql, params)
        return [dict(row) for row in cursor.fetchall()]

    def get_topics_due_for_review(self, user_id: str, subject: str = None) -> List[Dict]:
        """Get topics that need review based on spaced repetition"""
        cursor = self.conn.cursor()

        sql = """
            SELECT * FROM user_progress
            WHERE user_id = ?
            AND status = 'completed'
            AND review_due_date <= ?
        """
        params = [user_id, datetime.now()]

        if subject:
            sql += " AND subject = ?"
            params.append(subject)

        sql += " ORDER BY review_due_date"

        cursor.execute(sql, params)
        return [dict(row) for row in cursor.fetchall()]

    def get_study_path_details(self, path_id: int) -> Dict:
        """Get detailed information about a study path"""
        cursor = self.conn.cursor()

        cursor.execute("SELECT * FROM study_paths WHERE id = ?", (path_id,))
        path = cursor.fetchone()

        if not path:
            return {'error': 'Study path not found'}

        path_dict = dict(path)

        cursor.execute("""
            SELECT spi.*, ps.topic, ps.subtopics, ps.difficulty, ps.estimated_hours
            FROM study_path_items spi
            JOIN parsed_syllabus ps ON spi.topic_id = ps.id
            WHERE spi.path_id = ?
            ORDER BY spi.sequence_order
        """, (path_id,))

        items = []
        for row in cursor.fetchall():
            item = dict(row)
            if item['subtopics']:
                item['subtopics'] = json.loads(item['subtopics'])
            items.append(item)

        path_dict['items'] = items

        completed = sum(1 for item in items if item['status'] == 'completed')
        path_dict['progress_percentage'] = (completed / len(items) * 100) if items else 0

        return path_dict

    def get_next_topic_to_study(self, user_id: str, path_id: int) -> Optional[Dict]:
        """Get the next topic the user should study in their path"""
        cursor = self.conn.cursor()

        cursor.execute("""
            SELECT spi.*, ps.topic, ps.subtopics, ps.description,
                   ps.difficulty, ps.estimated_hours
            FROM study_path_items spi
            JOIN parsed_syllabus ps ON spi.topic_id = ps.id
            WHERE spi.path_id = ?
            AND spi.status NOT IN ('completed')
            ORDER BY spi.sequence_order
            LIMIT 1
        """, (path_id,))

        result = cursor.fetchone()

        if not result:
            return None

        topic = dict(result)
        if topic['subtopics']:
            topic['subtopics'] = json.loads(topic['subtopics'])

        return topic

    def get_stats(self) -> Dict:
        """Get syllabus parser statistics"""
        cursor = self.conn.cursor()

        stats = {}

        cursor.execute("SELECT COUNT(*) as count FROM parsed_syllabus")
        stats['total_topics'] = cursor.fetchone()['count']

        cursor.execute("SELECT COUNT(*) as count FROM study_paths")
        stats['total_paths'] = cursor.fetchone()['count']

        cursor.execute("""
            SELECT subject, grade_level, COUNT(*) as count
            FROM parsed_syllabus
            GROUP BY subject, grade_level
        """)
        stats['by_subject_grade'] = [dict(row) for row in cursor.fetchall()]

        cursor.execute("""
            SELECT COUNT(DISTINCT user_id) as count
            FROM user_progress
        """)
        stats['active_users'] = cursor.fetchone()['count']

        return stats

    def close(self):
        """Close database connection"""
        if self.conn:
            self.conn.close()

_syllabus_parser_instance = None

def get_syllabus_parser(db_path: str = "syllabus_data.db") -> SyllabusParser:
    """Get or create syllabus parser instance"""
    global _syllabus_parser_instance
    if _syllabus_parser_instance is None:
        _syllabus_parser_instance = SyllabusParser(db_path)
    return _syllabus_parser_instance
