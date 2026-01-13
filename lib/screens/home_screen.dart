import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/grievance.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'submit_grievance_screen.dart';
import 'grievance_detail_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        final studentId = user?.id ?? 'guest';
        final studentName = user?.name ?? 'Guest User';
        final studentEmail = user?.email ?? '';

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverToBoxAdapter(
                    child: _buildHeader(studentName),
                  ),
                  
                  // Statistics Cards
                  SliverToBoxAdapter(
                    child: _buildStatistics(studentId),
                  ),
                  
                  // Recent Grievances
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Grievances',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to all grievances
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Grievances List
                  StreamBuilder<List<Grievance>>(
                    stream: _firebaseService.getStudentGrievances(studentId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SliverToBoxAdapter(
                          child: _buildLoadingShimmer(),
                        );
                      }

                      if (snapshot.hasError) {
                        return SliverToBoxAdapter(
                          child: _buildError(snapshot.error.toString()),
                        );
                      }

                      final grievances = snapshot.data ?? [];

                      if (grievances.isEmpty) {
                        return SliverToBoxAdapter(
                          child: _buildEmptyState(),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final grievance = grievances[index];
                              return _buildGrievanceCard(grievance, index);
                            },
                            childCount: grievances.length,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Bottom Spacing
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubmitGrievanceScreen(
                    studentId: studentId,
                    studentName: studentName,
                    studentEmail: studentEmail,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('New Complaint'),
          ).animate().scale(delay: 500.ms),
        );
      },
    );
  }

  Widget _buildHeader(String studentName) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 28,
                ),
              ).animate().scale(delay: 100.ms),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campus Grievance',
                      style: Theme.of(context).textTheme.displaySmall,
                    ).animate().fadeIn(delay: 200.ms).slideX(),
                    Text(
                      'AI-Powered Priority System',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideX(),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
                color: AppTheme.textPrimary,
                tooltip: 'Notifications',
              ).animate().scale(delay: 400.ms),
              IconButton(
                onPressed: () async {
                  final authService = Provider.of<AuthService>(context, listen: false);
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                color: AppTheme.textPrimary,
                tooltip: 'Logout',
              ).animate().scale(delay: 500.ms),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Hello, $studentName 👋',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  Widget _buildStatistics(String studentId) {
    return StreamBuilder<List<Grievance>>(
      stream: _firebaseService.getStudentGrievances(studentId),
      builder: (context, snapshot) {
        final grievances = snapshot.data ?? [];
        
        final stats = {
          'total': grievances.length,
          'pending': grievances.where((g) => g.status == 'pending').length,
          'in_progress': grievances.where((g) => g.status == 'in_progress').length,
          'resolved': grievances.where((g) => g.status == 'resolved').length,
          'critical': grievances.where((g) => g.severityScore >= 8).length,
        };

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  stats['pending']!,
                  Icons.pending_outlined,
                  AppTheme.warningColor,
                  0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'In Progress',
                  stats['in_progress']!,
                  Icons.autorenew,
                  AppTheme.infoColor,
                  1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Resolved',
                  stats['resolved']!,
                  Icons.check_circle_outline,
                  AppTheme.successColor,
                  2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    int count,
    IconData icon,
    Color color,
    int index,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(delay: (600 + index * 100).ms).slideY();
  }

  Widget _buildGrievanceCard(Grievance grievance, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.getSeverityColor(grievance.severityScore)
              .withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GrievanceDetailScreen(
                  grievance: grievance,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        grievance.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Severity Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.getSeverityColor(grievance.severityScore)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.priority_high,
                            size: 14,
                            color: AppTheme.getSeverityColor(
                              grievance.severityScore,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${grievance.severityScore}/10',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.getSeverityColor(
                                grievance.severityScore,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  grievance.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  grievance.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      grievance.location,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.getStatusColor(grievance.status)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        grievance.status.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.getStatusColor(grievance.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (800 + index * 100).ms).slideY();
  }

  Widget _buildLoadingShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 150,
            decoration: BoxDecoration(
              color: AppTheme.shimmerBase,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading grievances',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.white,
              ),
            ).animate().scale(),
            const SizedBox(height: 24),
            Text(
              'No Grievances Yet',
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to submit your first complaint',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }
}
