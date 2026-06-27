part of '../../app.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          ListTile(
            leading: Icon(Icons.menu_book),
            title: Text('Somo jipya limeongezwa'),
            subtitle: Text('Angalia mwongozo mpya wa nyanya.'),
          ),
          ListTile(
            leading: Icon(Icons.payment),
            title: Text('Jaribio linakaribia kuisha'),
            subtitle: Text('Lipia kifurushi ili kuendelea kujifunza.'),
          ),
        ],
      ),
    );
  }
}
