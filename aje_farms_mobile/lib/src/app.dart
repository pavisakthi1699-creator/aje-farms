library aje_farms_mobile_app;

import 'package:flutter/material.dart';

import 'models/community_post.dart';
import 'models/course.dart';
import 'models/plan_option.dart';
import 'models/problem_category.dart';
import 'repositories/demo_app_repository.dart';
import 'services/demo_mwalimu_ai_service.dart';
import 'theme/app_theme.dart';

part 'app/aje_farms_app.dart';
part 'features/onboarding/onboarding_screen.dart';
part 'features/auth/auth_screen.dart';
part 'app/main_shell.dart';
part 'features/home/dashboard_screen.dart';
part 'features/problem/problem_screen.dart';
part 'features/courses/courses_screen.dart';
part 'features/courses/course_detail_screen.dart';
part 'features/ai_chat/ai_chat_screen.dart';
part 'features/community/community_screen.dart';
part 'features/assessments/assessments_screen.dart';
part 'features/paywall/paywall_screen.dart';
part 'features/expert_support/whatsapp_escalation_screen.dart';
part 'features/notifications/notifications_screen.dart';
part 'features/profile/profile_screen.dart';
part 'shared/widgets/brand_header.dart';
part 'features/home/home_widgets.dart';
part 'features/courses/course_widgets.dart';
part 'features/courses/expert_panel.dart';
part 'features/ai_chat/chat_widgets.dart';
part 'features/community/community_widgets.dart';
part 'features/paywall/paywall_widgets.dart';
part 'features/problem/problem_widgets.dart';
part 'features/home/community_teaser.dart';
part 'shared/widgets/action_card.dart';
part 'shared/widgets/section_header.dart';
part 'shared/widgets/pill.dart';
part 'features/paywall/payment_badge.dart';
part 'features/profile/profile_widgets.dart';
part 'shared/widgets/network_photo.dart';
part 'shared/widgets/snack.dart';

const _demoRepository = DemoAppRepository();
const _mwalimuAiService = DemoMwalimuAiService();
