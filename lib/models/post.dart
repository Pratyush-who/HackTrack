import 'package:cloud_firestore/cloud_firestore.dart';

class HackathonPost {
  final String id;
  final String userId;
  final String userName;
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
    required this.userName,
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
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      hackathonName: data['hackathonName'] ?? '',
      teammates: List<String>.from(data['teammates'] ?? []),
      projectName: data['projectName'] ?? '',
      projectIdea: data['projectIdea'],
      location: data['location'] ?? '',
      mode: data['mode'] ?? 'Offline',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      achievement: data['achievement'],
      description: data['description'] ?? '',
      certificates: List<String>.from(data['certificates'] ?? []),
      githubLink: data['githubLink'],
      linkedinLink: data['linkedinLink'],
      liveLink: data['liveLink'],
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'hackathonName': hackathonName,
      'teammates': teammates,
      'projectName': projectName,
      'projectIdea': projectIdea,
      'location': location,
      'mode': mode,
      'date': Timestamp.fromDate(date),
      'achievement': achievement,
      'description': description,
      'certificates': certificates,
      'githubLink': githubLink,
      'linkedinLink': linkedinLink,
      'liveLink': liveLink,
      'photoUrls': photoUrls,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}