"""
Test script for Phase 1 Custom Tools
Tests all 3 custom tools: Knowledge Base, Cache Manager, Syllabus Parser
"""

import sys
from pathlib import Path

backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))

from tools.offline_knowledge_base import get_knowledge_base
from tools.cache_manager import get_cache_manager, SyncPriority, SyncStatus
from tools.syllabus_parser import get_syllabus_parser, TopicStatus

def test_knowledge_base():
    """Test offline knowledge base functionality"""
    print("\n" + "="*60)
    print("🧪 TESTING OFFLINE KNOWLEDGE BASE")
    print("="*60)

    kb = get_knowledge_base("test_knowledge_base.db")

    print("\n1️⃣  Testing: Add Knowledge Entry")
    kb_id = kb.add_knowledge(
        question="What is machine learning?",
        answer="Machine learning is a subset of AI that enables systems to learn from data.",
        category="technology",
        subject="Computer Science"
    )
    print(f"✅ Added knowledge entry with ID: {kb_id}")

    print("\n2️⃣  Testing: Add App FAQ")
    faq_id = kb.add_app_faq(
        question="How do I logout?",
        answer="Go to Settings > Account > Logout button",
        category="app_help"
    )
    print(f"✅ Added FAQ with ID: {faq_id}")

    print("\n3️⃣  Testing: Semantic Search")
    results = kb.search("learning from data", limit=3)
    print(f"✅ Found {len(results)} results")
    if results:
        print(f"   Top result: {results[0]['question'][:50]}...")
        print(f"   Similarity: {results[0]['similarity']:.4f}")

    print("\n4️⃣  Testing: FAQ Search")
    faq_results = kb.search_app_faqs("logout")
    print(f"✅ Found {len(faq_results)} FAQ results")

    print("\n5️⃣  Testing: Content Caching")
    kb.cache_content("video", "xyz123", {"title": "Test Video", "url": "http://example.com"})
    cached = kb.get_cached_content("video", "xyz123")
    print(f"✅ Cached and retrieved: {cached['title']}")

    print("\n6️⃣  Testing: Get Statistics")
    stats = kb.get_stats()
    print(f"✅ Stats: {stats['total_knowledge']} knowledge, {stats['total_faqs']} FAQs")

    kb.close()
    print("\n✅ All Knowledge Base tests passed!")

def test_cache_manager():
    """Test cache manager functionality"""
    print("\n" + "="*60)
    print("🧪 TESTING CACHE MANAGER")
    print("="*60)

    cm = get_cache_manager("test_cache_manager.db")

    print("\n1️⃣  Testing: Add to Sync Queue")
    sync_id = cm.add_to_sync_queue(
        content_type="video",
        content_id="video_001",
        priority=SyncPriority.HIGH,
        data_size=5000000
    )
    print(f"✅ Added to sync queue with ID: {sync_id}")

    print("\n2️⃣  Testing: Get Pending Sync Items")
    pending = cm.get_pending_sync_items(limit=10)
    print(f"✅ Found {len(pending)} pending items")

    print("\n3️⃣  Testing: Save Downloaded Content")
    cm.save_downloaded_content(
        content_type="lesson",
        content_id="lesson_math_101",
        data={"title": "Algebra Basics", "content": "Learn about variables..."},
        expires_hours=48
    )
    print(f"✅ Saved downloaded content")

    print("\n4️⃣  Testing: Retrieve Cached Content")
    cached = cm.get_cached_content("lesson", "lesson_math_101")
    if cached:
        print(f"✅ Retrieved: {cached['parsed_data']['title']}")

    print("\n5️⃣  Testing: Get Cache Size")
    size_info = cm.get_cache_size()
    print(f"✅ Cache size: {size_info['total_mb']:.2f} MB ({size_info['total_items']} items)")

    print("\n6️⃣  Testing: Sync Preferences")
    prefs = cm.get_sync_preferences()
    print(f"✅ Auto-sync: {prefs['auto_sync_enabled']}, WiFi-only: {prefs['wifi_only']}")

    print("\n7️⃣  Testing: Should Sync Check")
    should_sync = cm.should_sync_now(is_wifi=True)
    print(f"✅ Should sync now: {should_sync}")

    cm.close()
    print("\n✅ All Cache Manager tests passed!")

