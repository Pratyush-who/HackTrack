import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final String userName = "Alex";
  final String userImageUrl = "https://i.pravatar.cc/150?img=11";

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
                    backgroundImage: NetworkImage(userImageUrl),
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
                    'Ready to track your hack',
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
              title: Text(
                'Feed',
                style: GoogleFonts.roboto(color: textColor),
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer
                setState(() => _currentIndex = 0); // Switch to Feed
              },
            ),
            ListTile(
              leading: const Icon(Icons.code, color: accentColor),
              title: Text(
                'Your Hacks',
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
                Navigator.pop(context);
                // Add logout functionality here
                // Example: AuthService().signOut();
              },
            ),
          ],
        ),
      ),
      body: Column(
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
                    'Check out the latest hackathons or manage your submissions',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16,
                      color: textColor.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Navigation Bar
          Container(
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
                      backgroundColor: _currentIndex == 0 ? primaryColor : Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => setState(() => _currentIndex = 0),
                    child: Text(
                      'Feed',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w500,
                        color: _currentIndex == 0 ? textColor : textColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: _currentIndex == 1 ? primaryColor : Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => setState(() => _currentIndex = 1),
                    child: Text(
                      'Your Hacks',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w500,
                        color: _currentIndex == 1 ? textColor : textColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content Area (Switches between Feed and Your Hacks)
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                // Feed Page
                Center(
                  child: Text(
                    'Feed Content - List of Hackathons',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                ),
                // Your Hacks Page
                Center(
                  child: Text(
                    'Your Hacks - Your Submissions',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}