import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../components/GlobalVariables.dart';
import '../components/bottom_nav_bar.dart';
import '../components/emails.dart';
import '../pages/app_settings_page.dart';
import '../pages/error_page.dart';
import '../pages/history_page.dart';
import '../pages/login_page.dart';
import '../pages/profile_page.dart';
import '../pages/tiles_page.dart';
import '../pages/mailbox_page.dart';
import '../components/gmail_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int _selectedIndex = 0;
  String pageTile = "Home";

  void navigationBottomBar(int index) async {

    // if(index == 3)
    //   await getProfileInfo();

    setState(() {
      _selectedIndex = index;

      switch(index){
        case 0:
          pageTile = "Home";
          break;
        case 1:
          pageTile = "History";
          break;
        case 2:
          pageTile = "App Settings";
          break;
        case 3:
          pageTile = "Profile";
          break;
      }

    });
  }

  Future<void> _runConnectionTest() async {
    String result;
    try {
      final profile = await gmailApi.users.getProfile('me');
      result = 'Connection successful\\nAccount: ${profile.emailAddress}\\nMessages: ${profile.messagesTotal ?? 0}';
    } catch (e) {
      result = 'Connection failed\\n$e';
    }
    if (!mounted) return;
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Gmail connection test'), content: Text(result), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
  }

  final List<Widget> _pages = [
    const Tiles(),
    const HistoryPage(),
    const AppSettings(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(
          pageTile,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF6F8FB),
        elevation: 0,
        leading: Builder(
            builder: (context) => IconButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                icon: Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Icon(Icons.menu),
                ))) ,
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[900],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [ Column(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HomePage())),
                child: const Padding(
                  padding: const EdgeInsets.only(left: 25.0),
                  child: ListTile(
                    title: Text('Home', style: TextStyle(color: Colors.white, fontSize: 25),),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline, color: Colors.white),
                title: const Text('Mailbox', style: TextStyle(color: Colors.white, fontSize: 18)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MailboxPage())),
              ),
              GestureDetector(
                onTap: () async {
                  String url = "https://google.com/";
                  try{
                    Uri uri = Uri.parse(url);
                    await launchUrl(
                      uri, mode: LaunchMode.externalApplication,
                    );
                  } catch (ex) {
                    print(ex);
                  }
                },
                child: const Padding(
                  padding: const EdgeInsets.only(left: 25.0),
                  child: ListTile(
                    title: Text('FAQ', style: TextStyle(color: Colors.white, fontSize: 25),),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  String url = "https://google.com/";
                  try{
                    Uri uri = Uri.parse(url);
                    await launchUrl(
                    uri, mode: LaunchMode.externalApplication,
                    );
                  } catch (ex) {
                    print(ex);
                  }
                },
                child: const Padding(
                  padding: const EdgeInsets.only(left: 25.0),
                  child: ListTile(
                    title: Text('Report an issue', style: TextStyle(color: Colors.white, fontSize: 25),),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  String url = "https://google.com/";
                  try{
                    Uri uri = Uri.parse(url);
                    await launchUrl(
                    uri, mode: LaunchMode.externalApplication,
                    );
                  } catch (ex) {
                    print(ex);
                  }
                },
                child: const Padding(
                  padding: const EdgeInsets.only(left: 25.0),
                  child: ListTile(
                    title: Text('About us', style: TextStyle(color: Colors.white, fontSize: 25),),
                  ),
                ),
              ),
              // GestureDetector(
              //   onTap: () => Navigator.push(context,
              //       MaterialPageRoute(builder: (context) => ErrorPage())),
              //   child: const Padding(
              //     padding: const EdgeInsets.only(left: 25.0),
              //     child: ListTile(
              //       title: Text('Error Page', style: TextStyle(color: Colors.white, fontSize: 25),),
              //     ),
              //   ),
              // ),
              GestureDetector(
                onTap: _runConnectionTest,
                child: const Padding(
                  padding: EdgeInsets.only(left: 25.0),
                  child: ListTile(
                    leading: Icon(Icons.health_and_safety, color: Colors.white),
                    title: Text('Test connection', style: TextStyle(color: Colors.white, fontSize: 25),),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  try {
                    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                      googleSignIn.signOut();
                    }
                    objectBox?.removeUserCredential();
                    gettingEmails = false;
                    Future.delayed(const Duration(seconds: 1), () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                    });
                  } catch (ex) {
                    print(ex);
                  }
                },
                child: const Padding(
                  padding: const EdgeInsets.only(left: 25.0),
                  child: ListTile(
                    title: Text('Log out', style: TextStyle(color: Colors.redAccent, fontSize: 25),),
                  ),
                ),
              ),
              // GestureDetector(
              //   onTap: () {
              //     // DateTime testTime = DateTime.now().toUtc().add(Duration(days: 60));
              //     // insertMembershipData("test@test.com", "Free", testTime);
              //     checkIfEmailExists("test1@test.com");
              //   },
              //   child: const Padding(
              //     padding: const EdgeInsets.only(left: 25.0),
              //     child: ListTile(
              //       title: Text('test', style: TextStyle(color: Colors.redAccent, fontSize: 25),),
              //     ),
              //   ),
              // )
            ],
          )
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: MyBottomNavBar(
        onTabChange: (index) => navigationBottomBar(index),
      ),
    );
  }
}
