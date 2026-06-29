class EmergencyStepsRepository {
  final Database db;

  EmergencyStepsRepository(this.db);

  Future<List<Map<String, dynamic>>> getStepsFor(String emergencyType) async {
    return await db.query(
      'emergency_steps',
      where: 'emergency = ?',
      whereArgs: [emergencyType],
      orderBy: 'stepNum ASC',
    );
  }
}
