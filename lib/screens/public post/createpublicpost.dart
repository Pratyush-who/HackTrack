import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hacktrack/models/post.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CreatePublicPostPage extends StatefulWidget {
  final String userName;
  const CreatePublicPostPage({Key? key, required this.userName})
    : super(key: key);

  @override
  State<CreatePublicPostPage> createState() => _CreatePublicPostPageState();
}

class _CreatePublicPostPageState extends State<CreatePublicPostPage> {
  @override
  void initState() {
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  List<XFile> _selectedImages = [];
  List<XFile> _selectedCertificates = [];
  List<String> _teammates = [''];

  final TextEditingController _hackathonNameController =
      TextEditingController();
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectIdeaController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String _mode = 'Offline';
  DateTime _date = DateTime.now();
  final TextEditingController _achievementController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
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

  Future<void> _pickCertificates() async {
    try {
      final List<XFile> certificates = await _imagePicker.pickMultiImage();
      if (certificates.isNotEmpty) {
        setState(() {
          _selectedCertificates.addAll(certificates);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking certificate images: $e'),
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
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
              surface: Color(0xFF242424),
              onSurface: Color(0xFFE0E0E0),
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

  Future<List<String>> _uploadToCloudinary(
    List<XFile> files,
    String folder,
  ) async {
    List<String> uploadedUrls = [];
    try {
      for (var file in files) {
        final mimeType = lookupMimeType(file.path);
        final fileBytes = await file.readAsBytes();

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.cloudinary.com/v1_1/dteigt5oc/image/upload'),
        );

        request.fields['upload_preset'] = 'hacktrack_uploads';
        request.fields['folder'] = folder;

        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: path.basename(file.path),
            contentType: mimeType != null ? MediaType.parse(mimeType) : null,
          ),
        );

        final response = await request.send();
        final responseData = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(responseData);
          uploadedUrls.add(jsonResponse['secure_url']);
        } else {
          throw Exception(
            'Failed to upload: ${response.statusCode} - $responseData',
          );
        }
      }
      return uploadedUrls;
    } catch (e) {
      print('Cloudinary Upload Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      return [];
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && currentUser != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final List<String> photoUrls = await _uploadToCloudinary(
          _selectedImages,
          'hackathon_photos',
        );
        final List<String> certificateUrls = await _uploadToCloudinary(
          _selectedCertificates,
          'hackathon_certificates',
        );

        final HackathonPost post = HackathonPost(
          id: const Uuid().v4(),
          userId: currentUser!.uid,
          userName: widget.userName,
          hackathonName: _hackathonNameController.text.trim(),
          teammates:
              _teammates.where((name) => name.trim().isNotEmpty).toList(),
          projectName: _projectNameController.text.trim(),
          projectIdea:
              _projectIdeaController.text.trim().isNotEmpty
                  ? _projectIdeaController.text.trim()
                  : null,
          location: _locationController.text.trim(),
          mode: _mode,
          date: _date,
          achievement:
              _achievementController.text.trim().isNotEmpty
                  ? _achievementController.text.trim()
                  : null,
          description: _descriptionController.text.trim(),
          certificates: certificateUrls,
          githubLink:
              _githubLinkController.text.trim().isNotEmpty
                  ? _githubLinkController.text.trim()
                  : null,
          linkedinLink:
              _linkedinLinkController.text.trim().isNotEmpty
                  ? _linkedinLinkController.text.trim()
                  : null,
          liveLink:
              _liveLinkController.text.trim().isNotEmpty
                  ? _liveLinkController.text.trim()
                  : null,
          photoUrls: photoUrls,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('public_hackathon')
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
    const primaryColor = Color(0xFF2E7D32);
    const backgroundColor = Color(0xFF121212);
    const cardColor = Color(0xFF242424);
    const textColor = Color(0xFFE0E0E0);
    const errorColor = Color(0xFFCF6679);

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
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 200, // Adjust as needed
                      height: 200, // Adjust as needed
                      child: LoadingAnimationWidget.halfTriangleDot(
                        color: primaryColor,
                        size: 200,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Uploading files...',
                      style: GoogleFonts.roboto(color: textColor, fontSize: 16),
                    ),
                  ],
                ),
              )
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
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
                                    hintText:
                                        index == 0
                                            ? 'Your name'
                                            : 'Team member ${index + 1}',
                                  ),
                                  style: GoogleFonts.roboto(color: textColor),
                                  initialValue: _teammates[index],
                                  onChanged: (value) {
                                    _teammates[index] = value;
                                  },
                                  validator:
                                      index == 0
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
                          items:
                              <String>['Online', 'Offline', 'Hybrid'].map((
                                String value,
                              ) {
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

                    Text(
                      'Certificates (Optional)',
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedCertificates.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedCertificates.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_selectedCertificates[index].path),
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
                                          _selectedCertificates.removeAt(index);
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
                      onPressed: _pickCertificates,
                      icon: const Icon(
                        Icons.add_photo_alternate,
                        color: primaryColor,
                      ),
                      label: Text(
                        _selectedCertificates.isEmpty
                            ? 'Add Certificate Images'
                            : 'Add More Certificate Images',
                        style: GoogleFonts.roboto(color: primaryColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Links (Optional)',
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _githubLinkController,
                      decoration: inputDecoration.copyWith(
                        hintText: 'GitHub Repository URL',
                        prefixIcon: const Icon(Icons.code, color: primaryColor),
                      ),
                      style: GoogleFonts.roboto(color: textColor),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _linkedinLinkController,
                      decoration: inputDecoration.copyWith(
                        hintText: 'LinkedIn Post URL',
                        prefixIcon: const Icon(
                          Icons.person,
                          color: primaryColor,
                        ),
                      ),
                      style: GoogleFonts.roboto(color: textColor),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _liveLinkController,
                      decoration: inputDecoration.copyWith(
                        hintText: 'Live Project URL',
                        prefixIcon: const Icon(
                          Icons.public,
                          color: primaryColor,
                        ),
                      ),
                      style: GoogleFonts.roboto(color: textColor),
                    ),
                    const SizedBox(height: 16),

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
                      icon: const Icon(
                        Icons.photo_library,
                        color: primaryColor,
                      ),
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
                    const SizedBox(height: 24),

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
