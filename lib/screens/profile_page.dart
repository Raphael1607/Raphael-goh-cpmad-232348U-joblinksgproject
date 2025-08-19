import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../model/user_profile.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final UserProfile? profile; 

  const ProfilePage({super.key, this.profile});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService(); 

  UserProfile? _profile;
  File? _newProfileImage;
  File? _newResumeFile;

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) {
      _setProfile(widget.profile!);
    } else {
      _loadUserProfile();
    }
  }

  void _setProfile(UserProfile profile) {
    _profile = profile;
    _usernameController.text = profile.username ?? '';
    _phoneController.text = profile.phone ?? '';
    _locationController.text = profile.location ?? '';
    _educationController.text = profile.education ?? '';
    _experienceController.text = profile.experience ?? '';
  }

  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final profile = await _firestoreService.getUserProfile(uid);
      if (profile != null) {
        setState(() => _setProfile(profile));
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newProfileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickResume() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (picked != null && picked.files.single.path != null) {
      setState(() {
        _newResumeFile = File(picked.files.single.path!);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && _profile != null) {
      String? imageUrl = _profile!.profileImageUrl;
      String? resumeUrl = _profile!.resumeUrl;

      if (_newProfileImage != null) {
        final uploadedImageUrl =
            await _firestoreService.uploadProfileImage(_newProfileImage!, _profile!.uid!);
        if (uploadedImageUrl != null) imageUrl = uploadedImageUrl;
      }

      if (_newResumeFile != null) {
        final uploadedResumeUrl =
            await _firestoreService.uploadResumeFile(_newResumeFile!, _profile!.uid!);
        if (uploadedResumeUrl != null) resumeUrl = uploadedResumeUrl;
      }

      final updatedProfile = UserProfile(
        uid: _profile!.uid,
        username: _usernameController.text.trim(),
        email: _profile!.email,
        profileImageUrl: imageUrl,
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        education: _educationController.text.trim(),
        experience: _experienceController.text.trim(),
        resumeUrl: resumeUrl,
      );

      await _firestoreService.updateUserProfile(updatedProfile);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );

      setState(() {
        _profile = updatedProfile;
        _newProfileImage = null;
        _newResumeFile = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.blueGrey.shade700,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _newProfileImage != null
                      ? FileImage(_newProfileImage!)
                      : (_profile!.profileImageUrl != null
                          ? NetworkImage(_profile!.profileImageUrl!)
                          : null) as ImageProvider<Object>?,
                  child: (_newProfileImage == null && _profile!.profileImageUrl == null)
                      ? const Icon(Icons.add_a_photo, size: 50, color: Colors.white70)
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter username' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _educationController,
                decoration: const InputDecoration(
                  labelText: 'Education',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(
                  labelText: 'Experience',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Resume'),
                    onPressed: _pickResume,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _newResumeFile != null
                          ? _newResumeFile!.path.split('/').last
                          : (_profile!.resumeUrl != null
                              ? 'Resume uploaded'
                              : 'No resume uploaded'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Profile',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
