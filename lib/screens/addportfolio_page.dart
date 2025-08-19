import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/company_portfolio.dart';
import '../services/firestore_service.dart';

class PortfolioPage extends StatefulWidget {
  final String companyId;
  final String companyName;
  final String jobTitle;
  final String location;

  final String? docId;
  final PortfolioEntry? initial;

  const PortfolioPage({
    super.key,
    required this.companyId,
    required this.companyName,
    required this.jobTitle,
    required this.location,
    this.docId,
    this.initial,
  });

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final _service = FirestoreService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _achievementController = TextEditingController();
  final _skillController = TextEditingController();
  final _roleController = TextEditingController();
  final _respController = TextEditingController();

  final List<String> _skills = [];
  final List<String> _responsibilities = [];
  final List<String> _achievements = [];

  final List<String> _existingImageUrls = [];
  final List<String> _originalExistingUrls = [];
  final List<File> _newImages = [];

  bool get _isEdit => widget.docId != null;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      final e = widget.initial!;
      _titleController.text = e.projectTitle ?? '';
      _descriptionController.text = e.description ?? '';
      _durationController.text = e.projectDuration ?? '';
      _roleController.text = e.role ?? '';

      // achievements
      final achList = e.achievements ?? [];
      for (int i = 0; i < achList.length; i++) {
        _achievements.add(achList[i]);
      }

      // responsibilities
      final respList = e.responsibilities ?? [];
      for (int i = 0; i < respList.length; i++) {
        _responsibilities.add(respList[i]);
      }

      // skills
      if (e.mainSkill != null && e.mainSkill!.trim().isNotEmpty) {
        final parts = e.mainSkill!.split(',');
        for (int i = 0; i < parts.length; i++) {
          final s = parts[i].trim();
          if (s.isNotEmpty) {
            _skills.add(s);
          }
        }
      }

      // images
      final urls = e.imageUrls ?? [];
      for (int i = 0; i < urls.length; i++) {
        _existingImageUrls.add(urls[i]);
        _originalExistingUrls.add(urls[i]);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _achievementController.dispose();
    _skillController.dispose();
    _roleController.dispose();
    _respController.dispose();
    super.dispose();
  }

