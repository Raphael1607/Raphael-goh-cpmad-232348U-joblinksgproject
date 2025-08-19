import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../model/company_portfolio.dart';
import 'addportfolio_page.dart';

class CompanyPortfolioPage extends StatefulWidget {
  final String companyId;
  final String companyName;
  final String jobTitle;
  final String location;

  const CompanyPortfolioPage({
    super.key,
    required this.companyId,
    required this.companyName,
    required this.jobTitle,
    required this.location,
  });

  @override
  State<CompanyPortfolioPage> createState() => _CompanyPortfolioPageState();
}

class _CompanyPortfolioPageState extends State<CompanyPortfolioPage> {
  final _service = FirestoreService();
  late final String _uid; 
  late Future<List<PortfolioItem>> _future;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    _future = _loadForUser();
  }

  Future<List<PortfolioItem>> _loadForUser() async {
    return _service.getMyPortfolioItemsByCompanyId(
      companyId: widget.companyId,
      uid: _uid,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _loadForUser();
    });
  }

  Future<void> _goToAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PortfolioPage(
          companyId: widget.companyId,
          companyName: widget.companyName,
          jobTitle: widget.jobTitle,
          location: widget.location,
        ),
      ),
    );
    await _reload();
  }

  Future<void> _goToEdit(PortfolioItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PortfolioPage(
          docId: item.id,      
          initial: item.entry, 
          companyId: widget.companyId,
          companyName: widget.companyName,
          jobTitle: widget.jobTitle,
          location: widget.location,
        ),
      ),
    );
    await _reload();
  }

  Future<void> _confirmDelete(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete project?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _service.deletePortfolioEntry(docId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project deleted')),
      );
      await _reload();
    }
  }

  Widget _sectionTitle(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey.shade700, size: 20),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _imageWrap(List<String>? urls) {
    final list = urls ?? <String>[];
    if (list.isEmpty) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.photo_library_outlined, size: 24),
      );
    }

    final List<Widget> children = [];
    for (int i = 0; i < list.length; i++) {
      final u = list[i];
      final Widget img = u.startsWith('http')
          ? Image.network(u, width: 100, height: 100, fit: BoxFit.cover)
          : Image.file(File(u), width: 100, height: 100, fit: BoxFit.cover);
      children.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 100, height: 100, child: img),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: children,
    );
  }

  Widget _skillsWrap(String? mainSkill) {
    if (mainSkill == null || mainSkill.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final List<String> skills = [];
    final parts = mainSkill.split(',');
    for (int i = 0; i < parts.length; i++) {
      final s = parts[i].trim();
      if (s.isNotEmpty) {
        skills.add(s);
      }
    }

    if (skills.isEmpty) return const SizedBox.shrink();

    final List<Widget> chips = [];
    for (int i = 0; i < skills.length; i++) {
      chips.add(
        Chip(
          label: Text(skills[i]),
          avatar: const Icon(Icons.workspace_premium_outlined, size: 16),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _bulletList(List<String> items, {IconData icon = Icons.task_alt, Color? color}) {
    final c = color ?? Colors.indigo;
    final List<Widget> rows = [];

    for (int i = 0; i < items.length; i++) {
      rows.add(
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: c, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(items[i], style: const TextStyle(fontSize: 14, height: 1.4)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _projectCard(PortfolioItem item, int index) {
    final e = item.entry;

    final List<Widget> content = [];

    content.add(
      Row(
        children: [
          Expanded(
            child: Text(
              (e.projectTitle != null && e.projectTitle!.trim().isNotEmpty)
                  ? e.projectTitle!.trim()
                  : 'Project ${index + 1}',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _goToEdit(item),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(item.id),
          ),
        ],
      ),
    );

    content.add(const SizedBox(height: 12));
    content.add(_sectionTitle('Photos', Icons.photo_library_outlined));
    content.add(_imageWrap(e.imageUrls));

    if (e.mainSkill != null && e.mainSkill!.trim().isNotEmpty) {
      content.add(const SizedBox(height: 12));
      content.add(_sectionTitle('Skills', Icons.workspace_premium_outlined));
      content.add(_skillsWrap(e.mainSkill));
    }

    if ((e.role ?? '').isNotEmpty) {
      content.add(const SizedBox(height: 12));
      content.add(_sectionTitle('Role', Icons.badge_outlined));
      content.add(Text(e.role!, style: const TextStyle(fontSize: 14, height: 1.4)));
    }

    if ((e.responsibilities ?? []).isNotEmpty) {
      content.add(const SizedBox(height: 12));
      content.add(_sectionTitle('Responsibilities', Icons.checklist_rtl));
      content.add(_bulletList(e.responsibilities!));
    }

    if ((e.description ?? '').isNotEmpty) {
      content.add(const SizedBox(height: 12));
      content.add(_sectionTitle('Description', Icons.description_outlined));
      content.add(Text(e.description!, style: const TextStyle(fontSize: 14, height: 1.4)));
    }

    if ((e.projectDuration ?? '').isNotEmpty) {
      content.add(const SizedBox(height: 12));
      content.add(_sectionTitle('Timeline', Icons.schedule_outlined));
      content.add(
        Text(
          e.projectDuration!,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );
    }

    if ((e.achievements ?? []).isNotEmpty) {
      content.add(const SizedBox(height: 12));
      content.add(_sectionTitle('Achievements', Icons.verified_outlined));
      content.add(_bulletList(e.achievements!, icon: Icons.check_circle, color: Colors.green));
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.companyName} – Portfolio'),
        backgroundColor: Colors.blueGrey.shade700,
        actions: [
          IconButton(
            tooltip: 'Add project',
            icon: const Icon(Icons.add),
            onPressed: _goToAdd,
          ),
        ],
      ),
      body: FutureBuilder<List<PortfolioItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No projects yet.\nTap the + button to add your first project.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, i) {
                return _projectCard(items[i], i);
              },
            ),
          );
        },
      ),
    );
  }
}
