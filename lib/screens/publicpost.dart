import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'public post/createpublicpost.dart';

class Publicpost extends StatefulWidget {
  const Publicpost({Key? key}) : super(key: key);

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
      final QuerySnapshot snapshot = await _firestore
          .collection('public_hackathon_posts')
          .orderBy('createdAt', descending: true)
          .get();

      final List<HackathonPost> posts = snapshot.docs
          .map((doc) => HackathonPost.fromDocument(doc))
          .toList();

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
      body: _isLoading
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
              builder: (context) => const CreatePublicPostPage(),
            ),
          ).then((_) => _fetchHackathonPosts());
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHackathonCard(BuildContext context, HackathonPost post) {
    const cardColor = Color(0xFF242424); // Dark card
    const textColor = Color(0xFFE0E0E0); // Light text for dark background
    const primaryColor = Color(0xFF2E7D32); // Green 800

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
              child: Text(
                post.hackathonName,
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
                  const Icon(
                    Icons.people,
                    size: 18,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Team: ${post.teammates.join(", ")}',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: textColor.withOpacity(0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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