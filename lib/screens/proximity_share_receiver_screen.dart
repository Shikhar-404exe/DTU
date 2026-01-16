

library;

import 'package:flutter/material.dart';
import 'dart:async';

import '../models/note.dart';
import '../services/proximity_share_service.dart';

class ProximityShareReceiverScreen extends StatefulWidget {
  const ProximityShareReceiverScreen({super.key});

  @override
  State<ProximityShareReceiverScreen> createState() =>
      _ProximityShareReceiverScreenState();
}

class _ProximityShareReceiverScreenState
    extends State<ProximityShareReceiverScreen> {
  final ProximityShareService _shareService = ProximityShareService();

  ProximityShareState _state = ProximityShareState.idle;
  List<ProximityDevice> _availableDevices = [];
  final List<Note> _receivedNotes = [];
  String? _errorMessage;
  bool _isInitialized = false;

  StreamSubscription? _stateSubscription;
  StreamSubscription? _devicesSubscription;
  StreamSubscription? _notesSubscription;
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
        setState(() => _availableDevices = devices);
      }
    });

    _notesSubscription = _shareService.receivedNotesStream.listen((note) {
      if (mounted) {
        setState(() => _receivedNotes.insert(0, note));
        _showNoteReceived(note);
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

  Future<void> _startDiscovery() async {
    setState(() {
      _errorMessage = null;
      _availableDevices.clear();
    });

    final success = await _shareService.startReceiving();
    if (!success) {
      _showError('Failed to start discovery');
    }
  }

  Future<void> _connectToDevice(ProximityDevice device) async {
    final success = await _shareService.connectToDevice(device);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${device.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showError('Failed to connect to ${device.name}');
    }
  }

  void _showNoteReceived(Note note) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Note Received!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    note.topic,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {

          },
        ),
      ),
    );
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
    _notesSubscription?.cancel();
    _errorSubscription?.cancel();
    _shareService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Notes - Student Mode'),
        backgroundColor: Colors.green,
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

          _buildStatusCard(),
          const SizedBox(height: 20),

          if (_state == ProximityShareState.idle ||
              _state == ProximityShareState.ready)
            _buildInstructions(),

          if (_state == ProximityShareState.discovering) ...[
            _buildAvailableDevices(),
            const SizedBox(height: 20),
          ],

          if (_receivedNotes.isNotEmpty) ...[
            _buildReceivedNotes(),
            const SizedBox(height: 20),
          ],

          _buildActionButton(),

          const SizedBox(height: 20),
          _buildStatistics(),
        ],
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
          'icon': Icons.radar,
          'title': 'Ready to Discover',
          'subtitle': 'Tap "Start Discovery" to find teachers',
          'color': Colors.blue,
        };
      case ProximityShareState.discovering:
        return {
          'icon': Icons.search,
          'title': 'Searching for Teachers',
          'subtitle': '${_availableDevices.length} device(s) found',
          'color': Colors.green,
        };
      case ProximityShareState.transferring:
        return {
          'icon': Icons.download,
          'title': 'Receiving Note...',
          'subtitle': 'Please wait',
          'color': Colors.orange,
        };
      case ProximityShareState.completed:
        return {
          'icon': Icons.check_circle,
          'title': 'Notes Received',
          'subtitle': '${_receivedNotes.length} note(s) downloaded',
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

  Widget _buildInstructions() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'How to Receive Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInstructionStep('1', 'Turn on Bluetooth and WiFi'),
            _buildInstructionStep('2', 'Tap "Start Discovery" below'),
            _buildInstructionStep('3', 'Wait for teacher to appear'),
            _buildInstructionStep(
                '4', 'Connect and receive notes automatically'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Both Bluetooth and WiFi work simultaneously for best coverage',
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

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.blue,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableDevices() {
    if (_availableDevices.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(
                Icons.search_off,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Teachers Found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Make sure your teacher has started broadcasting',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Available Teachers (${_availableDevices.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ..._availableDevices.map((device) => ListTile(
                  leading: Icon(
                    device.mode == ShareMode.bluetooth
                        ? Icons.bluetooth
                        : Icons.wifi,
                    color: Colors.blue,
                  ),
                  title: Text(device.name),
                  subtitle: Text(
                    device.mode == ShareMode.bluetooth
                        ? 'Bluetooth Connection'
                        : 'WiFi Connection',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _connectToDevice(device),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Connect'),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedNotes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.download_done, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Received Notes (${_receivedNotes.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ..._receivedNotes.take(5).map((note) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.note, color: Colors.blue),
                  title: Text(note.topic),
                  subtitle: Text(
                    '${note.subject} • ${_formatDateTime(note.createdAt)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (note.quizMetadata != null)
                        const Icon(Icons.quiz, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {

                    _showNoteDetails(note);
                  },
                )),
            if (_receivedNotes.length > 5) ...[
              const Divider(),
              Center(
                child: TextButton(
                  onPressed: () {

                  },
                  child: Text('View all ${_receivedNotes.length} notes'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showNoteDetails(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note.topic),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                note.subject,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              Text(note.content),
              if (note.quizMetadata != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.quiz, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${note.quizMetadata!.questionTemplates.length} quiz questions available',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note saved to library'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_state == ProximityShareState.idle ||
        _state == ProximityShareState.ready) {
      return ElevatedButton.icon(
        onPressed: _startDiscovery,
        icon: const Icon(Icons.radar),
        label: const Text('Start Discovery'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
        ),
      );
    }

    if (_state == ProximityShareState.discovering ||
        _state == ProximityShareState.completed) {
      return OutlinedButton.icon(
        onPressed: () => _shareService.stop(),
        icon: const Icon(Icons.stop),
        label: const Text('Stop Discovery'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.all(16),
        ),
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
            _buildStatRow('Available Devices', '${_availableDevices.length}'),
            _buildStatRow('Received Notes', '${_receivedNotes.length}'),
            _buildStatRow('Bluetooth Active',
                stats['bluetooth_devices'] > 0 ? 'Yes' : 'No'),
            _buildStatRow(
                'WiFi Active', stats['wifi_active'] == true ? 'Yes' : 'No'),
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
