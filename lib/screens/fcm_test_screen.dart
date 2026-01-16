import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/fcm_service.dart';

class FCMTestScreen extends StatefulWidget {
  const FCMTestScreen({super.key});

  @override
  State<FCMTestScreen> createState() => _FCMTestScreenState();
}

class _FCMTestScreenState extends State<FCMTestScreen> {
  final FCMService _fcmService = FCMService();
  String? _fcmToken;
  bool _isLoading = true;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
  }

  Future<void> _loadFCMToken() async {
    setState(() => _isLoading = true);

    try {

      final token = _fcmService.fcmToken ?? await _fcmService.getSavedToken();
      final enabled = await _fcmService.areNotificationsEnabled();

      setState(() {
        _fcmToken = token;
        _notificationsEnabled = enabled;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading FCM token: $e')),
        );
      }
    }
  }

  void _copyToken() {
    if (_fcmToken != null) {
      Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ FCM Token copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _subscribeToTopic() async {
    try {
      await _fcmService.subscribeToTopic('test-topic');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Subscribed to "test-topic"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  Future<void> _unsubscribeFromTopic() async {
    try {
      await _fcmService.unsubscribeFromTopic('test-topic');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Unsubscribed from "test-topic"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Test Screen'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _notificationsEnabled
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: _notificationsEnabled
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'FCM Status',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _notificationsEnabled
                                ? '✅ Notifications Enabled'
                                : '❌ Notifications Disabled',
                            style: TextStyle(
                              color: _notificationsEnabled
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'FCM Token',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed:
                                    _fcmToken != null ? _copyToken : null,
                                tooltip: 'Copy token',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_fcmToken != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SelectableText(
                                _fcmToken!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            )
                          else
                            const Text('No token available'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Topic Subscription',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Subscribe to topics to receive broadcast notifications',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _subscribeToTopic,
                                  icon: const Icon(Icons.add_alert),
                                  label: const Text('Subscribe to test-topic'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _unsubscribeFromTopic,
                                  icon: const Icon(Icons.remove_circle),
                                  label: const Text('Unsubscribe'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'How to Test',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.blue[900]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '1. Copy the FCM token above\n'
                            '2. Open your backend test:\n'
                            '   python backend/test_fcm_integration.py\n'
                            '3. Use the token in API calls:\n'
                            '   POST http://localhost:8000/fcm/send\n'
                            '4. Or test topic notifications:\n'
                            '   POST http://localhost:8000/fcm/send-topic',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _loadFCMToken,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Token'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
