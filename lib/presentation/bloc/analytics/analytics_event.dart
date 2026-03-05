// lib/presentation/bloc/analytics/analytics_event.dart

import 'package:equatable/equatable.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();
  @override
  List<Object?> get props => [];
}

class LoadWeeklyAnalytics extends AnalyticsEvent {
  const LoadWeeklyAnalytics();
}

class LoadMonthlyAnalytics extends AnalyticsEvent {
  const LoadMonthlyAnalytics();
}

