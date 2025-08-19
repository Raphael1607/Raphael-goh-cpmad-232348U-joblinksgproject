import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swipe_cards/swipe_cards.dart';

import '../model/company.dart';
import '../model/applied_job.dart';
import '../services/firestore_service.dart';

class SwipeToApplyPage extends StatefulWidget {
  const SwipeToApplyPage({super.key});

  @override
  State<SwipeToApplyPage> createState() => _SwipeToApplyPageState();
}

class _SwipeToApplyPageState extends State<SwipeToApplyPage> {
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  final FirestoreService _fs = FirestoreService();

  final List<String> _rejectedCompanyIds = [];

  List<Company> _baseCompanies = [];

  bool _loading = true;
  String? _error;

  Company? _lastRejectedCompany;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _baseCompanies = await _fs.getCompanies();
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "Failed to load jobs. Please try again.";
      });
    }
  }

  MatchEngine _buildEngineFor(List<Company> visible) {
    final swipeItems = <SwipeItem>[];
    for (int i = 0; i < visible.length; i++) {
      final company = visible[i];
      swipeItems.add(
        SwipeItem(
          content: company,
          likeAction: () async {
            await _applyToCompany(company);
          },
          nopeAction: () {
            _handleReject(company);
          },
        ),
      );
    }
    return MatchEngine(swipeItems: swipeItems);
  }

  Future<void> _applyToCompany(Company company) async {
    if (company.id == null) return;

    final alreadyApplied = await _fs.hasUserApplied(_userId, company.id!);
    if (alreadyApplied) {
      _removeFromBase(company.id!);
      return;
    }

    final resumeUrl = await _fs.getUserResumeUrlOnly(_userId);

    final application = AppliedJob(
      userId: _userId,
      companyId: company.id,
      companyName: company.companyName,
      resumeUrl: resumeUrl ?? '',
      appliedAt: DateTime.now().toIso8601String(),
    );

    await _fs.applyToJob(application);

    _removeFromBase(company.id!);

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text("Applied successfully")),
      );
    }
  }

  void _handleReject(Company company) {
    if (company.id != null && company.id!.isNotEmpty) {
      bool alreadyRejected = false;
      for (int i = 0; i < _rejectedCompanyIds.length; i++) {
        if (_rejectedCompanyIds[i] == company.id) {
          alreadyRejected = true;
          break;
        }
      }
      if (!alreadyRejected) _rejectedCompanyIds.add(company.id!);
    }

    _lastRejectedCompany = company;

    if (company.id != null) {
      _removeFromBase(company.id!);
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text("Rejected"),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: "UNDO",
          onPressed: _undoReject,
        ),
      ),
    );
  }

  void _undoReject() {
    if (_lastRejectedCompany == null) return;

    final Company c = _lastRejectedCompany!;
    final id = c.id;
    if (id != null) {
      int idx = -1;
      for (int i = 0; i < _rejectedCompanyIds.length; i++) {
        if (_rejectedCompanyIds[i] == id) {
          idx = i;
          break;
        }
      }
      if (idx != -1) _rejectedCompanyIds.removeAt(idx);

      bool exists = false;
      for (int i = 0; i < _baseCompanies.length; i++) {
        if (_baseCompanies[i].id == id) {
          exists = true;
          break;
        }
      }
      if (!exists) {
        _baseCompanies.insert(0, c);
        setState(() {});
      }
    }

    _lastRejectedCompany = null;
  }

  void _removeFromBase(String id) {
    int removeIndex = -1;
    for (int i = 0; i < _baseCompanies.length; i++) {
      if (_baseCompanies[i].id == id) {
        removeIndex = i;
        break;
      }
    }
    if (removeIndex != -1) {
      _baseCompanies.removeAt(removeIndex);
      setState(() {});
    }
  }

  Widget _infoRow({required IconData icon, required String value}) {
    final text = value.isEmpty ? "N/A" : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _labeledRow({required String label, required String? value, IconData? icon}) {
    final text = (value == null || value.isEmpty) ? "N/A" : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 6),
          ],
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _openDetails(Company c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.companyName ?? 'Unknown Company',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (c.jobType != null && c.jobType!.isNotEmpty)
                  _labeledRow(label: "Job Type", value: c.jobType, icon: Icons.work_outline),
                if (c.skill != null && c.skill!.isNotEmpty)
                  _labeledRow(label: "Skill", value: c.skill, icon: Icons.school_outlined),
                if (c.industry != null && c.industry!.isNotEmpty)
                  _labeledRow(label: "Industry", value: c.industry, icon: Icons.business_outlined),

                const SizedBox(height: 12),
                _labeledRow(label: "Location", value: c.location, icon: Icons.location_on_outlined),
                _labeledRow(label: "Start Date", value: c.startDate, icon: Icons.event_outlined),
                _labeledRow(label: "Duration", value: c.duration, icon: Icons.schedule_outlined),
                _labeledRow(label: "Compensation", value: c.price, icon: Icons.payments_outlined),
                _labeledRow(label: "Offer Details", value: c.offerDetails, icon: Icons.description_outlined),
                _labeledRow(label: "Contact", value: c.contactEmail, icon: Icons.mail_outline),

                const SizedBox(height: 12),
                Row(
                  children: const [
                    Icon(Icons.info_outline, size: 18),
                    SizedBox(width: 6),
                    Text("Job Description", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  c.jobDescription == null || c.jobDescription!.isEmpty
                      ? "No description provided."
                      : c.jobDescription!,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Swipe to Apply'),
          centerTitle: true,
          backgroundColor: Colors.blueGrey.shade700,
        ),
        body: Center(
          child: Text(
            _error!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Swipe to Apply'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade700,
      ),
      body: StreamBuilder<List<AppliedJob>>(
        stream: _fs.streamAppliedJobs(_userId),
        builder: (context, snapshot) {
          final appliedIds = <String>{};
          if (snapshot.hasData) {
            final jobs = snapshot.data!;
            for (int i = 0; i < jobs.length; i++) {
              final cid = jobs[i].companyId;
              if (cid != null && cid.isNotEmpty) {
                appliedIds.add(cid);
              }
            }
          }

          final visible = <Company>[];
          for (int i = 0; i < _baseCompanies.length; i++) {
            final c = _baseCompanies[i];
            final id = c.id;
            final bool isApplied = id != null && appliedIds.contains(id);
            final bool isRejected = id != null && _rejectedCompanyIds.contains(id);
            if (!isApplied && !isRejected) {
              visible.add(c);
            }
          }

          if (visible.isEmpty) {
            return const Column(
              children: [
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swipe_right_alt, size: 20),
                    SizedBox(width: 6),
                    Text("Swipe right to apply"),
                    SizedBox(width: 18),
                    Icon(Icons.swipe_left_alt, size: 20),
                    SizedBox(width: 6),
                    Text("Swipe left to reject"),
                  ],
                ),
                SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.work_off_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          "No more jobs to show.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          final matchEngine = _buildEngineFor(visible);

          return Column(
            children: [
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swipe_right_alt, size: 20),
                  SizedBox(width: 6),
                  Text("Swipe right to apply"),
                  SizedBox(width: 18),
                  Icon(Icons.swipe_left_alt, size: 20),
                  SizedBox(width: 6),
                  Text("Swipe left to reject"),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: SwipeCards(
                    matchEngine: matchEngine,
                    itemBuilder: (context, index) {
                      final company = visible[index];

                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (company.imageUrl != null && company.imageUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Image.network(
                                  company.imageUrl!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) {
                                    return Container(
                                      height: 200,
                                      width: double.infinity,
                                      alignment: Alignment.center,
                                      color: Colors.grey.shade300,
                                      child: const Text("Image failed to load"),
                                    );
                                  },
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    company.companyName ?? 'Unknown Company',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),

                                  if (company.jobType != null && company.jobType!.isNotEmpty)
                                    _labeledRow(label: "Job Type", value: company.jobType, icon: Icons.work_outline),
                                  if (company.skill != null && company.skill!.isNotEmpty)
                                    _labeledRow(label: "Skill", value: company.skill, icon: Icons.school_outlined),
                                  if (company.industry != null && company.industry!.isNotEmpty)
                                    _labeledRow(label: "Industry", value: company.industry, icon: Icons.business_outlined),

                                  const SizedBox(height: 8),
                                  _infoRow(icon: Icons.location_on_outlined, value: company.location ?? ""),
                                  _infoRow(icon: Icons.event_outlined, value: "Start: ${company.startDate ?? 'N/A'}"),
                                  _infoRow(icon: Icons.schedule_outlined, value: "Duration: ${company.duration ?? 'N/A'}"),
                                  _infoRow(icon: Icons.payments_outlined, value: company.price ?? "N/A"),

                                  const SizedBox(height: 8),
                                  if (company.jobDescription != null && company.jobDescription!.isNotEmpty)
                                    Text(
                                      company.jobDescription!,
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: () => _openDetails(company),
                                      icon: const Icon(Icons.info_outline),
                                      label: const Text("More details"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onStackFinished: () {
                      setState(() {});
                    },
                    itemChanged: (item, index) {},
                    upSwipeAllowed: false,
                    fillSpace: true,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
