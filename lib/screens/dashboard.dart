import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_profile.dart';
import '../services/firestore_service.dart';
import 'home_page.dart';
import 'swipe_to_apply_page.dart';
import 'applied_jobs_page.dart';
import 'work_history_page.dart';
import 'profile_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const HomePage(),
          const SwipeToApplyPage(),
           AppliedJobsPage(), 
          const WorkHistoryPage(),
          const ProfilePage(), 
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.swipe), label: 'Swipe'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline), label: 'Applied'),
          const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            label: 'Profile',
            icon: uid == null
                ? const Icon(Icons.person)
                : StreamBuilder<UserProfile?>(
                    stream: FirestoreService().streamUserProfile(uid),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data?.profileImageUrl == null ||
                          snapshot.data!.profileImageUrl!.isEmpty) {
                        return const Icon(Icons.person);
                      }
                      return CircleAvatar(
                        radius: 12,
                        backgroundImage:
                            NetworkImage(snapshot.data!.profileImageUrl!),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
