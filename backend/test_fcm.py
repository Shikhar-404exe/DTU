"""
Test FCM service configuration
"""
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from services.fcm_service import fcm_service

def test_fcm_service():
    """Test FCM service initialization"""
    print("=" * 60)
    print("FCM Service Configuration Test")
    print("=" * 60)

    if fcm_service.credentials:
        print("✅ FCM credentials loaded successfully")
        print(f"   Project ID: {fcm_service.project_id}")
        print(f"   Service Account: Configured")
    else:
        print("❌ FCM credentials NOT loaded")
        print("\n📋 To fix this, you need to:")
        print("   1. Download service account JSON from Firebase Console:")
        print("      https://console.firebase.google.com/project/sih-2025-4e10d/settings/serviceaccounts/adminsdk")
        print("   2. Click 'Generate new private key'")
        print("   3. Save the file as: sih-2025-4e10d-firebase-adminsdk-fbsvc-29121330f3.json")
        print("   4. Place it in: C:\\Users\\shash\\Desktop\\SIH2025\\backend\\")
        print("\n   Alternative locations checked:")
        possible_paths = [
            os.path.join(os.path.dirname(__file__), 'sih-2025-4e10d-firebase-adminsdk-fbsvc-29121330f3.json'),
            'sih-2025-4e10d-firebase-adminsdk-fbsvc-29121330f3.json',
            os.path.join('backend', 'sih-2025-4e10d-firebase-adminsdk-fbsvc-29121330f3.json')
        ]
        for path in possible_paths:
            abs_path = os.path.abspath(path)
            exists = "✅" if os.path.exists(path) else "❌"
            print(f"   {exists} {abs_path}")

    print("\n" + "=" * 60)
    print("Configuration Details:")
    print("=" * 60)
    print(f"Firebase Project ID: sih-2025-4e10d")
    print(f"Sender ID: 810050677328")
    print(f"Service Status: {'Ready' if fcm_service.credentials else 'Not Configured'}")
    print("=" * 60)

if __name__ == "__main__":
    test_fcm_service()
