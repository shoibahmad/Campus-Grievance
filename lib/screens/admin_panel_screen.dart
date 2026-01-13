import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/grievance.dart';
import '../services/firebase_service.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final AIService _aiService = AIService();
  late TabController _tabController;
  final String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final adminName = authService.currentUser?.name ?? 'Admin';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(adminName, authService),
              
              // Tab Bar
              _buildTabBar(),
              
              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllGrievancesTab(),
                    _buildPendingTab(),
                    _buildInProgressTab(),
                    _buildResolvedTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String adminName, AuthService authService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 32,
                ),
              ).animate().scale(delay: 100.ms),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Panel',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideX(),
                    Text(
                      'Welcome, $adminName',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideX(),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                color: Colors.white,
                tooltip: 'Logout',
              ).animate().scale(delay: 400.ms),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatisticsCards(),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return StreamBuilder<List<Grievance>>(
      stream: _firebaseService.getAllGrievances(),
      builder: (context, snapshot) {
        final grievances = snapshot.data ?? [];
        
        final stats = {
          'total': grievances.length,
          'pending': grievances.where((g) => g.status == 'pending').length,
          'in_progress': grievances.where((g) => g.status == 'in_progress').length,
          'resolved': grievances.where((g) => g.status == 'resolved').length,
          'critical': grievances.where((g) => g.severityScore >= 8).length,
        };

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                stats['total']!,
                Icons.list_alt,
                Colors.white,
                0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Pending',
                stats['pending']!,
                Icons.pending_outlined,
                AppTheme.warningColor,
                1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'In Progress',
                stats['in_progress']!,
                Icons.autorenew,
                AppTheme.infoColor,
                2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Resolved',
                stats['resolved']!,
                Icons.check_circle_outline,
                AppTheme.successColor,
                3,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Critical',
                stats['critical']!,
                Icons.warning_amber,
                AppTheme.errorColor,
                4,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(delay: (500 + index * 100).ms).slideY();
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surfaceColor,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primaryColor,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textTertiary,
        tabs: const [
          Tab(text: 'All', icon: Icon(Icons.list_alt, size: 20)),
          Tab(text: 'Pending', icon: Icon(Icons.pending, size: 20)),
          Tab(text: 'In Progress', icon: Icon(Icons.autorenew, size: 20)),
          Tab(text: 'Resolved', icon: Icon(Icons.check_circle, size: 20)),
        ],
      ),
    );
  }

  Widget _buildAllGrievancesTab() {
    return StreamBuilder<List<Grievance>>(
      stream: _firebaseService.getAllGrievances(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final grievances = snapshot.data ?? [];

        if (grievances.isEmpty) {
          return _buildEmptyState('No grievances yet');
        }

        return _buildGrievancesList(grievances);
      },
    );
  }

  Widget _buildPendingTab() {
    return StreamBuilder<List<Grievance>>(
      stream: _firebaseService.getGrievancesByStatus('pending'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final grievances = snapshot.data ?? [];

        if (grievances.isEmpty) {
          return _buildEmptyState('No pending grievances');
        }

        return _buildGrievancesList(grievances);
      },
    );
  }

  Widget _buildInProgressTab() {
    return StreamBuilder<List<Grievance>>(
      stream: _firebaseService.getGrievancesByStatus('in_progress'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final grievances = snapshot.data ?? [];

        if (grievances.isEmpty) {
          return _buildEmptyState('No grievances in progress');
        }

        return _buildGrievancesList(grievances);
      },
    );
  }

  Widget _buildResolvedTab() {
    return StreamBuilder<List<Grievance>>(
      stream: _firebaseService.getGrievancesByStatus('resolved'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final grievances = snapshot.data ?? [];

        if (grievances.isEmpty) {
          return _buildEmptyState('No resolved grievances');
        }

        return _buildGrievancesList(grievances);
      },
    );
  }

  Widget _buildGrievancesList(List<Grievance> grievances) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: grievances.length,
      itemBuilder: (context, index) {
        return _buildGrievanceCard(grievances[index], index);
      },
    );
  }

  Widget _buildGrievanceCard(Grievance grievance, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.getSeverityColor(grievance.severityScore).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getSeverityColor(grievance.severityScore).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showGrievanceDetails(grievance),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Severity Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.getSeverityColor(grievance.severityScore),
                            AppTheme.getSeverityColor(grievance.severityScore).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.priority_high, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Priority ${grievance.severityScore}/10',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        grievance.category,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.getStatusColor(grievance.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        grievance.status.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.getStatusColor(grievance.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  grievance.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  grievance.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // Footer
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: AppTheme.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      grievance.studentName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      grievance.location,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Icon(Icons.access_time, size: 16, color: AppTheme.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(grievance.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideY();
  }

  void _showGrievanceDetails(Grievance grievance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildGrievanceDetailsSheet(grievance),
    );
  }

  Widget _buildGrievanceDetailsSheet(Grievance grievance) {
    final statusController = TextEditingController();
    final responseController = TextEditingController(text: grievance.adminResponse);
    String selectedStatus = grievance.status;

    return StatefulBuilder(
      builder: (context, setState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Header
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Grievance Details',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // User Info Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Student Information',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(Icons.person, 'Name', grievance.studentName),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.email, 'Email', grievance.studentEmail),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.badge, 'Student ID', grievance.studentId),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Grievance Info
                        _buildDetailSection('Issue Details', [
                          _buildDetailRow('Title', grievance.title),
                          _buildDetailRow('Category', grievance.category),
                          _buildDetailRow('Location', grievance.location),
                          _buildDetailRow('Priority', '${grievance.severityScore}/10'),
                          _buildDetailRow('Status', grievance.status.toUpperCase()),
                          _buildDetailRow('Submitted', _formatDateTime(grievance.createdAt)),
                        ]),
                        
                        const SizedBox(height: 16),
                        
                        // Description
                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            grievance.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // AI Analysis
                        _buildAIAnalysisSection(grievance),
                        
                        const SizedBox(height: 24),
                        
                        // Update Status
                        Text(
                          'Update Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatusButton(
                                  'Pending',
                                  'pending',
                                  selectedStatus,
                                  AppTheme.warningColor,
                                  () => setState(() => selectedStatus = 'pending'),
                                ),
                              ),
                              Expanded(
                                child: _buildStatusButton(
                                  'In Progress',
                                  'in_progress',
                                  selectedStatus,
                                  AppTheme.infoColor,
                                  () => setState(() => selectedStatus = 'in_progress'),
                                ),
                              ),
                              Expanded(
                                child: _buildStatusButton(
                                  'Resolved',
                                  'resolved',
                                  selectedStatus,
                                  AppTheme.successColor,
                                  () => setState(() => selectedStatus = 'resolved'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Admin Response
                        Text(
                          'Admin Response',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: responseController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Enter your response to the student...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Update Button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => _updateGrievance(
                              grievance.id,
                              selectedStatus,
                              responseController.text,
                            ),
                            child: const Text(
                              'Update Grievance',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisSection(Grievance grievance) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _aiService.analyzeComplaint(grievance.description),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.accentColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 32,
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 2000.ms)
                    .shake(duration: 1000.ms, delay: 500.ms),
                const SizedBox(height: 16),
                Text(
                  'AI is analyzing...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final analysis = snapshot.data!;
        final suggestions = analysis['suggestions'] as String? ?? 'No suggestions available';
        final reasoning = analysis['reasoning'] as String? ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with animated icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.accentColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ).animate().scale(delay: 100.ms).shimmer(delay: 300.ms),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'AI Analysis',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.successColor,
                                  AppTheme.successColor.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Gemini 2.0',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms).scale(delay: 200.ms),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Powered by Google AI',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms).slideX(),
            
            const SizedBox(height: 20),
            
            // Reasoning Card
            if (reasoning.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.infoColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.infoColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        reasoning,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(),
              const SizedBox(height: 16),
            ],
            
            // Suggestions Card - Beautiful styled
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.05),
                    AppTheme.accentColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  width: 2,
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.2),
                          AppTheme.accentColor.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.tips_and_updates,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Recommended Actions',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _parseSuggestions(suggestions, context),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(),
          ],
        );
      },
    );
  }

  // Parse suggestions and create beautiful formatted widgets
  List<Widget> _parseSuggestions(String suggestions, BuildContext context) {
    // Clean up the text first
    var cleanText = suggestions;
    
    // Remove all escape sequences
    cleanText = cleanText.replaceAll(r'\n\n', '\n');
    cleanText = cleanText.replaceAll(r'\n', '\n');
    cleanText = cleanText.replaceAll(r'\1', '');
    cleanText = cleanText.replaceAll(r'\t', ' ');
    
    // Remove markdown bold markers
    cleanText = cleanText.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'\1');
    
    // Split into lines
    final lines = cleanText.split('\n');
    final widgets = <Widget>[];
    
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // Remove leading asterisks and bullets
      while (line.startsWith('*') || line.startsWith('•')) {
        line = line.substring(1).trim();
      }
      
      // Skip very short lines
      if (line.length < 3) continue;
      
      // Check if it's a numbered item (1., 2., 3., etc.)
      final numberMatch = RegExp(r'^(\d+)\.\s*(.+)$').firstMatch(line);
      if (numberMatch != null) {
        final number = numberMatch.group(1)!;
        final text = numberMatch.group(2)!;
        
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          height: 1.5,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }
      
      // Check if it's a sub-item (starts with dash or contains colon)
      if (line.startsWith('-') || (line.contains(':') && !line.toUpperCase().contains('ACTION'))) {
        final cleanLine = line.startsWith('-') ? line.substring(1).trim() : line;
        
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 52, bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 9),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentColor,
                        AppTheme.accentColor.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    cleanLine,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.6,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }
      
      // Check if it's an ALL CAPS header
      if (line.toUpperCase() == line && line.length > 5 && !line.contains(':')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.warningColor.withOpacity(0.2),
                    AppTheme.warningColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.warningColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    line,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warningColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        continue;
      }
      
      // Regular text - only show if meaningful
      if (line.length > 10) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 52, bottom: 10),
            child: Text(
              line,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.7,
                fontSize: 14,
              ),
            ),
          ),
        );
      }
    }
    
    // If no widgets were created, show a simple message
    if (widgets.isEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            suggestions,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ),
      );
    }
    
    return widgets;
  }

  Widget _buildStatusButton(
    String label,
    String value,
    String selectedValue,
    Color color,
    VoidCallback onTap,
  ) {
    final isSelected = value == selectedValue;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _updateGrievance(String id, String status, String response) async {
    try {
      await _firebaseService.updateGrievanceStatus(
        id,
        status,
        adminResponse: response.isNotEmpty ? response : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grievance updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Text('Error loading data', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(error, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_outlined, size: 64, color: Colors.white),
          ).animate().scale(),
          const SizedBox(height: 24),
          Text(
            message,
            style: Theme.of(context).textTheme.headlineMedium,
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
