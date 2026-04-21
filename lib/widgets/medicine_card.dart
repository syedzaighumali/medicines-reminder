import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../theme/app_theme.dart';

class MedicineCard extends StatefulWidget {
  final Medicine medicine;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<MedicineCard> createState() => _MedicineCardState();
}

class _MedicineCardState extends State<MedicineCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getMedicineIcon() {
    switch (widget.medicine.type.toLowerCase()) {
      case 'syrup':
        return Icons.local_drink_outlined;
      case 'injection':
        return Icons.vaccines_outlined;
      case 'capsule':
        return Icons.medication_outlined;
      case 'drop':
        return Icons.water_drop_outlined;
      default:
        return Icons.medication;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTaken = widget.medicine.isTaken;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isTaken
                ? (isDark
                      ? AppTheme.primaryPurple.withValues(alpha: 0.1)
                      : const Color(0xFFF0FDF4))
                : (isDark ? AppTheme.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isTaken
                  ? AppTheme.primaryPurple.withValues(alpha: 0.5)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppTheme.slate100),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : AppTheme.slate200).withValues(
                  alpha: 0.1,
                ),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: widget.onToggle,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: isTaken
                            ? const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              )
                            : AppTheme.purpleGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isTaken
                                        ? AppTheme.primaryPurple
                                        : AppTheme.secondaryPink)
                                    .withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getMedicineIcon(),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.medicine.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              decoration: isTaken
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isTaken
                                  ? (isDark
                                        ? Colors.green.shade300
                                        : Colors.green.shade700)
                                  : (isDark ? Colors.white : AppTheme.textDark),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.medicine.dosage} • ${widget.medicine.type}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isTaken
                                  ? (isDark
                                        ? Colors.green.shade400
                                        : Colors.green.shade600)
                                  : (isDark
                                        ? Colors.white54
                                        : AppTheme.slate500),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: widget.medicine.times.map((t) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentOrange.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppTheme.accentOrange.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.accentOrange,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isTaken
                                ? AppTheme.primaryPurple
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : AppTheme.slate50),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isTaken
                                ? Icons.check_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isTaken
                                ? Colors.white
                                : (isDark ? Colors.white24 : AppTheme.slate300),
                            size: 24,
                          ),
                        ),
                        if (widget.onEdit != null && widget.onDelete != null)
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') widget.onEdit!();
                              if (value == 'delete') widget.onDelete!();
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: AppTheme.slate600,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            icon: Icon(
                              Icons.more_horiz_rounded,
                              color: isDark
                                  ? Colors.white24
                                  : AppTheme.slate300,
                              size: 24,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
