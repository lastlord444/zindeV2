// lib/domain/usecases/analytics/get_weekly_report.dart

import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/analytics/haftalik_rapor.dart';
import '../../repositories/analytics_repository.dart';

/// Haftalık rapor getir use case'i
class GetWeeklyReport {
  final AnalyticsRepository _repository;

  const GetWeeklyReport(this._repository);

  Future<Either<Failure, HaftalikRapor>> call({
    required String userId,
    required DateTime baslangic,
  }) {
    return _repository.haftalikRaporOlustur(
      userId: userId,
      baslangic: baslangic,
    );
  }
}
