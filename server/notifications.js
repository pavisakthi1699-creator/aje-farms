export function createNotificationProvider() {
  return new DevelopmentNotificationProvider();
}

class DevelopmentNotificationProvider {
  name = 'development';

  async send(notification, devices = []) {
    if (devices.length === 0) return;
    if (process.env.NODE_ENV !== 'production') {
      console.log(
        `[AJE notification] ${notification.phoneNumber}: ${notification.title}`,
      );
    }
  }
}
