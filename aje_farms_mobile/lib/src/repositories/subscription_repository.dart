import '../models/plan_option.dart';

abstract interface class SubscriptionRepository {
  List<PlanOption> get plans;
}
