import 'package:aje_farms_mobile/src/shared/dashboard_greeting.dart';
import 'package:aje_farms_mobile/src/state/app_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guest greeting uses default mkulima copy', () {
    const state = AppSessionState(isGuest: true, hasStarted: true);
    expect(state.dashboardGreeting, 'Karibu, Mkulima');
  });

  test('signed-in greeting welcomes returning farmer', () {
    const state = AppSessionState(
      hasStarted: true,
      phoneNumber: '+255712345678',
    );
    expect(state.dashboardGreeting, 'Karibu tena');
  });

  test('location greeting names the farmer region', () {
    const state = AppSessionState(
      hasStarted: true,
      phoneNumber: '+255712345678',
      preferredLocation: 'Morogoro',
    );
    expect(state.dashboardGreeting, 'Karibu, mkulima wa Morogoro');
  });
}
