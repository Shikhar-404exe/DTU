

library;

import 'package:flutter/material.dart';
import '../services/agent_service.dart';
import '../services/tools_service.dart';
import '../main.dart';

class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _selectedAgentId;
  String? _selectedToolId;

  Map<String, dynamic>? _orchestratorStats;

  AgentResponse? _lastAgentResponse;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrchestratorStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrchestratorStats() async {
    setState(() => _isLoading = true);
    final stats = await AgentService.getOrchestratorStats();
    setState(() {
      _orchestratorStats = stats;
      _isLoading = false;
    });
  }

  Future<void> _testAgent(String agentId, String query) async {
    setState(() => _isLoading = true);
    final response = await AgentService.processWithAgent(
      agentId: agentId,
      query: query,
    );
    setState(() {
      _lastAgentResponse = response;
      _isLoading = false;
    });

    if (mounted) {
      _showResultDialog(
        title: 'Agent Response',
        content: response.response ?? response.error ?? 'No response',
        agentName: response.agentName ?? agentId,
        mode: response.mode ?? 'unknown',
      );
    }
  }

  void _showResultDialog({
    required String title,
    required String content,
    String? agentName,
    String? mode,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.smart_toy, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (agentName != null) ...[
                _buildInfoChip('Agent', agentName, Icons.psychology),
                const SizedBox(height: 8),
              ],
              if (mode != null) ...[
                _buildInfoChip(
                    'Mode', mode.toUpperCase(), Icons.cloud_outlined),
                const SizedBox(height: 12),
              ],
              const Text('Response:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(content),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Multi-Agent System'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.deepOrange,
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.grey.shade600,
            tabs: const [
              Tab(icon: Icon(Icons.psychology), text: 'Agents (9)'),
              Tab(icon: Icon(Icons.build), text: 'Tools (3)'),
              Tab(icon: Icon(Icons.analytics), text: 'Demo'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAgentsTab(),
            _buildToolsTab(),
            _buildDemoTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentsTab() {
    final agents = AgentService.getRegisteredAgents();

    return Column(
      children: [

        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepOrange.shade400, Colors.orange.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.deepOrange.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.psychology, color: Colors.white, size: 32),
                  SizedBox(width: 12),
                  Text(
                    '9 AI Agents',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Multi-Agent Orchestration System',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatBadge(
                      'Critical',
                      AgentService.getAgentsByPriority(AgentPriority.critical)
                          .length
                          .toString()),
                  _buildStatBadge(
                      'High',
                      AgentService.getAgentsByPriority(AgentPriority.high)
                          .length
                          .toString()),
                  _buildStatBadge(
                      'Medium',
                      AgentService.getAgentsByPriority(AgentPriority.medium)
                          .length
                          .toString()),
                  _buildStatBadge('Offline',
                      AgentService.getCriticalAgents().length.toString()),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: agents.length,
            itemBuilder: (context, index) {
              final agent = agents[index];
              return _buildAgentCard(agent, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(AgentInfo agent, int number) {
    final isSelected = _selectedAgentId == agent.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Colors.deepOrange.shade400, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => setState(() {
          _selectedAgentId = isSelected ? null : agent.id;
        }),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [

                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(agent.priority),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#$number',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agent.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            _buildMiniChip(
                              agent.priority.name,
                              _getPriorityColor(agent.priority),
                            ),
                            const SizedBox(width: 6),
                            _buildMiniChip(
                              agent.defaultMode.value.toUpperCase(),
                              _getModeColor(agent.defaultMode),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: () => _showAgentTestDialog(agent),
                    icon: const Icon(Icons.play_arrow_rounded),
                    color: Colors.deepOrange,
                    tooltip: 'Test Agent',
                  ),
                ],
              ),

              if (isSelected) ...[
                const SizedBox(height: 12),
                Text(
                  agent.description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Capabilities:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: agent.capabilities.map((cap) {
                    return Chip(
                      label: Text(
                        cap.value.replaceAll('_', ' '),
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.blue.shade50,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getPriorityColor(AgentPriority priority) {
    switch (priority) {
      case AgentPriority.critical:
        return Colors.red.shade600;
      case AgentPriority.high:
        return Colors.orange.shade600;
      case AgentPriority.medium:
        return Colors.blue.shade600;
      case AgentPriority.low:
        return Colors.grey.shade600;
    }
  }

  Color _getModeColor(AgentMode mode) {
    switch (mode) {
      case AgentMode.offline:
        return Colors.green.shade600;
      case AgentMode.online:
        return Colors.blue.shade600;
      case AgentMode.auto:
        return Colors.purple.shade600;
    }
  }

  void _showAgentTestDialog(AgentInfo agent) {
    final controller = TextEditingController();

    switch (agent.id) {
      case 'offline_knowledge':
        controller.text = 'How do I use this app?';
        break;
      case 'study_assistant':
        controller.text = 'Explain photosynthesis';
        break;
      case 'voice_interface':
        controller.text = 'Read this text aloud';
        break;
      case 'language_support':
        controller.text = 'Translate hello to Hindi';
        break;
      case 'assessment':
        controller.text = 'Generate a quiz on Science';
        break;
      case 'content_discovery':
        controller.text = 'Find videos about algebra';
        break;
      case 'study_path_planner':
        controller.text = 'Create study plan for Mathematics';
        break;
      case 'accessibility':
        controller.text = 'Enable high contrast mode';
        break;
      case 'offline_photomath':
        controller.text = 'Solve 2x + 5 = 15';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.psychology, color: _getPriorityColor(agent.priority)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Test ${agent.name}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              agent.description,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Test Query',
                hintText: 'Enter a test query...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _testAgent(agent.id, controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Run Test'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsTab() {
    final tools = ToolsService.getRegisteredTools();

    return Column(
      children: [

        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.cyan.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.build, color: Colors.white, size: 32),
                  SizedBox(width: 12),
                  Text(
                    '3 Custom Tools',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Purpose-Built Tools for Rural Education',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];
              return _buildToolCard(tool, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolCard(ToolInfo tool, int number) {
    final isSelected = _selectedToolId == tool.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Colors.blue.shade400, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => setState(() {
          _selectedToolId = isSelected ? null : tool.id;
        }),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [

                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '#$number',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tool.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            if (tool.supportsOffline)
                              _buildMiniChip('OFFLINE', Colors.green.shade600),
                            const SizedBox(width: 6),
                            _buildMiniChip(
                                'v${tool.version}', Colors.grey.shade600),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    isSelected ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),

              if (isSelected) ...[
                const SizedBox(height: 12),
                Text(
                  tool.description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Capabilities:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tool.capabilities.map((cap) {
                    return Chip(
                      label: Text(
                        cap.value.replaceAll('_', ' '),
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.cyan.shade50,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          _buildComplianceCard(),
          const SizedBox(height: 16),

          _buildArchitectureCard(),
          const SizedBox(height: 16),

          _buildQuickTestPanel(),
        ],
      ),
    );
  }

  Widget _buildComplianceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle,
                      color: Colors.green.shade700, size: 28),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Hackathon Criteria Met',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildRequirementRow(
              icon: Icons.psychology,
              title: 'Multi-Agent System',
              requirement: 'Minimum 6 agents required',
              actual: '${AgentService.agentCount} agents implemented',
              met: AgentService.agentCount >= 6,
            ),
            const Divider(height: 24),

            _buildRequirementRow(
              icon: Icons.build,
              title: 'Custom Tools',
              requirement: 'Minimum 3 tools required',
              actual: '${ToolsService.toolCount} tools implemented',
              met: ToolsService.toolCount >= 3,
            ),
            const Divider(height: 24),

            _buildRequirementRow(
              icon: Icons.auto_awesome,
              title: 'Agentic Automation',
              requirement: 'Agent orchestration required',
              actual: 'Central orchestrator with auto-routing',
              met: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementRow({
    required IconData icon,
    required String title,
    required String requirement,
    required String actual,
    required bool met,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: met ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: met ? Colors.green.shade700 : Colors.red.shade700,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    met ? Icons.check_circle : Icons.cancel,
                    color: met ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                requirement,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              Text(
                actual,
                style: TextStyle(
                  color: met ? Colors.green.shade700 : Colors.red.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArchitectureCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_tree, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'System Architecture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '👤 User Query',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.arrow_downward,
                      size: 30, color: Colors.grey),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🧠 Agent Orchestrator',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.arrow_downward,
                      size: 30, color: Colors.grey),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(9, (i) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Agent ${i + 1}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.sync_alt, size: 24, color: Colors.grey),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(3, (i) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Tool ${i + 1}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTestPanel() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.science, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Quick Tests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTestButton(
                  'Test Knowledge Search',
                  Icons.search,
                  () => _testAgent(
                      'offline_knowledge', 'How do I scan documents?'),
                ),
                _buildTestButton(
                  'Test Study Assistant',
                  Icons.school,
                  () =>
                      _testAgent('study_assistant', 'What is photosynthesis?'),
                ),
                _buildTestButton(
                  'Test Assessment',
                  Icons.quiz,
                  () => _testAgent('assessment', 'Generate math quiz'),
                ),
                _buildTestButton(
                  'Test PhotoMath',
                  Icons.calculate,
                  () => _testAgent('offline_photomath', 'Solve x^2 - 4 = 0'),
                ),
              ],
            ),

            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
