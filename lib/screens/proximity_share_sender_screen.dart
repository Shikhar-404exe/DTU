/// Proximity Share Sender Screen (Teacher Mode)
/// Teacher broadcasts notes to entire class via Bluetooth/WiFi
library;

import 'package:flutter/material.dart';
import 'dart:async';

import '../models/note.dart';
import '../services/proximity_share_service.dart';

class ProximityShareSenderScreen extends StatefulWidget {
  final Note note;

  const ProximityShareSenderScreen({
    super.key,
    required this.note,
  });

  @override
  State<ProximityShareSenderScreen> createState() =>
      _ProximityShareSenderScreenState();
}

class _ProximityShareSenderScreenState
    extends State<ProximityShareSenderScreen> {
  final ProximityShareService _shareService = ProximityShareService();

  ProximityShareState _state = ProximityShareState.idle;
  List<ProximityDevice> _connectedDevices = [];
  String? _errorMessage;
  bool _isInitialized = false;
  int _sentCount = 0;

  StreamSubscription? _stateSubscription;
  StreamSubscription? _devicesSubscription;
  StreamSubscription? _errorSubscription;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    _stateSubscription = _shareService.stateStream.listen((state) {
      if (mounted) {
        setState(() => _state = state);
      }
    });

    _devicesSubscription = _shareService.devicesStream.listen((devices) {
      if (mounted) {
        setState(() {
          _connectedDevices = devices.where((d) => d.isAvailable).toList();
        });
      }
    });

    _errorSubscription = _shareService.errorStream.listen((error) {
      if (mounted) {
        setState(() => _errorMessage = error);
        _showError(error);
      }
    });

    final success = await _shareService.initialize();
    setState(() => _isInitialized = success);

    if (!success) {
      _showError('Failed to initialize. Please check permissions.');
    }
  }

  Future<void> _startBroadcasting() async {
    setState(() {
      _errorMessage = null;
      _sentCount = 0;
    });

    final success = await _shareService.startSending();
    if (!success) {
      _showError('Failed to start broadcasting');
    }
  }

  Future<void> _sendNote() async {
    if (_connectedDevices.isEmpty) {
      _showError('No devices connected. Wait for students to connect.');
      return;
    }

    setState(() => _sentCount = 0);

    await _shareService.sendNoteToAll(widget.note);

    if (mounted) {
      setState(() => _sentCount = _connectedDevices.length);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Note sent to $_sentCount device(s)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _devicesSubscription?.cancel();
    _errorSubscription?.cancel();
    _shareService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Notes - Teacher Mode'),
        backgroundColor: Colors.blue,
      ),
      body: _isInitialized ? _buildContent() : _buildLoading(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Initializing proximity sharing...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Note preview
          _buildNotePreview(),
          const SizedBox(height: 20),

          // Status card
          _buildStatusCard(),
          const SizedBox(height: 20),

          // Connection info (WiFi SSID/Password)
          if (_state == ProximityShareState.broadcasting)
            _buildConnectionInfo(),

          // Connected devices list
          if (_connectedDevices.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildDevicesList(),
          ],

          const SizedBox(height: 20),

          // Action buttons
          _buildActionButtons(),

          // Statistics
          const SizedBox(height: 20),
          _buildStatistics(),
        ],
      ),
    );
  }

  Widget _buildNotePreview() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.note.topic,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.note.subject,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Text(
              widget.note.content.length > 150
                  ? '${widget.note.content.substring(0, 150)}...'
                  : widget.note.content,
              style: const TextStyle(fontSize: 14),
            ),
            if (widget.note.quizMetadata != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.quiz, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.note.quizMetadata!.questionTemplates.length} quiz questions included',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final statusInfo = _getStatusInfo();

    return Card(
      color: statusInfo['color'] as Color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              statusInfo['icon'] as IconData,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusInfo['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusInfo['subtitle'] as String,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo() {
    switch (_state) {
      case ProximityShareState.idle:
      case ProximityShareState.ready:
        return {
          'icon': Icons.play_circle_outline,
          'title': 'Ready to Share',
          'subtitle': 'Tap "Start Broadcasting" to begin',
          'color': Colors.blue,
        };
      case ProximityShareState.broadcasting:
        return {
          'icon': Icons.broadcast_on_personal,
          'title': 'Broadcasting Active',
          'subtitle': '${_connectedDevices.length} student(s) connected',
          'color': Colors.green,
        };
      case ProximityShareState.transferring:
        return {
          'icon': Icons.sync,
          'title': 'Sending Note...',
          'subtitle': 'Please wait',
          'color': Colors.orange,
        };
      case ProximityShareState.completed:
        return {
          'icon': Icons.check_circle,
          'title': 'Note Sent Successfully',
          'subtitle': 'Sent to $_sentCount device(s)',
          'color': Colors.green,
        };
      case ProximityShareState.error:
        return {
          'icon': Icons.error,
          'title': 'Error',
          'subtitle': _errorMessage ?? 'Something went wrong',
          'color': Colors.red,
        };
      default:
        return {
          'icon': Icons.hourglass_empty,
          'title': 'Initializing...',
          'subtitle': 'Please wait',
          'color': Colors.grey,
        };
    }
  }

  Widget _buildConnectionInfo() {
    final stats = _shareService.getStatistics();
    final wifiSsid = stats['wifi_ssid'] as String?;

    if (wifiSsid == null) return const SizedBox.shrink();

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.wifi, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'WiFi Connection Info',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Students should connect to this WiFi:',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Network Name (SSID)', wifiSsid),
            const SizedBox(height: 8),
            _buildInfoRow('Password', '(Auto-generated)'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Students can also use Bluetooth if WiFi is unavailable',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          ': $value',
          style: const TextStyle(color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildDevicesList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.devices, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Connected Students (${_connectedDevices.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ..._connectedDevices.map((device) => ListTile(
                  dense: true,
                  leading: Icon(
                    device.mode == ShareMode.bluetooth
                        ? Icons.bluetooth
                        : Icons.wifi,
                    color: Colors.green,
                  ),
                  title: Text(device.name),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_state == ProximityShareState.idle ||
        _state == ProximityShareState.ready) {
      return ElevatedButton.icon(
        onPressed: _startBroadcasting,
        icon: const Icon(Icons.broadcast_on_personal),
        label: const Text('Start Broadcasting'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
        ),
      );
    }

    if (_state == ProximityShareState.broadcasting ||
        _state == ProximityShareState.completed) {
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: _connectedDevices.isEmpty ? null : _sendNote,
            icon: const Icon(Icons.send),
            label: Text(
              _connectedDevices.isEmpty
                  ? 'Waiting for Students...'
                  : 'Send Note to All (${_connectedDevices.length})',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              disabledBackgroundColor: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _shareService.stop(),
            icon: const Icon(Icons.stop),
            label: const Text('Stop Broadcasting'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatistics() {
    final stats = _shareService.getStatistics();

    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow('Bluetooth Devices', '${stats['bluetooth_devices']}'),
            _buildStatRow(
                'Bluetooth Connected', '${stats['bluetooth_connected']}'),
            _buildStatRow(
                'WiFi Active', stats['wifi_active'] == true ? 'Yes' : 'No'),
            _buildStatRow('Notes Sent', '$_sentCount'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
