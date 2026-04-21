import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../widgets/medicine_card.dart';
import '../theme/app_theme.dart';
import 'add_medicine_screen.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  List<Medicine> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReminders();
  }

  Future<void> _fetchReminders() async {
    try {
      final medicines = await DatabaseService().getMedicines();
      setState(() {
        _reminders = medicines;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('DB Error: $e');
      setState(() {
        _isLoading = false;
        _reminders = [];
      });
    }
  }

  Future<void> _toggleMedicine(Medicine reminder, int index) async {
    final newStatus = !reminder.isTaken;
    setState(() {
      _reminders[index] = reminder.copyWith(isTaken: newStatus);
    });
    try {
      await DatabaseService().updateMedicineTakenStatus(reminder.id, newStatus);
    } catch (e) {
      debugPrint('Failed to toggle DB: $e');
    }
  }

  Future<void> _deleteMedicine(Medicine medicine) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Medicine'),
        content: Text(
          'Are you sure you want to remove "${medicine.name}" from your records?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await DatabaseService().deleteMedicine(medicine.id);
        final notificationService = NotificationService();
        for (int i = 0; i < medicine.times.length; i++) {
          await notificationService.cancelNotification(
            medicine.id.hashCode + i,
          );
        }
        _fetchReminders();
      } catch (e) {
        debugPrint('Failed to delete: $e');
      }
    }
  }

  void _editMedicine(Medicine medicine) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(medicineToEdit: medicine),
      ),
    );
    if (result == true) _fetchReminders();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final upcoming = _reminders.where((m) => !m.isTaken).toList();
    final completed = _reminders.where((m) => m.isTaken).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchReminders,
          child: CustomScrollView(
            slivers: [
              // Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 100, 20, 0),
                  child: Row(
                    children: [
                      _buildSummaryChip(
                        '${upcoming.length}',
                        'Pending',
                        AppTheme.accentOrange,
                        Icons.pending_actions_rounded,
                      ),
                      const SizedBox(width: 12),
                      _buildSummaryChip(
                        '${completed.length}',
                        'Done',
                        AppTheme.primaryPurple,
                        Icons.task_alt_rounded,
                      ),
                      const SizedBox(width: 12),
                      _buildSummaryChip(
                        '${_reminders.length}',
                        'Total',
                        AppTheme.secondaryPink,
                        Icons.medication_rounded,
                      ),
                    ],
                  ),
                ),
              ),

              // Upcoming
              if (upcoming.isNotEmpty) ...[
                _buildSectionHeader('UPCOMING', AppTheme.accentOrange),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final medication = upcoming[index];
                      return MedicineCard(
                        medicine: medication,
                        onToggle: () => _toggleMedicine(
                          medication,
                          _reminders.indexOf(medication),
                        ),
                        onEdit: () => _editMedicine(medication),
                        onDelete: () => _deleteMedicine(medication),
                      );
                    }, childCount: upcoming.length),
                  ),
                ),
              ],

              // Completed
              if (completed.isNotEmpty) ...[
                _buildSectionHeader('COMPLETED TODAY', AppTheme.primaryPurple),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final medication = completed[index];
                      return MedicineCard(
                        medicine: medication,
                        onToggle: () => _toggleMedicine(
                          medication,
                          _reminders.indexOf(medication),
                        ),
                        onEdit: () => _editMedicine(medication),
                        onDelete: () => _deleteMedicine(medication),
                      );
                    }, childCount: completed.length),
                  ),
                ),
              ],

              // Empty or Loading
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_reminders.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 64,
                          color: isDark ? Colors.white10 : AppTheme.slate100,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'All caught up!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white38 : AppTheme.slate300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip(
    String count,
    String label,
    Color color,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.08),
              color.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              count,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppTheme.textDark,
                letterSpacing: -1,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
