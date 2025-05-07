import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hacktrack/auth/login.dart';
import 'package:hacktrack/screens/private%20post/privatepost.dart';
import 'package:hacktrack/screens/public%20post/publicpost.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String userName = "User";
  String userImageUrl = "https://i.pravatar.cc/150?img=11";
  final ScrollController _scrollController = ScrollController();
  bool _isTabRowSticky = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _scrollController.addListener(_updateTabRowStickiness);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateTabRowStickiness);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateTabRowStickiness() {
    // Calculate when the tab row should become sticky (based on card height + padding)
    final shouldBeSticky = _scrollController.offset > 130; // Adjust this value as needed
    if (shouldBeSticky != _isTabRowSticky) {
      setState(() {
        _isTabRowSticky = shouldBeSticky;
      });
    }
  }

  Future<void> _loadUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
      currentUser = FirebaseAuth.instance.currentUser;

      setState(() {
        userName = currentUser?.displayName ?? 'User';
        if (currentUser?.photoURL != null) {
          userImageUrl = currentUser!.photoURL!;
        }
      });
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTabRow() {
    const primaryColor = Color(0xFF2E7D32); // Green 800
    const cardColor = Color(0xFF242424); // Dark card
    const textColor = Color(0xFFE0E0E0); // Light text for dark background

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor:
                    _currentIndex == 0 ? primaryColor : Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => setState(() => _currentIndex = 0),
              child: Text(
                'Public Feed',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w500,
                  color: _currentIndex == 0
                      ? textColor
                      : textColor.withOpacity(0.7),
                ),
              ),
            ),
          ),
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor:
                    _currentIndex == 1 ? primaryColor : Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => setState(() => _currentIndex = 1),
              child: Text(
                'Your Personal Hacks',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w500,
                  color: _currentIndex == 1
                      ? textColor
                      : textColor.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E7D32); // Green 800
    const primaryDarkColor = Color(0xFF1B5E20); // Green 900
    const accentColor = Color(0xFF388E3C); // Green 700
    const backgroundColor = Color(0xFF121212); // Dark background
    const surfaceColor = Color(0xFF1E1E1E); // Dark surface
    const cardColor = Color(0xFF242424); // Dark card
    const textColor = Color(0xFFE0E0E0); // Light text for dark background

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Hackathon Tracker',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: primaryDarkColor,
        iconTheme: const IconThemeData(color: textColor),
      ),
      endDrawer: Drawer(
        backgroundColor: surfaceColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage('https://avatars.githubusercontent.com/u/177855155?v=4'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Hi, $userName',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Ready to track your hacks...???',
                    style: GoogleFonts.poppins(
                      color: textColor.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: accentColor),
              title: Text('Feed', style: GoogleFonts.roboto(color: textColor)),
              onTap: () {
                Navigator.pop(context); // Close drawer
                setState(() => _currentIndex = 0); // Switch to Feed
              },
            ),
            ListTile(
              leading: const Icon(Icons.code, color: accentColor),
              title: Text(
                'Your Personal Hacks',
                style: GoogleFonts.roboto(color: textColor),
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer
                setState(() => _currentIndex = 1); // Switch to Your Hacks
              },
            ),
            const Divider(color: Color(0xFF424242)),
            ListTile(
              leading: const Icon(Icons.logout, color: accentColor),
              title: Text(
                'Logout',
                style: GoogleFonts.roboto(color: textColor),
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: cardColor,
                    title: Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to logout?',
                      style: GoogleFonts.roboto(color: textColor),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.roboto(color: accentColor),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          _logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: textColor,
                        ),
                        child: Text(
                          'Logout',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                color: cardColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: primaryColor, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello $userName!',
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save your hackathon memories in one place.',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 16,
                          color: textColor.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Tab row (visible but replaced by sticky version when scrolling)
              Visibility(
                visible: !_isTabRowSticky,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: _buildTabRow(),
              ),
              
              const SizedBox(height: 8),
              
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(height: 8),
                    ),
                    SliverFillRemaining(
                      child: IndexedStack(
                        index: _currentIndex,
                        children: [
                          Publicpost(userName: userName),
                          PrivatePostPage(), // Your Hacks Page
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Sticky tab row that appears when scrolling
          if (_isTabRowSticky)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: backgroundColor,
                child: _buildTabRow(),
              ),
            ),
        ],
      ),
    );
  }
}