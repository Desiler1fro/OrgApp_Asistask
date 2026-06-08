import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/subject.dart';
import '../../domain/repositories/subject_repository.dart';
import '../database/database_provider.dart';
import 'subject_repository_impl.dart';

final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  return SubjectRepositoryImpl(ref.watch(appDatabaseProvider));
});

final subjectsStreamProvider = StreamProvider<List<Subject>>((ref) {
  return ref.watch(subjectRepositoryProvider).watchAll();
});
