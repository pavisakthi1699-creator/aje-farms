import 'package:aje_farms_mobile/src/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records every call so tests can assert on exactly what the UI sent to the
/// server, and lets each test control the fixture data it returns.
class _RecordingAdminService extends LocalAdminService {
  _RecordingAdminService({
    this.users = const [],
    this.plans = const [],
    this.pending = const [],
    this.moderationReports = const [],
  });

  final List<AdminUserSummary> users;
  final List<AdminPlan> plans;
  List<AdminPaymentRecord> pending;
  List<AdminModerationReport> moderationReports;

  String? lastSearch;
  String? recordedUserId;
  String? recordedPlanId;
  String? recordedMethod;
  int? recordedAmountTzs;
  String? approvedPaymentId;
  String? reversedPaymentId;
  String? accessUserId;
  String? accessAction;
  String? moderationPostId;
  String? moderationAction;

  @override
  Future<AdminUsersPage> listUsers({
    String search = '',
    int limit = 50,
    int offset = 0,
  }) async {
    lastSearch = search;
    return AdminUsersPage(total: users.length, users: users);
  }

  @override
  Future<List<AdminPlan>> listPlans() async => plans;

  @override
  Future<AdminPaymentsPage> listPayments({
    String? status,
    String? userId,
    int limit = 50,
    int offset = 0,
  }) async {
    return AdminPaymentsPage(total: pending.length, records: pending);
  }

