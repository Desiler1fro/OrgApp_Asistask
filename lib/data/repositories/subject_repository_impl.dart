import '../../domain/entities/subject.dart';
import '../../domain/repositories/subject_repository.dart';
import '../database/app_database.dart';

class SubjectRepositoryImpl implements SubjectRepository {
  SubjectRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Subject>> watchAll() {
    return _db.subjectsDao.watchAll().map(
          (rows) => rows.map(_toEntity).toList(),
        );
  }

  @override
  Future<bool> hasAny() async {
    final c = await _db.subjectsDao.count();
    return c > 0;
  }

  @override
  Future<void> insertMany(List<SubjectInput> inputs) {
    final companions = inputs.map(_companionFrom).toList();
    return _db.subjectsDao.insertMany(companions);
  }

  @override
  Future<void> insertOne(SubjectInput input) {
    return _db.subjectsDao.insertOne(_companionFrom(input));
  }

  @override
  Future<void> updateColor(int id, int colorValue) {
    return _db.subjectsDao.updateColor(id, colorValue);
  }

  @override
  Future<int> taskCount(int subjectId) {
    return _db.tasksDao.countBySubjectId(subjectId);
  }

  @override
  Future<void> deleteById(int id) {
    return _db.subjectsDao.deleteById(id);
  }

  SubjectsCompanion _companionFrom(SubjectInput i) {
    return SubjectsCompanion.insert(
      name: i.name,
      colorValue: i.colorValue,
      liking: i.liking,
    );
  }

  Subject _toEntity(SubjectRow row) {
    return Subject(
      id: row.id,
      name: row.name,
      colorValue: row.colorValue,
      liking: row.liking,
      createdAt: row.createdAt,
    );
  }
}
