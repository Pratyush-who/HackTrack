import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class CreatePublicPostPage extends StatefulWidget {
  const CreatePublicPostPage({Key? key}) : super(key: key);

  @override
  State<CreatePublicPostPage> createState() => _CreatePublicPostPageState();
}

class _CreatePublicPostPageState extends State<CreatePublicPostPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  List<XFile> _selectedImages = [];
  List<String> _teammates = [''];
  
  // Form fields
  final TextEditingController _hackathonNameController = TextEditingController();
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectIdeaController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String _mode = 'Offline'; // Default value
  DateTime _date = DateTime.now();
  final TextEditingController _achievementController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _certificateControllers = [TextEditingController()];
  final TextEditingController _githubLinkController = TextEditingController();
  final TextEditingController _linkedinLinkController = TextEditingController();
  final TextEditingController _liveLinkController = TextEditingController();

  @override
  void dispose() {
    _hackathonNameController.dispose();
    _projectNameController.dispose();
    _projectIdeaController.dispose();
    _locationController.dispose();
    _achievementController.dispose();
    _descriptionController.dispose();
    for (var controller in _certificateControllers) {
      controller.dispose();
    }
    _githubLinkController.dispose();
    _linkedinLinkController.dispose();
    _liveLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2E7D32), // Green 800
              onPrimary: Colors.white,
              surface: Color(0xFF242424), // Dark card
              onSurface: Color(0xFFE0E0E0), // Light text
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _addTeammate() {
    setState(() {
      _teammates.add('');
    });
  }

  void _removeTeammate(int index) {
    if (_teammates.length > 1) {
      setState(() {
        _teammates.removeAt(index);
      });
    }
  }

  void _addCertificate() {
    setState(() {
      _certificateControllers.add(TextEditingController());
    });
  }

  void _removeCertificate(int index) {
    if (_certificateControllers.length > 1) {
      setState(() {
        _certificateControllers[index].dispose();
        _certificateControllers.removeAt(index);
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];

    List<String> imageUrls = [];
    try {
      for (var image in _selectedImages) {
        final String fileName = '${const Uuid().v4()}.jpg';
        final Reference storageRef = _storage.ref().child('hackathon_images/$fileName');
        
        final File file = File(image.path);
        final UploadTask uploadTask = storageRef.putFile(file);
        
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        
        imageUrls.add(downloadUrl);
      }
      return imageUrls;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading images: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return [];
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && currentUser != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Upload images first
        final List<String> photoUrls = await _uploadImages();

        // Get certificate URLs
        final List<String> certificates = _certificateControllers
            .map((controller) => controller.text.trim())
            .where((url) => url.isNotEmpty)
            .toList();

        // Create the hackathon post
        final HackathonPost post = HackathonPost(
          id: const Uuid().v4(),
          userId: currentUser!.uid,
          hackathonName: _hackathonNameController.text.trim(),
          teammates: _teammates.where((name) => name.trim().isNotEmpty).toList(),
          projectName: _projectNameController.text.trim(),
          projectIdea: _projectIdeaController.text.trim().isNotEmpty
              ? _projectIdeaController.text.trim()
              : null,
          location: _locationController.text.trim(),
          mode: _mode,
          date: _date,
          achievement: _achievementController.text.trim().isNotEmpty
              ? _achievementController.text.trim()
              : null,
          description: _descriptionController.text.trim(),
          certificates: certificates,
          githubLink: _githubLinkController.text.trim().isNotEmpty
              ? _githubLinkController.text.trim()
              : null,
          linkedinLink: _linkedinLinkController.text.trim().isNotEmpty
              ? _linkedinLinkController.text.trim()
              : null,
          liveLink: _liveLinkController.text.trim().isNotEmpty
              ? _liveLinkController.text.trim()
              : null,
          photoUrls: photoUrls,
          createdAt: DateTime.now(),
        );

        // Save to Firestore
        await _firestore
            .collection('public_hackathon_posts')
            .doc(post.id)
            .set(post.toMap());

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hackathon post created successfully!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E7D32); // Green 800
    const backgroundColor = Color(0xFF121212); // Dark background
    const cardColor = Color(0xFF242424); // Dark card
    const textColor = Color(0xFFE0E0E0); // Light text for dark background
    const errorColor = Color(0xFFCF6679); // Error color for dark theme

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: cardColor,
      hintStyle: GoogleFonts.roboto(color: textColor.withOpacity(0.5)),
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorStyle: GoogleFonts.roboto(color: errorColor),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Create Hackathon Post',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Hackathon Name
                  Text(
                    'Hackathon Name *',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _hackathonNameController,
                    decoration: inputDecoration.copyWith(
                      hintText: 'Enter hackathon name',
                    ),
                    style: GoogleFonts.roboto(color: textColor),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter hackathon name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Project Name
                  Text(
                    'Project Name *',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _projectNameController,
                    decoration: inputDecoration.copyWith(
                      hintText: 'Enter project name',
                    ),
                    style: GoogleFonts.roboto(color: textColor),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter project name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Project Idea (Optional)
                  Text(
                    'Project Idea (Optional)',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _projectIdeaController,
                    decoration: inputDecoration.copyWith(
                      hintText: 'Brief explanation of your project idea',
                    ),
                    style: GoogleFonts.roboto(color: textColor),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Teammates
                  Text(
                    'Team Members *',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: List.generate(
                      _teammates.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: inputDecoration.copyWith(
                                  hintText: index == 0
                                      ? 'Your name'
                                      : 'Team member ${index + 1}',
                                ),
                                style: GoogleFonts.roboto(color: textColor),
                                initialValue: _teammates[index],
                                onChanged: (value) {
                                  _teammates[index] = value;
                                },
                                validator: index == 0
                                    ? (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter at least one team member';
                                        }
                                        return null;
                                      }
                                    : null,
                              ),
                            ),
                            if (_teammates.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: errorColor,
                                ),
                                onPressed: () => _removeTeammate(index),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addTeammate,
                    icon: const Icon(Icons.add, color: primaryColor),
                    label: Text(
                      'Add Team Member',
                      style: GoogleFonts.roboto(color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location
                  Text(
                    'Location *',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationController,
                    decoration: inputDecoration.copyWith(
                      hintText: 'Enter hackathon location',
                    ),
                    style: GoogleFonts.roboto(color: textColor),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter hackathon location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Mode
                  Text(
                    'Mode *',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _mode,
                        dropdownColor: cardColor,
                        isExpanded: true,
                        iconEnabledColor: primaryColor,
                        style: GoogleFonts.roboto(color: textColor),
                        items: <String>['Online', 'Offline', 'Hybrid'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _mode = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date
                  Text(
                    'Date *',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMM dd, yyyy').format(_date),
                            style: GoogleFonts.roboto(color: textColor),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Achievement (Optional)
                  Text(
                    'Achievement (Optional)',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _achievementController,
                    decoration: inputDecoration.copyWith(
                      hintText: 'e.g., Winner, 1st Runner-up, etc.',
                    ),
                    style: GoogleFonts.roboto(color: textColor),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Description *',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: inputDecoration.copyWith(
                      hintText: 'Describe your hackathon experience',
                    ),
                    style: GoogleFonts.roboto(color: textColor),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Certificates
                  Text(
                    'Certificates (Optional)',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: List.generate(
                      _certificateControllers.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _certificateControllers[index],
                                decoration: inputDecoration.copyWith(
                                  hintText: 'Certificate URL',
                                ),
                                style: GoogleFonts.roboto(color: textColor),
                              ),
                            ),
                            if (_certificateControllers.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: errorColor,
                                ),
                                onPressed: () => _removeCertificate(index),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addCertificate,
                    icon: const Icon(Icons.add, color: primaryColor),
                    label: Text(
                      'Add Certificate',
                      style: GoogleFonts.roboto(color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Links
                  Text(
                    'Links (Optional)',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // GitHub Link
                  TextFormField(
                    controller: _githubLinkController,
                    decoration: inputDecoration.copyWith(
                      hintText: 'GitHub Repository URL',
                      prefixIcon: const Icon(Icons.code, color: primaryColor),
                    ),
                    style: GoogleFonts.roboto(color: textColor),
                  ),
                  const SizedBox(height: 8),
                  
                  // LinkedIn Link
                  TextFormField(
                    controller: _linkedinLinkController,
                    decoration: inputDecoration.copyWith(
                      hintText:                      'LinkedIn Post URL',
                      prefixIcon: const Icon(Icons.person, color: primaryColor),
                    ),
                    style: GoogleFonts.roboto(color: textColor),
                  ),
                  const SizedBox(height: 8),
                  
                  // Live Link
                  TextFormField(
                    controller: _liveLinkController,
                    decoration: inputDecoration.copyWith(
                      hintText: 'Live Project URL',
                      prefixIcon: const Icon(Icons.public, color: primaryColor),
                    ),
                    style: GoogleFonts.roboto(color: textColor),
                  ),
                  const SizedBox(height: 16),

                  // Photos
                  Text(
                    'Photos (Optional)',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedImages.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_selectedImages[index].path),
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: errorColor,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library, color: primaryColor),
                    label: Text(
                      _selectedImages.isEmpty
                          ? 'Add Photos'
                          : 'Add More Photos',
                      style: GoogleFonts.roboto(color: primaryColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                  ),
                  ),
                  // Submit Button
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Post Hackathon',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
    const primaryColor = Color(0xFF2E7D32); // Green 800
    const backgroundColor = Color(0xFF121212); // Dark background
    const cardColor = Color(0xFF242424); // Dark card
    const textColor = Color(0xFFE0E0E0); // Light text for dark background

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Hackathon Details',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hackathon Name
            Text(
              post.hackathonName,
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),

            // Date and Location
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: textColor),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(post.date),
                  style: GoogleFonts.roboto(color: textColor),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.location_on, size: 16, color: textColor),
                const SizedBox(width: 4),
                Text(
                  '${post.location} • ${post.mode}',
                  style: GoogleFonts.roboto(color: textColor),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Project Name
            Text(
              'Project: ${post.projectName}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),

            // Team Members
            Text(
              'Team Members',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: post.teammates
                  .map((member) => Chip(
                        label: Text(member),
                        backgroundColor: cardColor,
                        labelStyle: GoogleFonts.roboto(color: textColor),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Project Idea
            if (post.projectIdea != null) ...[
              Text(
                'Project Idea',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post.projectIdea!,
                style: GoogleFonts.roboto(color: textColor),
              ),
              const SizedBox(height: 16),
            ],

            // Achievement
            if (post.achievement != null) ...[
              Text(
                'Achievement',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post.achievement!,
                style: GoogleFonts.roboto(color: textColor),
              ),
              const SizedBox(height: 16),
            ],

            // Description
            Text(
              'Description',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.description,
              style: GoogleFonts.roboto(color: textColor),
            ),
            const SizedBox(height: 16),

            // Certificates
            if (post.certificates.isNotEmpty) ...[
              Text(
                'Certificates',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: post.certificates
                    .map((url) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              // TODO: Open certificate URL
                            },
                            child: Text(
                              url,
                              style: GoogleFonts.roboto(
                                color: primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Links
            if (post.githubLink != null ||
                post.linkedinLink != null ||
                post.liveLink != null) ...[
              Text(
                'Links',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              if (post.githubLink != null)
                ListTile(
                  leading: const Icon(Icons.code, color: primaryColor),
                  title: Text(
                    'GitHub Repository',
                    style: GoogleFonts.roboto(color: textColor),
                  ),
                  subtitle: Text(
                    post.githubLink!,
                    style: GoogleFonts.roboto(
                      color: primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTap: () {
                    // TODO: Open GitHub link
                  },
                ),
              if (post.linkedinLink != null)
                ListTile(
                  leading: const Icon(Icons.person, color: primaryColor),
                  title: Text(
                    'LinkedIn Post',
                    style: GoogleFonts.roboto(color: textColor),
                  ),
                  subtitle: Text(
                    post.linkedinLink!,
                    style: GoogleFonts.roboto(
                      color: primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTap: () {
                    // TODO: Open LinkedIn link
                  },
                ),
              if (post.liveLink != null)
                ListTile(
                  leading: const Icon(Icons.public, color: primaryColor),
                  title: Text(
                    'Live Project',
                    style: GoogleFonts.roboto(color: textColor),
                  ),
                  subtitle: Text(
                    post.liveLink!,
                    style: GoogleFonts.roboto(
                      color: primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTap: () {
                    // TODO: Open live link
                  },
                ),
              const SizedBox(height: 16),
            ],

            // Photos
            if (post.photoUrls.isNotEmpty) ...[
              Text(
                'Photos',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.photoUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          post.photoUrls[index],
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HackathonPost {
  final String id;
  final String userId;
  final String hackathonName;
  final List<String> teammates;
  final String projectName;
  final String? projectIdea;
  final String location;
  final String mode;
  final DateTime date;
  final String? achievement;
  final String description;
  final List<String> certificates;
  final String? githubLink;
  final String? linkedinLink;
  final String? liveLink;
  final List<String> photoUrls;
  final DateTime createdAt;

  HackathonPost({
    required this.id,
    required this.userId,
    required this.hackathonName,
    required this.teammates,
    required this.projectName,
    this.projectIdea,
    required this.location,
    required this.mode,
    required this.date,
    this.achievement,
    required this.description,
    required this.certificates,
    this.githubLink,
    this.linkedinLink,
    this.liveLink,
    required this.photoUrls,
    required this.createdAt,
  });

  factory HackathonPost.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HackathonPost(
      id: doc.id,
      userId: data['userId'],
      hackathonName: data['hackathonName'],
      teammates: List<String>.from(data['teammates']),
      projectName: data['projectName'],
      projectIdea: data['projectIdea'],
      location: data['location'],
      mode: data['mode'],
      date: (data['date'] as Timestamp).toDate(),
      achievement: data['achievement'],
      description: data['description'],
      certificates: List<String>.from(data['certificates'] ?? []),
      githubLink: data['githubLink'],
      linkedinLink: data['linkedinLink'],
      liveLink: data['liveLink'],
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'hackathonName': hackathonName,
      'teammates': teammates,
      'projectName': projectName,
      'projectIdea': projectIdea,
      'location': location,
      'mode': mode,
      'date': date,
      'achievement': achievement,
      'description': description,
      'certificates': certificates,
      'githubLink': githubLink,
      'linkedinLink': linkedinLink,
      'liveLink': liveLink,
      'photoUrls': photoUrls,
      'createdAt': createdAt,
    };
  }
}