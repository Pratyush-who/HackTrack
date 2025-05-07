import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hacktrack/models/post.dart';
import 'package:intl/intl.dart';

import 'createpublicpost.dart';

class Publicpost extends StatefulWidget {
  final String userName;
  const Publicpost({Key? key, required this.userName}) : super(key: key);

  @override
  State<Publicpost> createState() => _PublicpostState();
}

class _PublicpostState extends State<Publicpost> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  List<HackathonPost> _hackathonPosts = [];

  @override
  void initState() {
    super.initState();
    _fetchHackathonPosts();
  }

  Future<void> _fetchHackathonPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('public_hackathon_posts')
              .orderBy('createdAt', descending: true)
              .get();

      final List<HackathonPost> posts =
          snapshot.docs.map((doc) => HackathonPost.fromDocument(doc)).toList();

      setState(() {
        _hackathonPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching posts: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E7D32); // Green 800
    const backgroundColor = Color(0xFF121212); // Dark background
    const cardColor = Color(0xFF242424); // Dark card
    const textColor = Color(0xFFE0E0E0); // Light text for dark background

    return Scaffold(
      backgroundColor: backgroundColor,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
              : _hackathonPosts.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.code_off,
                      size: 64,
                      color: textColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hackathon posts yet!',
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to share your hackathon experience',
                      style: GoogleFonts.poppins(
                        color: textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                color: primaryColor,
                onRefresh: _fetchHackathonPosts,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _hackathonPosts.length,
                  itemBuilder: (context, index) {
                    final post = _hackathonPosts[index];
                    return _buildHackathonCard(context, post);
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CreatePublicPostPage(userName: widget.userName),
            ),
          ).then((_) => _fetchHackathonPosts());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHackathonCard(BuildContext context, HackathonPost post) {
    const cardColor = Color(0xFF242424);
    const textColor = Color(0xFFE0E0E0);
    const primaryColor = Color(0xFF2E7D32);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HackathonDetailPage(post: post),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with hackathon name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.hackathonName,
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        'Posted by: ${post.userName}',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Project name
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Project: ${post.projectName}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            // Team members
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.people, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Team: ${post.teammates.join(", ")}',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: textColor.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Location and date
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 18,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            post.location,
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: textColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(post.date),
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Show image if available
            if (post.photoUrls.isNotEmpty)
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(post.photoUrls[0]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HackathonDetailPage extends StatelessWidget {
  final HackathonPost post;

  const HackathonDetailPage({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E7D32);
    const backgroundColor = Color(0xFF121212);
    const cardColor = Color(0xFF242424);
    const textColor = Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          post.hackathonName,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project name
            Text(
              post.projectName,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 16),

            // Basic info card
            Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Team
                    Row(
                      children: [
                        const Icon(Icons.people, color: primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Team: ${post.teammates.join(", ")}',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Location: ${post.location}',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Mode
                    Row(
                      children: [
                        Icon(
                          post.mode == 'Online'
                              ? Icons.computer
                              : Icons.people_outline,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Mode: ${post.mode}',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Date
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: primaryColor),
                        const SizedBox(width: 12),
                        Text(
                          'Date: ${DateFormat('MMMM dd, yyyy').format(post.date)}',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),

                    // Achievement if exists
                    if (post.achievement != null &&
                        post.achievement!.isNotEmpty)
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Achievement: ${post.achievement}',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Project Idea if exists
            if (post.projectIdea != null && post.projectIdea!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Project Idea',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: cardColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        post.projectIdea!,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: textColor.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            // Description
            const SizedBox(height: 24),
            Text(
              'Description',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  post.description,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: textColor.withOpacity(0.9),
                  ),
                ),
              ),
            ),

            // Links if any
            if (post.githubLink != null ||
                post.linkedinLink != null ||
                post.liveLink != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Links',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: cardColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (post.githubLink != null &&
                              post.githubLink!.isNotEmpty)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.code,
                                color: primaryColor,
                              ),
                              title: Text(
                                'GitHub Repository',
                                style: GoogleFonts.roboto(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                post.githubLink!,
                                style: GoogleFonts.roboto(
                                  color: primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              onTap: () {
                                // Launch GitHub URL
                              },
                            ),
                          if (post.linkedinLink != null &&
                              post.linkedinLink!.isNotEmpty)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.person,
                                color: primaryColor,
                              ),
                              title: Text(
                                'LinkedIn Post',
                                style: GoogleFonts.roboto(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                post.linkedinLink!,
                                style: GoogleFonts.roboto(
                                  color: primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              onTap: () {
                                // Launch LinkedIn URL
                              },
                            ),
                          if (post.liveLink != null &&
                              post.liveLink!.isNotEmpty)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.public,
                                color: primaryColor,
                              ),
                              title: Text(
                                'Live Project',
                                style: GoogleFonts.roboto(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                post.liveLink!,
                                style: GoogleFonts.roboto(
                                  color: primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              onTap: () {
                                // Launch Live URL
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            // Photos gallery
            if (post.photoUrls.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Photos',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: post.photoUrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: GestureDetector(
                              onTap: () {
                                // Full-screen image view
                              },
                              child: Image.network(
                                post.photoUrls[index],
                                width: 240,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

            // Certificates gallery
            if (post.certificates.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Certificates',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: post.certificates.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: GestureDetector(
                              onTap: () {
                                // Full-screen certificate view
                              },
                              child: Image.network(
                                post.certificates[index],
                                width: 240,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
