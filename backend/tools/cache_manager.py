"""
Smart Cache Manager Tool - Custom Tool #2
Manages content synchronization for low-bandwidth scenarios
Implements progressive sync and offline-first strategies
"""

import json
import sqlite3
import os
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
from enum import Enum
import asyncio
from pathlib import Path

class SyncPriority(Enum):
    """Priority levels for content synchronization"""
    CRITICAL = 1
    HIGH = 2
    MEDIUM = 3
    LOW = 4

class SyncStatus(Enum):
    """Status of sync operations"""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"

class CacheManager:
    """
    Custom Tool for smart content caching and synchronization
    - Progressive data sync based on bandwidth
    - Offline-first data management
    - Intelligent cache invalidation
    """

    def __init__(self, db_path: str = "cache_manager.db"):
        """Initialize cache manager"""
        self.db_path = db_path
        self.conn = None
        self.max_cache_size_mb = 100
        self.setup_database()

    def setup_database(self):
        """Create cache management tables"""
        self.conn = sqlite3.connect(self.db_path, check_same_thread=False)
        self.conn.row_factory = sqlite3.Row
        cursor = self.conn.cursor()

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS sync_queue (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                content_type TEXT NOT NULL,
                content_id TEXT NOT NULL,
                priority TEXT NOT NULL,
                status TEXT NOT NULL,
                data_size INTEGER DEFAULT 0,
                retry_count INTEGER DEFAULT 0,
                last_attempt TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                completed_at TIMESTAMP,
                UNIQUE(content_type, content_id)
            )
        """)

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS downloaded_content (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                content_type TEXT NOT NULL,
                content_id TEXT NOT NULL,
                file_path TEXT,
                data TEXT,
                size_bytes INTEGER,
                version TEXT,
                expires_at TIMESTAMP,
                downloaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_accessed TIMESTAMP,
                access_count INTEGER DEFAULT 0,
                UNIQUE(content_type, content_id)
            )
        """)

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS sync_stats (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sync_session_id TEXT UNIQUE,
                start_time TIMESTAMP,
                end_time TIMESTAMP,
                items_synced INTEGER DEFAULT 0,
                bytes_downloaded INTEGER DEFAULT 0,
                bandwidth_kbps REAL,
                status TEXT,
                error_message TEXT
            )
        """)

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS sync_preferences (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT UNIQUE,
                auto_sync_enabled BOOLEAN DEFAULT 1,
                wifi_only BOOLEAN DEFAULT 1,
                max_cache_size_mb INTEGER DEFAULT 100,
                sync_frequency_hours INTEGER DEFAULT 24,
                last_sync TIMESTAMP
            )
        """)

        cursor.execute("CREATE INDEX IF NOT EXISTS idx_sync_status ON sync_queue(status)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_sync_priority ON sync_queue(priority)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_content_type ON downloaded_content(content_type)")

        self.conn.commit()

    def add_to_sync_queue(self, content_type: str, content_id: str,
                         priority: SyncPriority, data_size: int = 0) -> int:
        """Add content to sync queue"""
        cursor = self.conn.cursor()

        cursor.execute("""
            INSERT OR REPLACE INTO sync_queue
            (content_type, content_id, priority, status, data_size)
            VALUES (?, ?, ?, ?, ?)
        """, (content_type, content_id, priority.name, SyncStatus.PENDING.value, data_size))

        self.conn.commit()
        return cursor.lastrowid

    def get_pending_sync_items(self, limit: int = 10,
                              priority: Optional[SyncPriority] = None) -> List[Dict]:
        """Get items pending synchronization"""
        cursor = self.conn.cursor()

        sql = """
            SELECT * FROM sync_queue
            WHERE status = ?
        """
        params = [SyncStatus.PENDING.value]

        if priority:
            sql += " AND priority = ?"
            params.append(priority.name)

        sql += " ORDER BY priority, created_at LIMIT ?"
        params.append(limit)

        cursor.execute(sql, params)
        return [dict(row) for row in cursor.fetchall()]

    def update_sync_status(self, sync_id: int, status: SyncStatus,
                          retry_count: Optional[int] = None):
        """Update sync item status"""
        cursor = self.conn.cursor()

        if status == SyncStatus.COMPLETED:
            cursor.execute("""
                UPDATE sync_queue
                SET status = ?, completed_at = ?, last_attempt = ?
                WHERE id = ?
            """, (status.value, datetime.now(), datetime.now(), sync_id))
        elif retry_count is not None:
            cursor.execute("""
                UPDATE sync_queue
                SET status = ?, retry_count = ?, last_attempt = ?
                WHERE id = ?
            """, (status.value, retry_count, datetime.now(), sync_id))
        else:
            cursor.execute("""
                UPDATE sync_queue
                SET status = ?, last_attempt = ?
                WHERE id = ?
            """, (status.value, datetime.now(), sync_id))

        self.conn.commit()

    def save_downloaded_content(self, content_type: str, content_id: str,
                               data: Any, file_path: Optional[str] = None,
                               expires_hours: int = 168) -> int:
        """Save downloaded content to cache"""
        cursor = self.conn.cursor()

        if isinstance(data, (dict, list)):
            data_str = json.dumps(data)
            size_bytes = len(data_str.encode('utf-8'))
        else:
            data_str = str(data)
            size_bytes = len(data_str.encode('utf-8'))

        expires_at = datetime.now() + timedelta(hours=expires_hours)

        cursor.execute("""
            INSERT OR REPLACE INTO downloaded_content
            (content_type, content_id, file_path, data, size_bytes,
             expires_at, last_accessed)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (content_type, content_id, file_path, data_str, size_bytes,
              expires_at, datetime.now()))

        self.conn.commit()

        self.cleanup_old_content()

        return cursor.lastrowid

    def get_cached_content(self, content_type: str, content_id: str) -> Optional[Dict]:
        """Retrieve cached content"""
        cursor = self.conn.cursor()

        cursor.execute("""
            SELECT * FROM downloaded_content
            WHERE content_type = ? AND content_id = ?
        """, (content_type, content_id))

        result = cursor.fetchone()
        if not result:
            return None

        result_dict = dict(result)

        if result_dict['expires_at']:
            expires = datetime.fromisoformat(result_dict['expires_at'])
            if expires < datetime.now():
                return None

        cursor.execute("""
            UPDATE downloaded_content
            SET last_accessed = ?, access_count = access_count + 1
            WHERE id = ?
        """, (datetime.now(), result_dict['id']))
        self.conn.commit()

        try:
            result_dict['parsed_data'] = json.loads(result_dict['data'])
        except:
            result_dict['parsed_data'] = result_dict['data']

        return result_dict

    def is_content_cached(self, content_type: str, content_id: str) -> bool:
        """Check if content exists in cache and is valid"""
        content = self.get_cached_content(content_type, content_id)
        return content is not None

    def get_cache_size(self) -> Dict:
        """Get current cache size statistics"""
        cursor = self.conn.cursor()

        cursor.execute("""
            SELECT
                COUNT(*) as total_items,
                SUM(size_bytes) as total_bytes,
                content_type,
                COUNT(*) as type_count
            FROM downloaded_content
            GROUP BY content_type
        """)

        by_type = {row['content_type']: {
            'count': row['type_count'],
            'bytes': row['total_bytes'] or 0
        } for row in cursor.fetchall()}

        cursor.execute("""
            SELECT
                COUNT(*) as total_items,
                SUM(size_bytes) as total_bytes
            FROM downloaded_content
        """)

        totals = cursor.fetchone()

        return {
            'total_items': totals['total_items'] or 0,
            'total_bytes': totals['total_bytes'] or 0,
            'total_mb': (totals['total_bytes'] or 0) / (1024 * 1024),
            'by_type': by_type
        }

    def cleanup_old_content(self):
        """Remove old/expired content to maintain cache size"""
        cursor = self.conn.cursor()

        cursor.execute("""
            DELETE FROM downloaded_content
            WHERE expires_at < ?
        """, (datetime.now(),))

        cache_info = self.get_cache_size()

        if cache_info['total_mb'] > self.max_cache_size_mb:

            cursor.execute("""
                DELETE FROM downloaded_content
                WHERE id IN (
                    SELECT id FROM downloaded_content
                    ORDER BY access_count ASC, last_accessed ASC
                    LIMIT ?
                )
            """, (int(cache_info['total_items'] * 0.2),))

        self.conn.commit()

    def start_sync_session(self, session_id: str) -> int:
        """Start a new sync session"""
        cursor = self.conn.cursor()

        cursor.execute("""
            INSERT INTO sync_stats (sync_session_id, start_time, status)
            VALUES (?, ?, ?)
        """, (session_id, datetime.now(), "in_progress"))

        self.conn.commit()
        return cursor.lastrowid

    def end_sync_session(self, session_id: str, items_synced: int,
                        bytes_downloaded: int, status: str = "completed",
                        error_message: str = None):
        """End sync session and record stats"""
        cursor = self.conn.cursor()

        cursor.execute("""
            SELECT start_time FROM sync_stats
            WHERE sync_session_id = ?
        """, (session_id,))

        result = cursor.fetchone()
        if not result:
            return

        start_time = datetime.fromisoformat(result['start_time'])
        duration_seconds = (datetime.now() - start_time).total_seconds()

        bandwidth_kbps = 0
        if duration_seconds > 0:
            bandwidth_kbps = (bytes_downloaded / 1024) / duration_seconds

        cursor.execute("""
            UPDATE sync_stats
            SET end_time = ?,
                items_synced = ?,
                bytes_downloaded = ?,
                bandwidth_kbps = ?,
                status = ?,
                error_message = ?
            WHERE sync_session_id = ?
        """, (datetime.now(), items_synced, bytes_downloaded, bandwidth_kbps,
              status, error_message, session_id))

        self.conn.commit()

    def get_sync_preferences(self, user_id: str = "default") -> Dict:
        """Get user sync preferences"""
        cursor = self.conn.cursor()

        cursor.execute("""
            SELECT * FROM sync_preferences
            WHERE user_id = ?
        """, (user_id,))

        result = cursor.fetchone()

        if not result:

            cursor.execute("""
                INSERT INTO sync_preferences (user_id)
                VALUES (?)
            """, (user_id,))
            self.conn.commit()

            cursor.execute("""
                SELECT * FROM sync_preferences
                WHERE user_id = ?
            """, (user_id,))
            result = cursor.fetchone()

        return dict(result)

    def update_sync_preferences(self, user_id: str, **kwargs):
        """Update user sync preferences"""
        cursor = self.conn.cursor()

        fields = []
        values = []

        for key, value in kwargs.items():
            if key in ['auto_sync_enabled', 'wifi_only', 'max_cache_size_mb',
                      'sync_frequency_hours']:
                fields.append(f"{key} = ?")
                values.append(value)

        if not fields:
            return

        values.append(user_id)
        sql = f"UPDATE sync_preferences SET {', '.join(fields)} WHERE user_id = ?"

        cursor.execute(sql, values)
        self.conn.commit()

    def should_sync_now(self, user_id: str = "default",
                       is_wifi: bool = False) -> bool:
        """Determine if sync should run now based on preferences"""
        prefs = self.get_sync_preferences(user_id)

        if not prefs['auto_sync_enabled']:
            return False

        if prefs['wifi_only'] and not is_wifi:
            return False

        if prefs['last_sync']:
            last_sync = datetime.fromisoformat(prefs['last_sync'])
            hours_since = (datetime.now() - last_sync).total_seconds() / 3600

            if hours_since < prefs['sync_frequency_hours']:
                return False

        return True

    def mark_synced(self, user_id: str = "default"):
        """Mark that sync has been performed"""
        cursor = self.conn.cursor()
        cursor.execute("""
            UPDATE sync_preferences
            SET last_sync = ?
            WHERE user_id = ?
        """, (datetime.now(), user_id))
        self.conn.commit()

    def get_stats(self) -> Dict:
        """Get cache manager statistics"""
        cursor = self.conn.cursor()

        stats = {}

        cursor.execute("""
            SELECT status, COUNT(*) as count
            FROM sync_queue
            GROUP BY status
        """)
        stats['sync_queue'] = {row['status']: row['count']
                              for row in cursor.fetchall()}

        stats['cache'] = self.get_cache_size()

        cursor.execute("""
            SELECT * FROM sync_stats
            ORDER BY start_time DESC
            LIMIT 5
        """)
        stats['recent_syncs'] = [dict(row) for row in cursor.fetchall()]

        return stats

    def close(self):
        """Close database connection"""
        if self.conn:
            self.conn.close()

_cache_manager_instance = None

def get_cache_manager(db_path: str = "cache_manager.db") -> CacheManager:
    """Get or create cache manager instance"""
    global _cache_manager_instance
    if _cache_manager_instance is None:
        _cache_manager_instance = CacheManager(db_path)
    return _cache_manager_instance
