import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/subjects_table.dart';

part 'subjects_dao.g.dart';

@DriftAccessor(tables: [Subjects])
class SubjectsDao extends DatabaseAccessor<AppDatabase>
    with _$SubjectsDaoMixin {
  SubjectsDao(super.db);

  Stream<List<SubjectRow>> watchAll() {
    return (select(subjects)..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .watch();
  }

  Future<int> count() async {
    final expr = subjects.id.count();
    final row =
        await (selectOnly(subjects)..addColumns([expr])).getSingle();
    return row.read(expr) ?? 0;
  }

  Future<void> insertMany(List<SubjectsCompanion> entries) async {
    await batch((b) => b.insertAll(subjects, entries));
  }

  Future<void> insertOne(SubjectsCompanion entry) async {
    await into(subjects).insert(entry);
  }

  Future<void> updateColor(int id, int colorValue) async {
    await (update(subjects)..where((t) => t.id.equals(id))).write(
      SubjectsCompanion(colorValue: Value(colorValue)),
    );
  }

  Future<void> deleteById(int id) async {
    await (delete(subjects)..where((t) => t.id.equals(id))).go();
  }
}