  @override
  Future<AdminPaymentRecord> recordPayment({
    required String userId,
    required String planId,
    required String method,
    required int amountTzs,
    String? reference,
    String? note,
  }) async {
    recordedUserId = userId;
    recordedPlanId = planId;
    recordedMethod = method;
    recordedAmountTzs = amountTzs;
    final record = AdminPaymentRecord(
      id: 'new-payment',
      userId: userId,
      userEmail: users.firstWhere((user) => user.id == userId).email,
      planId: planId,
      method: method,
      amountTzs: amountTzs,
      currency: 'TZS',
      reference: reference,
      note: note,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    pending = [...pending, record];
    return record;
  }

  @override
  Future<AdminPaymentRecord> approvePayment(
    String paymentRecordId, {
    String? reason,
  }) async {
    approvedPaymentId = paymentRecordId;
    final record = pending.firstWhere((item) => item.id == paymentRecordId);
    pending = pending.where((item) => item.id != paymentRecordId).toList();
    return AdminPaymentRecord(
      id: record.id,
      userId: record.userId,
      userEmail: record.userEmail,
      planId: record.planId,
      method: record.method,
      amountTzs: record.amountTzs,
      currency: record.currency,
      reference: record.reference,
      note: record.note,
      status: 'approved',
      createdAt: record.createdAt,
    );
  }

  @override
  Future<AdminPaymentRecord> reversePayment(
    String paymentRecordId, {
    String? reason,
  }) async {
    reversedPaymentId = paymentRecordId;
    final record = pending.firstWhere((item) => item.id == paymentRecordId);
    pending = pending.where((item) => item.id != paymentRecordId).toList();
    return AdminPaymentRecord(
      id: record.id,
      userId: record.userId,
      userEmail: record.userEmail,
      planId: record.planId,
      method: record.method,
      amountTzs: record.amountTzs,
      currency: record.currency,
      reference: record.reference,
      note: record.note,
      status: 'reversed',
      createdAt: record.createdAt,
    );
  }

  @override
  Future<void> updateUserAccess({
    required String userId,
    required String action,
    String? reason,
  }) async {
    accessUserId = userId;
    accessAction = action;
  }

  @override
  Future<List<AdminModerationReport>> listModerationReports() async =>
      moderationReports;

  @override
  Future<CommunityPost> resolveModerationReport({
    required String postId,
    required String action,
  }) async {
    moderationPostId = postId;
    moderationAction = action;
    final report = moderationReports.firstWhere(
      (item) => item.post.id == postId,
    );
    moderationReports =
        moderationReports.where((item) => item.post.id != postId).toList();
    return report.post;
  }
}

final _learner = AdminUserSummary(
  id: 'user-learner-1',
  email: 'learner@aje.test',
  accountStatus: 'pending_activation',
  displayName: null,
  preferredLocation: null,
  role: 'learner',
  subscriptionPlan: null,
  subscriptionStartedAt: null,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  learningProgressCount: 0,
  paymentTransactionsCount: 0,
  notificationCount: 0,
  communityPostsCount: 0,
);

const _plan = AdminPlan(
  id: 'wiki-1',
  title: 'Wiki 1',
  subtitle: 'Ufikiaji wa haraka',
  price: 'TZS 3,000',
  priceTzs: 3000,
  durationDays: 7,
  recommended: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> openAdminTab(
    WidgetTester tester,
    _RecordingAdminService adminService,
    String tabLabel,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final session = AppSessionController();
    await session.signInWithEmail('admin@aje.test', role: 'admin');

    final demo = AppDependencies.demo();
    await tester.pumpWidget(
      AjeFarmsApp(
        dependencies: AppDependencies(
          learningRepository: demo.learningRepository,
          communityRepository: demo.communityRepository,
          subscriptionRepository: demo.subscriptionRepository,
          mwalimuAiService: demo.mwalimuAiService,
          authService: demo.authService,
          catalogService: demo.catalogService,
          adminService: adminService,
          communityService: demo.communityService,
          learningProgressService: demo.learningProgressService,
          notificationService: demo.notificationService,
          paymentService: demo.paymentService,
          refreshCatalog: demo.refreshCatalog,
        ),
        sessionController: session,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Akaunti'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Dashibodi ya Admin'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Dashibodi ya Admin'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(tabLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tabLabel));
    await tester.pumpAndSettle();
  }

  Future<void> openMalipoTab(
    WidgetTester tester,
    _RecordingAdminService adminService,
  ) =>
      openAdminTab(tester, adminService, 'Malipo');

  testWidgets(
      'user card records and approves a paid learner in one admin action',
      (tester) async {
    final adminService = _RecordingAdminService(
      users: [_learner],
      plans: const [_plan],
    );
    await openAdminTab(tester, adminService, 'Watumiaji');

    expect(find.text('Thibitisha Malipo'), findsOneWidget);
    await tester.tap(find.text('Thibitisha Malipo'));
    await tester.pumpAndSettle();

    expect(find.text('Thibitisha malipo na fungua mafunzo'), findsOneWidget);
    expect(find.text('Wiki 1 — TZS 3,000'), findsOneWidget);
    await tester.tap(find.text('Thibitisha na Fungua'));
    await tester.pumpAndSettle();

    expect(adminService.recordedUserId, 'user-learner-1');
    expect(adminService.recordedPlanId, 'wiki-1');
    expect(adminService.recordedMethod, 'cash');
    expect(adminService.recordedAmountTzs, 3000);
    expect(adminService.approvedPaymentId, 'new-payment');
    expect(
      find.text('Malipo yamethibitishwa na mafunzo yamefunguliwa.'),
      findsOneWidget,
    );
  });

  testWidgets('admin user card shows role access instead of suspended status',
      (tester) async {
    final adminUser = AdminUserSummary(
      id: 'user-admin-1',
      email: 'admin@aje.test',
      accountStatus: 'suspended',
      displayName: 'AJE Admin',
      preferredLocation: null,
      role: 'admin',
      subscriptionPlan: null,
      subscriptionStartedAt: null,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      learningProgressCount: 0,
      paymentTransactionsCount: 0,
      notificationCount: 0,
      communityPostsCount: 0,
    );
    final adminService = _RecordingAdminService(users: [adminUser]);
    await openAdminTab(tester, adminService, 'Watumiaji');

    expect(find.text('Ufikiaji wa Admin'), findsOneWidget);
    expect(find.text('Amesitishwa'), findsNothing);
    expect(find.text('Thibitisha Malipo'), findsNothing);
  });

  testWidgets('admin suspension requires confirmation and calls real service',
      (tester) async {
    final adminService = _RecordingAdminService(users: [_learner]);
    await openAdminTab(tester, adminService, 'Watumiaji');

    await tester.tap(find.text('Sitisha Akaunti'));
    await tester.pumpAndSettle();
    expect(find.text('Sitisha akaunti?'), findsOneWidget);
    expect(adminService.accessAction, isNull);

    await tester.tap(find.text('Sitisha').last);
    await tester.pumpAndSettle();
    expect(adminService.accessUserId, 'user-learner-1');
    expect(adminService.accessAction, 'suspend');
  });

  testWidgets('admin can restore a hidden community post', (tester) async {
    final adminService = _RecordingAdminService(
      moderationReports: [
        AdminModerationReport(
          post: const CommunityPost(
            id: 'post-hidden-1',
            author: 'Mkulima Asha',
            location: 'Arusha',
            time: 'Leo',
            content: 'Ujumbe uliofichwa kwa ukaguzi.',
            likes: 0,
            comments: 0,
            tags: [],
            replies: [],
          ),
          report: AdminModerationReportStatus(
            postId: 'post-hidden-1',
            reportedAt: DateTime(2026, 7, 1),
            status: 'hidden',
          ),
        ),
      ],
    );
    await openAdminTab(tester, adminService, 'Usimamizi');

    expect(find.text('Ujumbe uliofichwa kwa ukaguzi.'), findsOneWidget);
    await tester.tap(find.text('Rejesha chapisho'));
    await tester.pumpAndSettle();

    expect(adminService.moderationPostId, 'post-hidden-1');
    expect(adminService.moderationAction, 'restore');
    expect(find.text('Chapisho limerejeshwa.'), findsOneWidget);
    expect(find.text('Hakuna ripoti'), findsOneWidget);
  });

  testWidgets('records a payment for a searched learner against a real plan',
      (tester) async {
    final adminService = _RecordingAdminService(
      users: [_learner],
      plans: const [_plan],
    );
    await openMalipoTab(tester, adminService);

    await tester.enterText(
      find.widgetWithText(TextField, 'Tafuta mkulima kwa barua pepe'),
      'learner',
    );
    await tester.tap(find.byIcon(Icons.arrow_forward).first);
    await tester.pumpAndSettle();

    expect(adminService.lastSearch, 'learner');
    expect(find.text('learner@aje.test'), findsOneWidget);

    await tester.tap(find.text('learner@aje.test'));
    await tester.pumpAndSettle();

    // The amount field is pre-filled from the selected plan's server-owned
    // price, never left for the staff member to type freely.
    final amountField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Kiasi (TZS)'),
    );
    expect(amountField.controller?.text, '3000');

    await tester.scrollUntilVisible(
      find.text('Rekodi Malipo'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Rekodi Malipo'));
    await tester.pumpAndSettle();

    expect(adminService.recordedUserId, 'user-learner-1');
    expect(adminService.recordedPlanId, 'wiki-1');
    expect(adminService.recordedMethod, 'cash');
    expect(adminService.recordedAmountTzs, 3000);
    expect(
        find.text('Malipo yamerekodiwa. Yanasubiri idhini.'), findsOneWidget);
  });

  testWidgets(
      'approving a pending payment calls the service and removes it from the list',
      (tester) async {
    final pendingRecord = AdminPaymentRecord(
      id: 'payrec-1',
      userId: 'user-learner-1',
      userEmail: 'learner@aje.test',
      planId: 'wiki-1',
      method: 'cash',
      amountTzs: 3000,
      currency: 'TZS',
      reference: null,
      note: null,
      status: 'pending',
      createdAt: DateTime(2026, 7, 1),
    );
    final adminService = _RecordingAdminService(
      users: [_learner],
      plans: const [_plan],
      pending: [pendingRecord],
    );
    await openMalipoTab(tester, adminService);

    expect(find.text('learner@aje.test'), findsOneWidget);
    await tester.tap(find.text('Idhinisha'));
    await tester.pumpAndSettle();

    // Approving is destructive-adjacent enough to confirm, matching the
    // pattern used for sign-out and subscription cancellation elsewhere.
    expect(find.text('Idhinisha malipo?'), findsOneWidget);
    await tester.tap(find.text('Idhinisha').last);
    await tester.pumpAndSettle();

    expect(adminService.approvedPaymentId, 'payrec-1');
    expect(find.text('Malipo yameidhinishwa.'), findsOneWidget);
  });

  testWidgets('reversing a pending payment calls the service', (tester) async {
    final pendingRecord = AdminPaymentRecord(
      id: 'payrec-2',
      userId: 'user-learner-1',
      userEmail: 'learner@aje.test',
      planId: 'wiki-1',
      method: 'bank_transfer',
      amountTzs: 3000,
      currency: 'TZS',
      reference: 'REF-1',
      note: null,
      status: 'pending',
      createdAt: DateTime(2026, 7, 1),
    );
    final adminService = _RecordingAdminService(
      users: [_learner],
      plans: const [_plan],
      pending: [pendingRecord],
    );
    await openMalipoTab(tester, adminService);

    await tester.tap(find.text('Rudisha Nyuma'));
    await tester.pumpAndSettle();
    expect(find.text('Rudisha nyuma malipo?'), findsOneWidget);
    await tester.tap(find.text('Rudisha Nyuma').last);
    await tester.pumpAndSettle();

    expect(adminService.reversedPaymentId, 'payrec-2');
    expect(find.text('Malipo yamerudishwa nyuma.'), findsOneWidget);
  });

  testWidgets('empty pending list shows an explanatory empty state',
      (tester) async {
    final adminService = _RecordingAdminService(plans: const [_plan]);
    await openMalipoTab(tester, adminService);

    expect(find.text('Hakuna malipo yanayosubiri'), findsOneWidget);
  });
}
