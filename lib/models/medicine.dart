class Medicine {
  final String id;
  final String name;
  final String dosage;
  final String type;
  final String frequency;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> times;
  final bool isTaken;
  final String? assignedTo;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    this.type = 'Tablet',
    this.frequency = 'Daily',
    this.startDate,
    this.endDate,
    required this.times,
    this.isTaken = false,
    this.assignedTo,
  });

  Medicine copyWith({
    String? id,
    String? name,
    String? dosage,
    String? type,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? times,
    bool? isTaken,
    String? assignedTo,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      times: times ?? this.times,
      isTaken: isTaken ?? this.isTaken,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
}