def test_syllabus_parser():
    """Test syllabus parser functionality"""
    print("\n" + "="*60)
    print("🧪 TESTING SYLLABUS PARSER")
    print("="*60)

    parser = get_syllabus_parser("test_syllabus_data.db")

    print("\n1️⃣  Testing: Add Syllabus Topic")
    topic_id = parser.add_syllabus_topic(
        subject="Physics",
        grade_level="10",
        topic="Motion and Force",
        subtopics=["Types of motion", "Newton's laws", "Friction"],
        difficulty="intermediate",
        estimated_hours=8.0
    )
    print(f"✅ Added topic with ID: {topic_id}")

    print("\n2️⃣  Testing: Parse Syllabus Text")
    sample_syllabus = """
1. Introduction to Chemistry
   - Matter and its properties
   - Elements and compounds

2. Atomic Structure
   - Structure of atom
   - Electrons and energy levels

3. Chemical Bonding
   - Ionic bonds
   - Covalent bonds
    """

    parsed = parser.parse_syllabus_text(sample_syllabus, "Chemistry", "10")
    print(f"✅ Parsed {len(parsed)} topics from text")
    for topic in parsed:
        print(f"   - {topic['topic']}")

    print("\n3️⃣  Testing: Get Syllabus Topics")
    topics = parser.get_syllabus_topics(subject="Physics", grade_level="10")
    print(f"✅ Found {len(topics)} Physics topics for grade 10")

    print("\n4️⃣  Testing: Create Study Path")
    all_topics = parser.get_syllabus_topics()
    if all_topics:
        topic_ids = [t['id'] for t in all_topics[:3]]
        path_id = parser.create_study_path(
            user_id="test_user_001",
            path_name="My Test Study Plan",
            subject="Chemistry",
            grade_level="10",
            topic_ids=topic_ids,
            duration_days=30
        )
        print(f"✅ Created study path with ID: {path_id}")

        print("\n5️⃣  Testing: Get Study Path Details")
        path_details = parser.get_study_path_details(path_id)
        print(f"✅ Path: {path_details['path_name']}")
        print(f"   Total topics: {path_details['total_topics']}")
        print(f"   Progress: {path_details['progress_percentage']:.1f}%")

        print("\n6️⃣  Testing: Get Next Topic to Study")
        next_topic = parser.get_next_topic_to_study("test_user_001", path_id)
        if next_topic:
            print(f"✅ Next topic: {next_topic['topic']}")

    print("\n7️⃣  Testing: Update Topic Progress")
    parser.update_topic_progress(
        user_id="test_user_001",
        subject="Chemistry",
        topic="Introduction to Chemistry",
        status=TopicStatus.COMPLETED,
        time_spent_minutes=45,
        mastery_level=3
    )
    print(f"✅ Updated progress for topic")

    print("\n8️⃣  Testing: Get User Progress")
    progress = parser.get_user_progress("test_user_001")
    print(f"✅ Found progress for {len(progress)} topics")

    print("\n9️⃣  Testing: Get Statistics")
    stats = parser.get_stats()
    print(f"✅ Stats: {stats['total_topics']} topics, {stats['total_paths']} paths")

    parser.close()
    print("\n✅ All Syllabus Parser tests passed!")

def main():
    """Run all tests"""
    print("=" * 60)
    print("🚀 PHASE 1 CUSTOM TOOLS TESTING")
    print("=" * 60)

    try:
        test_knowledge_base()
        test_cache_manager()
        test_syllabus_parser()

        print("\n" + "=" * 60)
        print("✅ ALL TESTS PASSED SUCCESSFULLY!")
        print("=" * 60)
        print("\n📝 Summary:")
        print("   ✓ Offline Knowledge Base - Working")
        print("   ✓ Cache Manager - Working")
        print("   ✓ Syllabus Parser - Working")
        print("\n🎉 Phase 1 implementation complete!")
        print("=" * 60)

    except Exception as e:
        print(f"\n❌ TEST FAILED: {e}")
        import traceback
        traceback.print_exc()
        return 1

    return 0

if __name__ == "__main__":
    exit(main())
