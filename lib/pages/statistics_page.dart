import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late Future<List<Task>> _tasksFuture;

  static const _primary = Color(0xFF4F46E5);
  static const _background = Color(0xFFF8FAFC);
  static const _secondaryText = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _tasksFuture = TaskService().fetchTasks();
  }

  void _retry() {
    setState(() {
      _tasksFuture = TaskService().fetchTasks();
    });
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 23,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: _secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: FutureBuilder<List<Task>>(
          future: _tasksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Could not load statistics.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _retry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final tasks = snapshot.data ?? [];

            final total = tasks.length;
            final completed = tasks.where((task) => task.completed).length;
            final pending = total - completed;

            final completionRate = total == 0
                ? 0.0
                : completed / total;

            final percentage = '${(completionRate * 100).round()}%';

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1000,
                ),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                const Text(
                  'Your Progress',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Get an overview of your tasks and progress.',
                  style: TextStyle(
                    fontSize: 14,
                    color: _secondaryText,
                  ),
                ),
                const SizedBox(height: 24),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;

                    final columns = width >= 800
                        ? 4
                        : width >= 560
                            ? 3
                            : 2;

                    final aspectRatio = width >= 800
                        ? 1.25
                        : width >= 560
                            ? 1.05
                            : 0.9;

                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: aspectRatio,
                      children: [
                        _buildStatCard(
                          title: 'Total Tasks',
                          value: '$total',
                          icon: Icons.checklist_rounded,
                          color: _primary,
                        ),
                        _buildStatCard(
                          title: 'Completed',
                          value: '$completed',
                          icon: Icons.check_circle_outline,
                          color: const Color(0xFF10B981),
                        ),
                        _buildStatCard(
                          title: 'Pending',
                          value: '$pending',
                          icon: Icons.pending_actions,
                          color: const Color(0xFFF59E0B),
                        ),
                        _buildStatCard(
                          title: 'Completion Rate',
                          value: percentage,
                          icon: Icons.trending_up,
                          color: const Color(0xFF6366F1),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Completion',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$completed out of $total tasks completed',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _secondaryText,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: completionRate,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(_primary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          percentage,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                OutlinedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Statistics'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );   
          },
        ),
      ),
    );
  }
}