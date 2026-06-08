import '../entities/subject.dart';

abstract class SubjectRepository {
  Stream<List<Subject>> watchAll();
  Future<bool> hasAny();
  Future<void> insertMany(List<SubjectInput> inputs);
  Future<void> insertOne(SubjectInput input);
  Future<void> updateColor(int id, int colorValue);
  Future<int> taskCount(int subjectId);
  Future<void> deleteById(int id);
}
