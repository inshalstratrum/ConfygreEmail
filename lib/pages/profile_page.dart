import 'package:flutter/material.dart';
import '../components/GlobalVariables.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // getProfileInfo();
  }

  @override
  Widget build(BuildContext context) {
    final account = googleSignIn.currentUser;
    final saved = objectBox?.getUserCredential();
    final email = account?.email ?? saved?.userEmail ?? 'Not available';
    final name = account?.displayName ?? email.split('@').first;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            ProfileField(label: 'Email', value: email),
            ProfileField(label: 'Username', value: name),
            ProfileField(
                label: 'OAuth',
                value: objectBox?.getOAuthData()?.oAuthKey.isNotEmpty == true
                    ? 'Configured'
                    : 'Not configured'),
            Spacer(), // Pushes the button to the bottom
          ],
        ),
      ),
    );
  }
}

// Widget to display a profile field
class ProfileField extends StatelessWidget {
  final String label;
  final String value;

  const ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }
}
