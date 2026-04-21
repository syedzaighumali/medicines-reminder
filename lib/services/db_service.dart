import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medicine.dart';
import '../models/family_member.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final SupabaseClient client = Supabase.instance.client;

  // --- Auth logic ---
  
  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp(String email, String password) async {
    await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // --- Medicines CRUD ---

  Future<void> insertMedicine(Medicine medicine) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await client.from('medicines').upsert({
      'id': medicine.id,
      'user_id': userId,
      'name': medicine.name,
      'dosage': medicine.dosage,
      'type': medicine.type,
      'frequency': medicine.frequency,
      'start_date': medicine.startDate?.toIso8601String(),
      'end_date': medicine.endDate?.toIso8601String(),
      'times': medicine.times, // Automatically serialized to JSONB by Supabase
      'is_taken': medicine.isTaken,
      'assigned_to': medicine.assignedTo,
    });
  }

  Future<void> deleteMedicine(String id) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await client
        .from('medicines')
        .delete()
        .match({'id': id, 'user_id': userId});
  }

  Future<List<Medicine>> getMedicines() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await client
        .from('medicines')
        .select()
        .eq('user_id', userId);

    return (response as List<dynamic>).map((row) {
      return Medicine(
        id: row['id'] as String,
        name: row['name'] as String,
        dosage: row['dosage'] as String,
        type: row['type'] as String? ?? 'Tablet',
        frequency: row['frequency'] as String? ?? 'Daily',
        startDate: row['start_date'] != null ? DateTime.parse(row['start_date'] as String) : null,
        endDate: row['end_date'] != null ? DateTime.parse(row['end_date'] as String) : null,
        times: List<String>.from(row['times'] ?? []),
        isTaken: row['is_taken'] as bool,
        assignedTo: row['assigned_to'] as String?,
      );
    }).toList();
  }

  Future<void> updateMedicineTakenStatus(String id, bool isTaken) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await client
        .from('medicines')
        .update({'is_taken': isTaken})
        .match({'id': id, 'user_id': userId});
  }

  // --- Family Members CRUD ---

  Future<void> insertFamilyMember(FamilyMember member) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await client.from('family_members').upsert({
      'id': member.id,
      'user_id': userId,
      'name': member.name,
      'age': member.age,
      'relation': member.relation,
    });
  }

  Future<void> deleteFamilyMember(String id) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await client
        .from('family_members')
        .delete()
        .match({'id': id, 'user_id': userId});
  }

  Future<List<FamilyMember>> getFamilyMembers() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await client
        .from('family_members')
        .select()
        .eq('user_id', userId);
    
    return (response as List<dynamic>).map((row) {
      return FamilyMember(
        id: row['id'] as String,
        name: row['name'] as String,
        age: row['age'] as int,
        relation: row['relation'] as String,
      );
    }).toList();
  }
}
