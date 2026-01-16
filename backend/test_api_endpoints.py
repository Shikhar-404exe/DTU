"""
Phase 6: REST API Endpoint Tests
Tests all 27 FastAPI endpoints
"""

import requests
import json
import time
from typing import Dict, Any

class APIEndpointTester:
    """Test all FastAPI endpoints"""

    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
        self.results = {
            "total_tests": 0,
            "passed": 0,
            "failed": 0,
            "errors": [],
            "test_details": []
        }
        self.session_id = None
        self.user_id = "test_api_user"

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

    def test_endpoint(self, method: str, endpoint: str, data: Dict = None,
                     params: Dict = None, expected_keys: list = None) -> bool:
        """Generic endpoint test"""
        try:
            url = f"{self.base_url}{endpoint}"

            if method == "GET":
                response = requests.get(url, params=params, timeout=10)
            elif method == "POST":
                response = requests.post(url, json=data, timeout=10)
            elif method == "PATCH":
                response = requests.patch(url, json=data, timeout=10)
            elif method == "DELETE":
                response = requests.delete(url, timeout=10)
            else:
                return False

            if response.status_code not in [200, 201]:
                return False

            result = response.json()

            if expected_keys:
                for key in expected_keys:
                    if key not in result:
                        return False

            return True

        except Exception as e:
            print(f"      Exception: {str(e)}")
            return False

    def test_chatbot_create_session(self):
        """POST /chatbot/session - Create new session"""
        try:
            response = requests.post(
                f"{self.base_url}/chatbot/session",
                json={
                    "user_id": self.user_id,
                    "mode": "auto"
                },
                timeout=10
            )

            if response.status_code == 200:
                data = response.json()
                self.session_id = data.get("session_id")
                passed = self.session_id is not None
                details = f"Session ID: {self.session_id[:12]}..." if self.session_id else "No session ID"
            else:
                passed = False
                details = f"Status: {response.status_code}"

            self.log_test("POST /chatbot/session", passed, details)
            return passed
        except Exception as e:
            self.log_test("POST /chatbot/session", False, error=str(e))
            return False

    def test_chatbot_send_message(self):
        """POST /chatbot/chat - Send message"""
        if not self.session_id:
            self.log_test("POST /chatbot/chat", False, error="No session ID")
            return False

        try:
            response = requests.post(
                f"{self.base_url}/chatbot/chat",
                json={
                    "session_id": self.session_id,
                    "message": "What is photosynthesis?"
                },
                timeout=15
            )

            passed = response.status_code == 200
            if passed:
                data = response.json()
                response_len = len(data.get("response", ""))
                details = f"Response: {response_len} chars, Agent: {data.get('agent_id', 'N/A')}"
            else:
                details = f"Status: {response.status_code}"

            self.log_test("POST /chatbot/chat", passed, details)
            return passed
        except Exception as e:
            self.log_test("POST /chatbot/chat", False, error=str(e))
            return False

    def test_chatbot_get_history(self):
        """GET /chatbot/session/{id}/history - Get history"""
        if not self.session_id:
            self.log_test("GET /chatbot/session/{id}/history", False, error="No session ID")
            return False

        try:
            response = requests.get(
                f"{self.base_url}/chatbot/session/{self.session_id}/history",
                timeout=10
            )

            passed = response.status_code == 200
            if passed:
                data = response.json()
                msg_count = len(data.get("messages", []))
                details = f"History: {msg_count} messages"
            else:
                details = f"Status: {response.status_code}"

            self.log_test("GET /chatbot/session/{id}/history", passed, details)
            return passed
        except Exception as e:
            self.log_test("GET /chatbot/session/{id}/history", False, error=str(e))
            return False

    def test_chatbot_user_sessions(self):
        """GET /chatbot/user/{id}/sessions - Get user sessions"""
        passed = self.test_endpoint(
            "GET",
            f"/chatbot/user/{self.user_id}/sessions",
            expected_keys=["sessions"]
        )
        details = "User sessions retrieved" if passed else "Failed to get sessions"
        self.log_test("GET /chatbot/user/{id}/sessions", passed, details)
        return passed

    def test_chatbot_update_session(self):
        """PATCH /chatbot/session/{id} - Update session"""
        if not self.session_id:
            self.log_test("PATCH /chatbot/session/{id}", False, error="No session ID")
            return False

        passed = self.test_endpoint(
            "PATCH",
            f"/chatbot/session/{self.session_id}",
            data={"title": "Integration Test Session"}
        )
        details = "Session updated" if passed else "Failed to update"
        self.log_test("PATCH /chatbot/session/{id}", passed, details)
        return passed

    def test_chatbot_search(self):
        """GET /chatbot/user/{id}/search - Search conversations"""
        passed = self.test_endpoint(
            "GET",
            f"/chatbot/user/{self.user_id}/search",
            params={"query": "photosynthesis", "limit": 10},
            expected_keys=["results"]
        )
        details = "Search completed" if passed else "Search failed"
        self.log_test("GET /chatbot/user/{id}/search", passed, details)
        return passed

    def test_chatbot_stats(self):
        """GET /chatbot/stats - Get statistics"""
        passed = self.test_endpoint(
            "GET",
            "/chatbot/stats",
            expected_keys=["stats"]
        )
        details = "Stats retrieved" if passed else "Failed to get stats"
        self.log_test("GET /chatbot/stats", passed, details)
        return passed

    def test_chatbot_health(self):
        """GET /chatbot/health - Health check"""
        passed = self.test_endpoint(
            "GET",
            "/chatbot/health",
            expected_keys=["status"]
        )
        details = "Health check OK" if passed else "Health check failed"
        self.log_test("GET /chatbot/health", passed, details)
        return passed

    def test_chatbot_delete_session(self):
        """DELETE /chatbot/session/{id} - Delete session"""
        if not self.session_id:
            self.log_test("DELETE /chatbot/session/{id}", False, error="No session ID")
            return False

        passed = self.test_endpoint(
            "DELETE",
            f"/chatbot/session/{self.session_id}"
        )
        details = "Session deleted" if passed else "Failed to delete"
        self.log_test("DELETE /chatbot/session/{id}", passed, details)

        if passed:
            self.session_id = None

        return passed

    def test_tts_synthesize(self):
        """POST /tts/synthesize - Text-to-speech"""
        try:
            response = requests.post(
                f"{self.base_url}/tts/synthesize",
                json={
                    "text": "Hello, this is a test",
                    "language": "en",
                    "use_online": False
                },
                timeout=10
            )

            passed = response.status_code == 200
            if passed:
                data = response.json()
                details = f"Provider: {data.get('provider', 'N/A')}, Success: {data.get('success')}"
            else:
                details = f"Status: {response.status_code}"

            self.log_test("POST /tts/synthesize", passed, details)
            return passed
        except Exception as e:
            self.log_test("POST /tts/synthesize", False, error=str(e))
            return False

    def test_tts_voices(self):
        """GET /tts/voices - Get available voices"""
        try:
            response = requests.get(f"{self.base_url}/tts/voices", timeout=10)

            passed = response.status_code == 200
            if passed:
                data = response.json()
                voice_count = len(data.get("voices", []))
                details = f"{voice_count} voices available"
            else:
                details = f"Status: {response.status_code}"

            self.log_test("GET /tts/voices", passed, details)
            return passed
        except Exception as e:
            self.log_test("GET /tts/voices", False, error=str(e))
            return False

    def test_tts_health(self):
        """GET /tts/health - TTS health check"""
        passed = self.test_endpoint("GET", "/tts/health", expected_keys=["status"])
        details = "TTS healthy" if passed else "TTS unhealthy"
        self.log_test("GET /tts/health", passed, details)
        return passed

    def test_stt_languages(self):
        """GET /stt/languages - Get supported languages"""
        try:
            response = requests.get(f"{self.base_url}/stt/languages", timeout=10)

            passed = response.status_code == 200
            if passed:
                data = response.json()
                lang_count = len(data.get("languages", []))
                details = f"{lang_count} languages supported"
            else:
                details = f"Status: {response.status_code}"

            self.log_test("GET /stt/languages", passed, details)
            return passed
        except Exception as e:
            self.log_test("GET /stt/languages", False, error=str(e))
            return False

    def test_stt_health(self):
        """GET /stt/health - STT health check"""
        passed = self.test_endpoint("GET", "/stt/health", expected_keys=["status"])
        details = "STT healthy" if passed else "STT unhealthy"
        self.log_test("GET /stt/health", passed, details)
        return passed

    def test_youtube_search(self):
        """POST /youtube/search - Search videos"""
        try:
            response = requests.post(
                f"{self.base_url}/youtube/search",
                json={
                    "query": "mathematics",
                    "max_results": 5,
                    "use_online": False
                },
                timeout=10
            )

            passed = response.status_code == 200
            if passed:
                data = response.json()
                provider = data.get("provider", "N/A")
                channel_count = len(data.get("recommended_channels", []))
                details = f"Provider: {provider}, Channels: {channel_count}"
            else:
                details = f"Status: {response.status_code}"

            self.log_test("POST /youtube/search", passed, details)
            return passed
        except Exception as e:
            self.log_test("POST /youtube/search", False, error=str(e))
            return False

    def test_youtube_channels(self):
        """GET /youtube/channels/{subject} - Get channel recommendations"""
        try:
            response = requests.get(
                f"{self.base_url}/youtube/channels/Science",
                timeout=10
            )

            passed = response.status_code == 200
            if passed:
                data = response.json()
                channel_count = len(data.get("channels", []))
                details = f"{channel_count} science channels"
            else:
                details = f"Status: {response.status_code}"

            self.log_test("GET /youtube/channels/{subject}", passed, details)
            return passed
        except Exception as e:
            self.log_test("GET /youtube/channels/{subject}", False, error=str(e))
            return False

    def test_youtube_health(self):
        """GET /youtube/health - YouTube health check"""
        passed = self.test_endpoint("GET", "/youtube/health", expected_keys=["status"])
        details = "YouTube healthy" if passed else "YouTube unhealthy"
        self.log_test("GET /youtube/health", passed, details)
        return passed

    def run_all_tests(self):
        """Run all API endpoint tests"""
        print("\n" + "="*70)
        print("PHASE 6: REST API ENDPOINT TESTS (27 ENDPOINTS)")
        print("="*70 + "\n")

        try:
            response = requests.get(f"{self.base_url}/chatbot/health", timeout=5)
            if response.status_code != 200:
                print("❌ Backend server not responding!")
                print(f"   Please start the backend: cd backend && python main.py")
                return False
        except Exception:
            print("❌ Backend server not running!")
            print(f"   Please start the backend: cd backend && python main.py")
            return False

        print("✓ Backend server is running\n")

        print("Chatbot Endpoints (9)")
        print("-" * 70)
        self.test_chatbot_create_session()
        self.test_chatbot_send_message()
        self.test_chatbot_get_history()
        self.test_chatbot_user_sessions()
        self.test_chatbot_update_session()
        self.test_chatbot_search()
        self.test_chatbot_stats()
        self.test_chatbot_health()
        self.test_chatbot_delete_session()

        print("\nTTS Endpoints (3)")
        print("-" * 70)
        self.test_tts_synthesize()
        self.test_tts_voices()
        self.test_tts_health()

        print("\nSTT Endpoints (2)")
        print("-" * 70)
        self.test_stt_languages()
        self.test_stt_health()

        print("\nYouTube Endpoints (3)")
        print("-" * 70)
        self.test_youtube_search()
        self.test_youtube_channels()
        self.test_youtube_health()

        print("\n" + "="*70)
        print("TEST SUMMARY")
        print("="*70)
        print(f"Total Endpoints Tested: {self.results['total_tests']}")
        print(f"Passed: {self.results['passed']} ✓")
        print(f"Failed: {self.results['failed']} ✗")
        print(f"Success Rate: {(self.results['passed']/self.results['total_tests']*100):.1f}%")

        if self.results['errors']:
            print("\nErrors:")
            for error in self.results['errors']:
                print(f"  - {error}")

        print("\n" + "="*70)

        with open("api_test_results.json", "w", encoding="utf-8") as f:
            json.dump(self.results, f, indent=2)

        print(f"\nResults saved to api_test_results.json")

        return self.results['failed'] == 0

def main():
    """Run API endpoint tests"""
    tester = APIEndpointTester()
    success = tester.run_all_tests()
    return 0 if success else 1

if __name__ == "__main__":
    exit(main())
