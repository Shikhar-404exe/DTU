"""
Firebase Cloud Messaging (FCM) Service
Send push notifications using FCM HTTP v1 API with service account authentication
"""

import os
import json
import logging
from typing import Dict, Any, List, Optional
from google.oauth2 import service_account
from google.auth.transport.requests import Request
import requests

logger = logging.getLogger(__name__)

class FCMService:
    """Firebase Cloud Messaging service for sending push notifications"""

    def __init__(self):
        """Initialize FCM service with service account credentials"""

        possible_paths = [
            os.path.join(os.path.dirname(__file__), '..', 'sih-2025-4e10d-firebase-adminsdk-fbsvc-29121330f3.json'),
            'sih-2025-4e10d-firebase-adminsdk-fbsvc-29121330f3.json',
            os.path.join('backend', 'sih-2025-4e10d-firebase-adminsdk-fbsvc-29121330f3.json')
        ]

        service_account_path = None
        for path in possible_paths:
            if os.path.exists(path):
                service_account_path = path
                break

        if not service_account_path:
            logger.warning("Firebase service account JSON not found. FCM notifications will not work.")
            self.credentials = None
            self.project_id = None
            return

        try:

            self.credentials = service_account.Credentials.from_service_account_file(
                service_account_path,
                scopes=['https://www.googleapis.com/auth/firebase.messaging']
            )

            with open(service_account_path, 'r') as f:
                service_account_info = json.load(f)
                self.project_id = service_account_info.get('project_id')

            logger.info(f"FCM service initialized successfully for project: {self.project_id}")

        except Exception as e:
            logger.error(f"Failed to initialize FCM service: {e}")
            self.credentials = None
            self.project_id = None

    def _get_access_token(self) -> Optional[str]:
        """Get OAuth2 access token for FCM API"""
        if not self.credentials:
            return None

        try:

            if not self.credentials.valid:
                self.credentials.refresh(Request())

            return self.credentials.token
        except Exception as e:
            logger.error(f"Failed to get access token: {e}")
            return None

    def send_notification(
        self,
        device_token: str,
        title: str,
        body: str,
        data: Optional[Dict[str, str]] = None,
        image_url: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Send notification to a single device

        Args:
            device_token: FCM device token
            title: Notification title
            body: Notification body text
            data: Optional custom data payload
            image_url: Optional image URL for rich notification

        Returns:
            Response dict with success status and message
        """
        if not self.credentials or not self.project_id:
            return {
                "success": False,
                "error": "FCM service not initialized. Service account file missing."
            }

        access_token = self._get_access_token()
        if not access_token:
            return {
                "success": False,
                "error": "Failed to get access token"
            }

        message = {
            "message": {
                "token": device_token,
                "notification": {
                    "title": title,
                    "body": body
                }
            }
        }

        if image_url:
            message["message"]["notification"]["image"] = image_url

        if data:
            message["message"]["data"] = data

        url = f"https://fcm.googleapis.com/v1/projects/{self.project_id}/messages:send"
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }

        try:
            response = requests.post(url, headers=headers, json=message, timeout=10)

            if response.status_code == 200:
                logger.info(f"Notification sent successfully to device")
                return {
                    "success": True,
                    "message": "Notification sent successfully",
                    "response": response.json()
                }
            else:
                logger.error(f"FCM API error: {response.status_code} - {response.text}")
                return {
                    "success": False,
                    "error": f"FCM API error: {response.status_code}",
                    "details": response.text
                }

        except Exception as e:
            logger.error(f"Failed to send notification: {e}")
            return {
                "success": False,
                "error": str(e)
            }

    def send_to_topic(
        self,
        topic: str,
        title: str,
        body: str,
        data: Optional[Dict[str, str]] = None,
        image_url: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Send notification to all devices subscribed to a topic

        Args:
            topic: Topic name (e.g., "class-10-A", "parents", "teachers")
            title: Notification title
            body: Notification body text
            data: Optional custom data payload
            image_url: Optional image URL

        Returns:
            Response dict with success status
        """
        if not self.credentials or not self.project_id:
            return {
                "success": False,
                "error": "FCM service not initialized"
            }

        access_token = self._get_access_token()
        if not access_token:
            return {
                "success": False,
                "error": "Failed to get access token"
            }

        message = {
            "message": {
                "topic": topic,
                "notification": {
                    "title": title,
                    "body": body
                }
            }
        }

        if image_url:
            message["message"]["notification"]["image"] = image_url

        if data:
            message["message"]["data"] = data

        url = f"https://fcm.googleapis.com/v1/projects/{self.project_id}/messages:send"
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }

        try:
            response = requests.post(url, headers=headers, json=message, timeout=10)

            if response.status_code == 200:
                logger.info(f"Notification sent to topic: {topic}")
                return {
                    "success": True,
                    "message": f"Notification sent to topic: {topic}",
                    "response": response.json()
                }
            else:
                logger.error(f"FCM topic error: {response.status_code} - {response.text}")
                return {
                    "success": False,
                    "error": f"FCM API error: {response.status_code}",
                    "details": response.text
                }

        except Exception as e:
            logger.error(f"Failed to send topic notification: {e}")
            return {
                "success": False,
                "error": str(e)
            }

    def send_multicast(
        self,
        device_tokens: List[str],
        title: str,
        body: str,
        data: Optional[Dict[str, str]] = None
    ) -> Dict[str, Any]:
        """
        Send notification to multiple devices (up to 500 devices)

        Args:
            device_tokens: List of FCM device tokens
            title: Notification title
            body: Notification body
            data: Optional custom data

        Returns:
            Response with success/failure counts
        """
        if not device_tokens:
            return {"success": False, "error": "No device tokens provided"}

        results = {
            "success_count": 0,
            "failure_count": 0,
            "results": []
        }

        for token in device_tokens[:500]:
            result = self.send_notification(token, title, body, data)
            results["results"].append({
                "token": token[:20] + "...",
                "success": result.get("success", False)
            })

            if result.get("success"):
                results["success_count"] += 1
            else:
                results["failure_count"] += 1

        results["success"] = results["success_count"] > 0
        return results

fcm_service = FCMService()
