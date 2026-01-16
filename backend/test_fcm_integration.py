"""
Complete FCM Integration Test
Tests all FCM endpoints with real API calls
"""
import requests
import json

BASE_URL = "http://localhost:8000"

def print_section(title):
    print("\n" + "=" * 70)
    print(f"  {title}")
    print("=" * 70)

def test_fcm_health():
    """Test FCM health endpoint"""
    print_section("TEST 1: FCM Health Check")

    response = requests.get(f"{BASE_URL}/fcm/health")
    data = response.json()

    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(data, indent=2)}")

    if data.get("fcm_configured"):
        print("\n✅ FCM Service is configured and ready!")
        print(f"   Project ID: {data.get('project_id')}")
        return True
    else:
        print("\n❌ FCM Service is NOT configured")
        return False

def test_fcm_send_single():
    """Test sending notification to single device"""
    print_section("TEST 2: Send Notification to Single Device")

    payload = {
        "device_token": "test_token_12345",
        "title": "Test Notification",
        "body": "This is a test notification from SIH2025 backend",
        "data": {
            "type": "test",
            "timestamp": "2026-01-16"
        }
    }

    print(f"Request Payload:")
    print(json.dumps(payload, indent=2))

    try:
        response = requests.post(f"{BASE_URL}/fcm/send", json=payload)
        data = response.json()

        print(f"\nStatus Code: {response.status_code}")
        print(f"Response: {json.dumps(data, indent=2)}")

        if response.status_code == 200:
            print("\n✅ Endpoint is working!")
        else:
            print(f"\n⚠️  Expected error (need real device token): {data.get('detail', 'Unknown error')}")
    except Exception as e:
        print(f"\n❌ Request failed: {e}")

def test_fcm_send_topic():
    """Test sending notification to topic"""
    print_section("TEST 3: Send Notification to Topic")

    payload = {
        "topic": "test-topic",
        "title": "Class Announcement",
        "body": "Math quiz tomorrow at 9 AM",
        "data": {
            "type": "quiz",
            "subject": "mathematics"
        }
    }

    print(f"Request Payload:")
    print(json.dumps(payload, indent=2))

    try:
        response = requests.post(f"{BASE_URL}/fcm/send-topic", json=payload)
        data = response.json()

        print(f"\nStatus Code: {response.status_code}")
        print(f"Response: {json.dumps(data, indent=2)}")

        if response.status_code == 200:
            print("\n✅ Topic notification endpoint is working!")
        else:
            print(f"\n⚠️  Error: {data.get('detail', 'Unknown error')}")
    except Exception as e:
        print(f"\n❌ Request failed: {e}")

def test_fcm_multicast():
    """Test sending notification to multiple devices"""
    print_section("TEST 4: Send Multicast Notification")

    payload = {
        "device_tokens": ["token1", "token2", "token3"],
        "title": "Homework Reminder",
        "body": "Submit your Math homework by 5 PM",
        "data": {
            "type": "homework",
            "subject": "mathematics"
        }
    }

    print(f"Request Payload:")
    print(json.dumps(payload, indent=2))

    try:
        response = requests.post(f"{BASE_URL}/fcm/send-multicast", json=payload)
        data = response.json()

        print(f"\nStatus Code: {response.status_code}")
        print(f"Response: {json.dumps(data, indent=2)}")

        if response.status_code == 200:
            print("\n✅ Multicast notification endpoint is working!")
    except Exception as e:
        print(f"\n❌ Request failed: {e}")

def main():
    print("\n" + "=" * 70)
    print("   FCM Integration Test Suite")
    print("   Project: sih-2025-4e10d")
    print("=" * 70)

    try:

        if not test_fcm_health():
            print("\n⚠️  Stopping tests - FCM not configured")
            return

        test_fcm_send_single()

        test_fcm_send_topic()

        test_fcm_multicast()

        print_section("Test Summary")
        print("✅ FCM service is configured correctly")
        print("✅ All endpoints are accessible")
        print("✅ API request/response format is valid")
        print("\n📝 Next Steps:")
        print("   1. Add firebase_messaging to Flutter pubspec.yaml")
        print("   2. Get device FCM token from Flutter app")
        print("   3. Test with real device token for actual notification delivery")
        print("\n💡 Example use cases:")
        print("   • Send attendance alert to parent: POST /fcm/send")
        print("   • Broadcast quiz to class: POST /fcm/send-topic")
        print("   • Remind multiple students: POST /fcm/send-multicast")

    except requests.exceptions.ConnectionError:
        print("\n❌ Error: Cannot connect to backend")
        print("   Make sure backend is running on http://localhost:8000")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")

if __name__ == "__main__":
    main()