  // Images
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _newImages.add(File(picked.path));
      });
    }
  }

  void _removeExistingImage(int i) {
    setState(() {
      _existingImageUrls.removeAt(i);
    });
  }

  void _removeNewImage(int i) {
    setState(() {
      _newImages.removeAt(i);
    });
  }

  // Skills
  void _addSkill() {
    final t = _skillController.text.trim();
    if (t.isEmpty) return;

    bool exists = false;
    for (int i = 0; i < _skills.length; i++) {
      if (_skills[i].toLowerCase() == t.toLowerCase()) {
        exists = true;
        break;
      }
    }

    if (!exists) {
      setState(() {
        _skills.add(t);
      });
    }
    _skillController.clear();
  }

  void _removeSkill(String s) {
    setState(() {
      _skills.remove(s);
    });
  }

  // Responsibilities
  void _addResponsibility() {
    final t = _respController.text.trim();
    if (t.isNotEmpty) {
      setState(() {
        _responsibilities.add(t);
      });
    }
    _respController.clear();
  }

  void _removeResponsibility(int i) {
    setState(() {
      _responsibilities.removeAt(i);
    });
  }

  // Achievements
  void _addAchievement() {
    final t = _achievementController.text.trim();
    if (t.isNotEmpty) {
      setState(() {
        _achievements.add(t);
      });
    }
    _achievementController.clear();
  }

  void _removeAchievement(int i) {
    setState(() {
      _achievements.removeAt(i);
    });
  }

  Future<void> _save() async {
    try {
     
      final uid = FirebaseAuth.instance.currentUser!.uid;

      String? mainSkill;
      if (_skills.isNotEmpty) {
        String buffer = '';
        for (int i = 0; i < _skills.length; i++) {
          buffer += _skills[i];
          if (i != _skills.length - 1) buffer += ', ';
        }
        mainSkill = buffer;
      } else {
        mainSkill = null;
      }

      final entry = PortfolioEntry(
        companyId: widget.companyId,
        companyName: widget.companyName,
        jobTitle: widget.jobTitle,
        location: widget.location,
        mainSkill: mainSkill,
        description: _descriptionController.text.trim(),
        projectDuration: _durationController.text.trim(),
        achievements: _achievements,
        projectTitle: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        role: _roleController.text.trim().isEmpty
            ? null
            : _roleController.text.trim(),
        responsibilities: _responsibilities,
      );

      final List<String> removedUrls = [];
      for (int i = 0; i < _originalExistingUrls.length; i++) {
        final url = _originalExistingUrls[i];
        bool stillThere = false;
        for (int j = 0; j < _existingImageUrls.length; j++) {
          if (_existingImageUrls[j] == url) {
            stillThere = true;
            break;
          }
        }
        if (!stillThere) {
          removedUrls.add(url);
        }
      }

      await _service.upsertMyPortfolioEntry(
        uid: uid,
        companyId: widget.companyId,
        docId: widget.docId,
        entry: entry,
        newFiles: _newImages,
        keepUrls: _existingImageUrls,
        removeUrls: removedUrls,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Portfolio updated' : 'Portfolio saved!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _sectionTitle(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 6),
          const SizedBox.shrink(),
          Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> photoTiles = [];
    for (int i = 0; i < _existingImageUrls.length; i++) {
      final url = _existingImageUrls[i];
      photoTiles.add(
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: url.startsWith('http')
                  ? Image.network(url, width: 100, height: 100, fit: BoxFit.cover)
                  : Image.file(File(url), width: 100, height: 100, fit: BoxFit.cover),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: InkWell(
                onTap: () => _removeExistingImage(i),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }
    for (int i = 0; i < _newImages.length; i++) {
      photoTiles.add(
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(_newImages[i], width: 100, height: 100, fit: BoxFit.cover),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: InkWell(
                onTap: () => _removeNewImage(i),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }
    photoTiles.add(
      InkWell(
        onTap: _pickImage,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Icon(Icons.add_a_photo_outlined, size: 24),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${_isEdit ? "Edit" : "Portfolio"} – ${widget.companyName}'),
        backgroundColor: Colors.blueGrey.shade700,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              _isEdit ? 'Update' : 'Save',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Project Title
          _sectionTitle('Project Title', Icons.title),
          TextField(
            controller: _titleController,
            decoration: _fieldDecoration('Enter a project title'),
          ),
          const SizedBox(height: 16),

          // Photos
          _sectionTitle('Photos', Icons.photo_library_outlined),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: photoTiles,
          ),

          const SizedBox(height: 16),

          // Skills (chips)
          _sectionTitle('Skills', Icons.workspace_premium_outlined),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _skillController,
                decoration: _fieldDecoration('Type a skill and press Add'),
                onSubmitted: (_) => _addSkill(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addSkill,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Add'),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < _skills.length; i++)
                Chip(
                  label: Text(_skills[i]),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => _removeSkill(_skills[i]),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Role
          _sectionTitle('Role', Icons.badge_outlined),
          TextField(
            controller: _roleController,
            decoration: _fieldDecoration('Your role (e.g., Backend Developer)'),
          ),
          const SizedBox(height: 16),

          // Responsibilities
          _sectionTitle('Responsibilities', Icons.checklist_rtl),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _respController,
                decoration: _fieldDecoration('Add a responsibility…'),
                onSubmitted: (_) => _addResponsibility(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addResponsibility,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Add'),
            ),
          ]),
          const SizedBox(height: 8),
          for (int i = 0; i < _responsibilities.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(children: [
                const Icon(Icons.task_alt, color: Colors.indigo, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_responsibilities[i])),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _removeResponsibility(i),
                ),
              ]),
            ),

          const SizedBox(height: 16),

          // Achievements
          _sectionTitle('Achievements', Icons.verified_outlined),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _achievementController,
                decoration: _fieldDecoration('Add a bullet point…'),
                onSubmitted: (_) => _addAchievement(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addAchievement,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Add'),
            ),
          ]),
          const SizedBox(height: 8),
          for (int i = 0; i < _achievements.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_achievements[i])),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _removeAchievement(i),
                ),
              ]),
            ),

          const SizedBox(height: 16),

          // Description
          _sectionTitle('Description (optional)', Icons.description_outlined),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: _fieldDecoration('Include objectives, tech stack, challenges, and impact'),
          ),

          const SizedBox(height: 16),

          // Timeline
          _sectionTitle('Timeline', Icons.schedule_outlined),
          TextField(
            controller: _durationController,
            decoration: _fieldDecoration('e.g. Oct 2025 – Dec 2025 or "3-week sprint"'),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(_isEdit ? 'Update Portfolio' : 'Save Portfolio'),
            ),
          ),
        ]),
      ),
    );
  }
}
