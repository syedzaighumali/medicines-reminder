import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medicine.dart';
import '../services/db_service.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class AddMedicineScreen extends StatefulWidget {
  final Medicine? medicineToEdit;

  const AddMedicineScreen({super.key, this.medicineToEdit});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _dosage = '';
  String _type = 'Tablet';
  String _frequency = 'Daily';
  final List<TimeOfDay> _times = [];
  DateTime? _startDate = DateTime.now();
  DateTime? _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  final List<String> _types = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Injection',
    'Drop',
  ];
  final List<String> _frequencies = ['Daily', 'Weekly', 'Custom'];

  @override
  void initState() {
    super.initState();
    if (widget.medicineToEdit != null) {
      _name = widget.medicineToEdit!.name;
      _dosage = widget.medicineToEdit!.dosage;
      _type = widget.medicineToEdit!.type;
      _frequency = widget.medicineToEdit!.frequency;
      _startDate = widget.medicineToEdit!.startDate ?? DateTime.now();
      _endDate =
          widget.medicineToEdit!.endDate ??
          DateTime.now().add(const Duration(days: 7));
      for (var t in widget.medicineToEdit!.times) {
        final parts = t.split(':');
        if (parts.length == 2) {
          _times.add(
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
          );
        }
      }
    }
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      if (_times.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one reminder time'),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);
      _formKey.currentState!.save();

      try {
        final medicine = Medicine(
          id:
              widget.medicineToEdit?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _name,
          dosage: _dosage,
          type: _type,
          frequency: _frequency,
          startDate: _startDate,
          endDate: _endDate,
          times: _times
              .map(
                (t) =>
                    '${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}',
              )
              .toList(),
        );

        await DatabaseService().insertMedicine(medicine);

        final notificationService = NotificationService();
        for (int i = 0; i < _times.length; i++) {
          final time = _times[i];
          final scheduledTime = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            time.hour,
            time.minute,
          );

          await notificationService.scheduleNotification(
            id: medicine.id.hashCode + i,
            title: 'Medicine Reminder: ${medicine.name}',
            body:
                "It's time to take ${medicine.dosage} of ${medicine.name}. 💊",
            scheduledTime: scheduledTime.isBefore(DateTime.now())
                ? scheduledTime.add(const Duration(days: 1))
                : scheduledTime,
          );
        }

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medicine saved successfully!'),
              backgroundColor: AppTheme.primaryPurple,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        debugPrint('Failed to save: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.medicineToEdit == null ? 'New Reminder' : 'Edit Reminder',
        ),
        backgroundColor: (isDark ? Colors.black38 : Colors.white38),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader(
                    'General Information',
                    Icons.info_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _name,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.textDark,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Medicine Name',
                      prefixIcon: Icon(
                        Icons.medication_rounded,
                        color: AppTheme.secondaryPink,
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter name'
                        : null,
                    onSaved: (value) => _name = value!,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: _dosage,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.textDark,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Dosage (e.g. 1 Tab)',
                            prefixIcon: Icon(
                              Icons.scale_rounded,
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Required'
                              : null,
                          onSaved: (value) => _dosage = value!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _type,
                          decoration: const InputDecoration(labelText: 'Type'),
                          dropdownColor: isDark
                              ? AppTheme.darkCard
                              : Colors.white,
                          items: _types
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setState(() => _type = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    'Schedule Settings',
                    Icons.calendar_month_rounded,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _frequency,
                    decoration: const InputDecoration(
                      labelText: 'Frequency',
                      prefixIcon: Icon(
                        Icons.repeat_rounded,
                        color: AppTheme.accentOrange,
                      ),
                    ),
                    dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                    items: _frequencies
                        .map(
                          (freq) =>
                              DropdownMenuItem(value: freq, child: Text(freq)),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _frequency = val!),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    'Reminder Times',
                    Icons.access_time_rounded,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ..._times.map(
                        (t) => Chip(
                          label: Text(
                            t.format(context),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: AppTheme.secondaryPink.withValues(
                            alpha: 0.1,
                          ),
                          side: const BorderSide(
                            color: AppTheme.secondaryPink,
                            width: 0.5,
                          ),
                          onDeleted: () => setState(() => _times.remove(t)),
                        ),
                      ),
                      ActionChip(
                        label: const Text('Add Time'),
                        avatar: const Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.white,
                        ),
                        backgroundColor: AppTheme.primaryPurple,
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null && !_times.contains(time))
                            setState(() => _times.add(time));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(
                          'Start Date',
                          _startDate,
                          (d) => setState(() => _startDate = d),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDatePicker(
                          'End Date',
                          _endDate,
                          (d) => setState(() => _endDate = d),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppTheme.purpleGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryPink.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'SAVE REMINDER',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white70 : AppTheme.slate500,
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: isDark ? Colors.white70 : AppTheme.slate500,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? date,
    Function(DateTime) onDateSelected,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (d != null) onDateSelected(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null ? DateFormat('MMM d, y').format(date) : 'Select',
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: AppTheme.secondaryPink,
            ),
          ],
        ),
      ),
    );
  }
}
