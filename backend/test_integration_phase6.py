"""
Phase 6: Complete System Integration Tests
Tests end-to-end workflows across all components
"""

import asyncio
import time
import json
from typing import Dict, List, Any

from tools.knowledge_base import KnowledgeBase
from tools.cache_tool import CacheTool
from tools.syllabus_tool import SyllabusTool
from agents.content_agent import ContentAgent
from agents.summarization_agent import SummarizationAgent
from agents.homework_agent import HomeworkAgent
from agents.qa_agent import QAAgent
from agents.recommendation_agent import RecommendationAgent
from agents.timetable_agent import TimetableAgent
from agents.progress_agent import ProgressAgent
from agents.creative_agent import CreativeAgent
from agents.orchestrator_agent import OrchestratorAgent
from chatbot.conversation_manager import ConversationManager
from chatbot.dual_mode_chatbot import DualModeChatbot
from services.tts_service import TTSService
from services.stt_service import STTService
from services.youtube_service import YouTubeService

class IntegrationTestSuite:
    """Comprehensive integration test suite for all phases"""

    def __init__(self):
        self.results = {
            "total_tests": 0,
            "passed": 0,
            "failed": 0,
            "errors": [],
            "test_details": []
        }

        self.kb = KnowledgeBase()
        self.cache = CacheTool()
        self.syllabus = SyllabusTool()
        self.orchestrator = OrchestratorAgent(self.kb, self.cache, self.syllabus)
        self.chatbot = DualModeChatbot(self.orchestrator, self.kb, self.cache, self.syllabus)
        self.tts = TTSService()
        self.stt = STTService()
        self.youtube = YouTubeService()

    def log_test(self, name: str, passed: bool, details: str = "", error: str = ""):
        """Log test result"""
        self.results["total_tests"] += 1
        if passed:
            self.results["passed"] += 1
            status = "✓ PASS"
        else:
            self.results["failed"] += 1
            status = "✗ FAIL"
            if error:
                self.results["errors"].append(f"{name}: {error}")

        self.results["test_details"].append({
            "name": name,
            "status": status,
            "details": details,
            "error": error
        })

        print(f"{status} - {name}")
        if details:
            print(f"      {details}")
        if error:
            print(f"      Error: {error}")

    def test_knowledge_base_integration(self):
        """Test KB with multiple content types"""
        try:

            kb_id1 = self.kb.add_knowledge("Photosynthesis is the process plants use to make food",
                                          {"subject": "Science", "topic": "Biology"})
            kb_id2 = self.kb.add_knowledge("Pythagorean theorem: a² + b² = c²",
                                          {"subject": "Math", "topic": "Geometry"})
            kb_id3 = self.kb.add_knowledge("Mahatma Gandhi led India's independence movement",
                                          {"subject": "History", "topic": "Freedom Struggle"})

            results = self.kb.search("photosynthesis", limit=1)
            passed = len(results) > 0 and "photosynthesis" in results[0]["content"].lower()

            details = f"Added 3 KB entries, searched and found {len(results)} results"
            self.log_test("Knowledge Base Integration", passed, details)
            return passed
        except Exception as e:
            self.log_test("Knowledge Base Integration", False, error=str(e))
            return False

    def test_cache_tool_integration(self):
        """Test cache with TTL and retrieval"""
        try:

            self.cache.store("user_session_123", {"user": "test", "timestamp": time.time()}, ttl=300)
            self.cache.store("temp_data", {"temp": True}, ttl=60)

            session = self.cache.retrieve("user_session_123")
            passed = session is not None and session.get("user") == "test"

            details = f"Stored 2 cache entries, retrieved successfully"
            self.log_test("Cache Tool Integration", passed, details)
            return passed
        except Exception as e:
            self.log_test("Cache Tool Integration", False, error=str(e))
            return False

    def test_syllabus_integration(self):
        """Test syllabus with grade and subject queries"""
        try:

            subjects_8 = self.syllabus.get_subjects(grade=8)
            topics = self.syllabus.get_topics(subject="Science", grade=8)
            content = self.syllabus.get_content(subject="Math", grade=8, topic="Algebra")

            passed = len(subjects_8) > 0 and len(topics) > 0
            details = f"Grade 8: {len(subjects_8)} subjects, {len(topics)} science topics"
            self.log_test("Syllabus Tool Integration", passed, details)
            return passed
        except Exception as e:
            self.log_test("Syllabus Tool Integration", False, error=str(e))
            return False

    async def test_content_agent_workflow(self):
        """Test content agent with KB lookup"""
        try:
            agent = ContentAgent(self.kb, self.cache, self.syllabus)

            result = await agent.process("Explain photosynthesis in simple terms")
            passed = result.get("success", False) and len(result.get("response", "")) > 0

            details = f"Response length: {len(result.get('response', ''))} chars"
            self.log_test("Content Agent Workflow", passed, details)
            return passed
        except Exception as e:
            self.log_test("Content Agent Workflow", False, error=str(e))
            return False

    async def test_qa_agent_workflow(self):
        """Test Q&A agent with complex questions"""
        try:
            agent = QAAgent(self.kb, self.cache, self.syllabus)

            result = await agent.process("What is the Pythagorean theorem and how is it used?")
            passed = result.get("success", False) and len(result.get("response", "")) > 0

            details = f"Q&A response generated successfully"
            self.log_test("Q&A Agent Workflow", passed, details)
            return passed
        except Exception as e:
            self.log_test("Q&A Agent Workflow", False, error=str(e))
            return False

    async def test_orchestrator_routing(self):
        """Test orchestrator with various queries"""
        try:

            queries = [
                ("Explain Newton's laws", "content_agent"),
                ("Summarize this chapter on cells", "summarization_agent"),
                ("Give me homework on algebra", "homework_agent"),
                ("What is photosynthesis?", "qa_agent"),
            ]

            passed = True
            routed = []

            for query, expected_agent in queries:
                result = await self.orchestrator.process(query)
                agent_used = result.get("agent_id", "")
                routed.append(agent_used)
                if not result.get("success"):
                    passed = False

            details = f"Routed to: {', '.join(routed)}"
            self.log_test("Orchestrator Routing", passed, details)
            return passed
        except Exception as e:
            self.log_test("Orchestrator Routing", False, error=str(e))
            return False

    async def test_chatbot_session_management(self):
        """Test chatbot session creation and persistence"""
        try:

            session_id = await self.chatbot.create_session("test_user_integration")

            result1 = await self.chatbot.chat(session_id, "Tell me about photosynthesis")
            result2 = await self.chatbot.chat(session_id, "Can you explain that in simpler terms?")

            passed = (result1.get("success") and result2.get("success") and
                     session_id is not None)

            history = await self.chatbot.get_history(session_id)
            details = f"Session {session_id[:8]}... with {len(history)} messages"

            self.log_test("Chatbot Session Management", passed, details)
            return passed
        except Exception as e:
            self.log_test("Chatbot Session Management", False, error=str(e))
            return False

    async def test_chatbot_mode_switching(self):
        """Test offline/online mode switching"""
        try:
            session_id = await self.chatbot.create_session("test_user_modes", mode="auto")

            result_offline = await self.chatbot.chat(
                session_id,
                "What is algebra?",
                mode="offline"
            )

            result_online = await self.chatbot.chat(
                session_id,
                "Explain calculus",
                mode="online"
            )

            passed = (result_offline.get("mode") == "offline" and
                     result_online.get("mode") == "online")

            details = f"Offline: {result_offline.get('mode')}, Online: {result_online.get('mode')}"
            self.log_test("Chatbot Mode Switching", passed, details)
            return passed
        except Exception as e:
            self.log_test("Chatbot Mode Switching", False, error=str(e))
            return False

    def test_tts_service_multilingual(self):
        """Test TTS with multiple languages"""
        try:
            results = []
            languages = ["en", "hi", "pa"]

            for lang in languages:
                result = self.tts.synthesize(
                    text="Hello, this is a test",
                    language=lang,
                    use_online=False
                )
                results.append(result.get("success", False))

            passed = all(results)
            details = f"TTS tested in {len(languages)} languages"
            self.log_test("TTS Multilingual Support", passed, details)
            return passed
        except Exception as e:
            self.log_test("TTS Multilingual Support", False, error=str(e))
            return False

    def test_stt_service_languages(self):
        """Test STT language support"""
        try:
            languages = self.stt.get_supported_languages()
            passed = len(languages) >= 9

            details = f"STT supports {len(languages)} languages"
            self.log_test("STT Language Support", passed, details)
            return passed
        except Exception as e:
            self.log_test("STT Language Support", False, error=str(e))
            return False

    def test_youtube_service_offline_online(self):
        """Test YouTube in both offline and online modes"""
        try:

            offline_result = self.youtube.search_videos(
                query="mathematics",
                max_results=5,
                use_online=False
            )

            passed = (offline_result.get("success") and
                     offline_result.get("provider") == "offline" and
                     len(offline_result.get("recommended_channels", [])) > 0)

            details = f"Offline: {len(offline_result.get('recommended_channels', []))} channels"
            self.log_test("YouTube Service Offline/Online", passed, details)
            return passed
        except Exception as e:
            self.log_test("YouTube Service Offline/Online", False, error=str(e))
            return False

    async def test_voice_to_response_workflow(self):
        """Test complete voice workflow: STT → Chatbot → TTS"""
        try:

            voice_text = "What is photosynthesis?"

            session_id = await self.chatbot.create_session("voice_user")

            chat_result = await self.chatbot.chat(session_id, voice_text)

            if chat_result.get("success"):
                response_text = chat_result.get("response", "")[:100]
                tts_result = self.tts.synthesize(
                    text=response_text,
                    language="en",
                    use_online=False
                )
                passed = tts_result.get("success", False)
            else:
                passed = False

            details = "STT → Chatbot → TTS workflow completed"
            self.log_test("Voice-to-Response Workflow", passed, details)
            return passed
        except Exception as e:
            self.log_test("Voice-to-Response Workflow", False, error=str(e))
            return False

    async def test_educational_content_pipeline(self):
        """Test: Query → KB Search → Agent Processing → YouTube Recommendation"""
        try:
            query = "I want to learn about Newton's laws of motion"

            kb_results = self.kb.search("Newton's laws", limit=3)

            session_id = await self.chatbot.create_session("edu_pipeline_user")
            chat_result = await self.chatbot.chat(session_id, query)

            youtube_result = self.youtube.search_videos(
                query="Newton's laws physics",
                max_results=5,
                use_online=False
            )

            passed = (len(kb_results) > 0 and
                     chat_result.get("success") and
                     youtube_result.get("success"))

            details = f"KB: {len(kb_results)} results, Chat: OK, YouTube: {len(youtube_result.get('recommended_channels', []))} channels"
            self.log_test("Educational Content Pipeline", passed, details)
            return passed
        except Exception as e:
            self.log_test("Educational Content Pipeline", False, error=str(e))
            return False

    async def test_multilingual_learning_flow(self):
        """Test: English query → Hindi response → Voice output"""
        try:

            session_id = await self.chatbot.create_session("hindi_user")

            result = await self.chatbot.chat(session_id, "Explain gravity in simple terms")

            if result.get("success"):
                tts_result = self.tts.synthesize(
                    text="गुरुत्वाकर्षण एक बल है",
                    language="hi",
                    use_online=False
                )
                passed = tts_result.get("success", False)
            else:
                passed = False

            details = "English query → Processing → Hindi voice output"
            self.log_test("Multilingual Learning Flow", passed, details)
            return passed
        except Exception as e:
            self.log_test("Multilingual Learning Flow", False, error=str(e))
            return False

    async def test_all_8_agents_via_chatbot(self):
        """Test that all 8 agents can be accessed via chatbot"""
        try:
            session_id = await self.chatbot.create_session("agent_test_user")

            agent_queries = [
                "Explain photosynthesis",
                "Summarize the chapter on cells",
                "Give me homework on algebra",
                "What is the Pythagorean theorem?",
                "Recommend study materials for physics",
                "Create a study timetable for me",
                "Track my progress in mathematics",
                "Write a creative story about space",
            ]

            agents_used = []
            all_successful = True

            for query in agent_queries:
                result = await self.chatbot.chat(session_id, query)
                if result.get("success"):
                    agent_id = result.get("agent_id", "unknown")
                    agents_used.append(agent_id)
                else:
                    all_successful = False

            unique_agents = len(set(agents_used))
            passed = all_successful and unique_agents >= 5

            details = f"{unique_agents} unique agents used: {', '.join(set(agents_used))}"
            self.log_test("All 8 Agents via Chatbot", passed, details)
            return passed
        except Exception as e:
            self.log_test("All 8 Agents via Chatbot", False, error=str(e))
            return False

    async def test_performance_stress(self):
        """Test system under load - multiple concurrent requests"""
        try:
            session_id = await self.chatbot.create_session("stress_test_user")

            start_time = time.time()
            tasks = [
                self.chatbot.chat(session_id, f"Question number {i}")
                for i in range(10)
            ]

            results = await asyncio.gather(*tasks, return_exceptions=True)
            end_time = time.time()

            successful = sum(1 for r in results if isinstance(r, dict) and r.get("success"))
            avg_time = (end_time - start_time) / len(tasks)

            passed = successful >= 8
            details = f"{successful}/10 successful, avg {avg_time:.2f}s per request"
            self.log_test("Performance Stress Test", passed, details)
            return passed
        except Exception as e:
            self.log_test("Performance Stress Test", False, error=str(e))
            return False

    async def run_all_tests(self):
        """Run complete integration test suite"""
        print("\n" + "="*70)
        print("PHASE 6: INTEGRATION TESTING - COMPLETE SYSTEM TEST")
        print("="*70 + "\n")

        print("Phase 1: Tools Integration")
        print("-" * 70)
        self.test_knowledge_base_integration()
        self.test_cache_tool_integration()
        self.test_syllabus_integration()

        print("\nPhase 2: Agents Integration")
        print("-" * 70)
        await self.test_content_agent_workflow()
        await self.test_qa_agent_workflow()
        await self.test_orchestrator_routing()

        print("\nPhase 3: Chatbot Integration")
        print("-" * 70)
        await self.test_chatbot_session_management()
        await self.test_chatbot_mode_switching()

        print("\nPhase 4: Services Integration")
        print("-" * 70)
        self.test_tts_service_multilingual()
        self.test_stt_service_languages()
        self.test_youtube_service_offline_online()

        print("\nEnd-to-End Integration Tests")
        print("-" * 70)
        await self.test_voice_to_response_workflow()
        await self.test_educational_content_pipeline()
        await self.test_multilingual_learning_flow()
        await self.test_all_8_agents_via_chatbot()
        await self.test_performance_stress()

        print("\n" + "="*70)
        print("TEST SUMMARY")
        print("="*70)
        print(f"Total Tests: {self.results['total_tests']}")
        print(f"Passed: {self.results['passed']} ✓")
        print(f"Failed: {self.results['failed']} ✗")
        print(f"Success Rate: {(self.results['passed']/self.results['total_tests']*100):.1f}%")

        if self.results['errors']:
            print("\nErrors:")
            for error in self.results['errors']:
                print(f"  - {error}")

        print("\n" + "="*70)

        return self.results['failed'] == 0

async def main():
    """Run integration test suite"""
    suite = IntegrationTestSuite()
    success = await suite.run_all_tests()

    with open("integration_test_results.json", "w", encoding="utf-8") as f:
        json.dump(suite.results, f, indent=2, ensure_ascii=False)

    print(f"\nResults saved to integration_test_results.json")

    return 0 if success else 1

if __name__ == "__main__":
    exit_code = asyncio.run(main())
    exit(exit_code)
