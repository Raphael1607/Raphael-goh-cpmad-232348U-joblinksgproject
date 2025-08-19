import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/company.dart';
import '../model/applied_job.dart';
import '../model/user_profile.dart';
import '../services/firestore_service.dart';
import 'job_details_page.dart';
import 'about_us_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _searchController = TextEditingController();


  bool _showFilters = true;               
  String _filterJobType = 'All';         
  String _filterIndustry = 'All';        
  final TextEditingController _skillCtrl = TextEditingController();    
  final TextEditingController _locCtrl = TextEditingController();      

  @override
  void dispose() {
    _searchController.dispose();
    _skillCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade700,
        actions: [
          IconButton(
            tooltip: 'About',
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutUsPage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 4),
            child: Text(
              'Welcome to JobLinkSG!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

       
          StreamBuilder<UserProfile?>(
            stream: _firestoreService.streamUserProfile(userId),
            builder: (context, profileSnapshot) {
              if (!profileSnapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Loading profile...'),
                );
              }

              final profile = profileSnapshot.data!;
              final username = profile.username ?? 'User';

              return StreamBuilder<List<AppliedJob>>(
                stream: _firestoreService.streamAppliedJobs(userId),
                builder: (context, jobsSnapshot) {
                  if (!jobsSnapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Loading job stats...'),
                    );
                  }

                  final jobs = jobsSnapshot.data!;
                  int appliedCount = 0;
                  int offeredCount = 0;
                  int rejectedCount = 0;
                  int completedCount = 0;

                  for (int i = 0; i < jobs.length; i++) {
                    final s = jobs[i].status;
                    if (s == 'applied') appliedCount++;
                    else if (s == 'offered') offeredCount++;
                    else if (s == 'rejected') rejectedCount++;
                    else if (s == 'completed') completedCount++;
                  }

                  final totalJobs = appliedCount + offeredCount + rejectedCount + completedCount;
                  double successRate = 0.0;
                  if (totalJobs > 0) successRate = completedCount / totalJobs;

                  return Card(
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hello, $username',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                Row(children: [
                                  const Icon(Icons.send, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Jobs Applied: $appliedCount', style: const TextStyle(fontSize: 14)),
                                ]),
                                const SizedBox(height: 8),
                                Row(children: [
                                  const Icon(Icons.thumb_up, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Offer Received: $offeredCount', style: const TextStyle(fontSize: 14)),
                                ]),
                                const SizedBox(height: 8),
                                Row(children: [
                                  const Icon(Icons.cancel_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Rejected: $rejectedCount', style: const TextStyle(fontSize: 14)),
                                ]),
                                const SizedBox(height: 8),
                                Row(children: [
                                  const Icon(Icons.check_circle_outline, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Completed: $completedCount', style: const TextStyle(fontSize: 14)),
                                ]),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularPercentIndicator(
                                radius: 40.0,
                                lineWidth: 8.0,
                                percent: successRate,
                                center: Text("${(successRate * 100).round()}%"),
                                progressColor: Colors.blueGrey,
                                backgroundColor: Colors.grey.shade300,
                                animation: true,
                                animationDuration: 600,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Success Rate',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          //  For You 
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text(
              'For You',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
          ),

          // Companies + Search
          FutureBuilder<List<Company>>(
            future: _firestoreService.getCompanies(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No companies found.'),
                );
              }

              final companies = snapshot.data!;

              // Search bar -
              final searchBar = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 20, color: Colors.black54),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Search internships…',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) => setState(() {}),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                          child: const Icon(Icons.close, size: 18, color: Colors.black45),
                        ),
                      IconButton(
                        tooltip: _showFilters ? 'Hide filters' : 'Show filters',
                        icon: const Icon(Icons.filter_list),
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );

              // (case-insensitive)
              final List<String> industryOptions = ['All'];
              for (int i = 0; i < companies.length; i++) {
                final ind = companies[i].industry;
                if (ind != null) {
                  final trimmed = ind.trim();
                  if (trimmed.isNotEmpty) {
                    bool exists = false;
                    for (int j = 0; j < industryOptions.length; j++) {
                      if (industryOptions[j].toLowerCase() == trimmed.toLowerCase()) {
                        exists = true;
                        break;
                      }
                    }
                    if (!exists) industryOptions.add(trimmed);
                  }
                }
              }
              
              String industryDropdownValue = 'All';
              for (int i = 0; i < industryOptions.length; i++) {
                if (industryOptions[i].toLowerCase() == _filterIndustry.toLowerCase()) {
                  industryDropdownValue = industryOptions[i];
                  break;
                }
              }

              //  Apply search first 
              final String q = _searchController.text.trim().toLowerCase();
              final List<Company> afterSearch = [];
              if (q.isEmpty) {
                for (int i = 0; i < companies.length; i++) {
                  afterSearch.add(companies[i]);
                }
              } else {
                for (int i = 0; i < companies.length; i++) {
                  final c = companies[i];
                  final fName = (c.companyName ?? '').toLowerCase();
                  final fTitle = (c.offerDetails ?? '').toLowerCase();
                  bool matches = false;
                  if (fName.contains(q) || fTitle.contains(q)) {
                    matches = true;
                  }
                  if (matches) afterSearch.add(c);
                }
              }

              // Then apply filters 
              final List<Company> finalList = [];
              for (int i = 0; i < afterSearch.length; i++) {
                final c = afterSearch[i];

                // Job Type
                bool okJobType = true;
                if (_filterJobType != 'All') {
                  final jt = (c.jobType ?? '').trim().toLowerCase();
                  if (jt != _filterJobType.toLowerCase()) okJobType = false;
                }

                // Industry
                bool okIndustry = true;
                if (_filterIndustry != 'All') {
                  final ind = (c.industry ?? '').trim().toLowerCase();
                  if (ind != _filterIndustry.toLowerCase()) okIndustry = false;
                }

                // Skill contains
                bool okSkill = true;
                final skillQuery = _skillCtrl.text.trim();
                if (skillQuery.isNotEmpty) {
                  final s = (c.skill ?? '').toLowerCase();
                  if (!s.contains(skillQuery.toLowerCase())) okSkill = false;
                }

                // Location contains
                bool okLoc = true;
                final locQuery = _locCtrl.text.trim();
                if (locQuery.isNotEmpty) {
                  final loc = (c.location ?? '').toLowerCase();
                  if (!loc.contains(locQuery.toLowerCase())) okLoc = false;
                }

                if (okJobType && okIndustry && okSkill && okLoc) {
                  finalList.add(c);
                }
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    searchBar,
                    const SizedBox(height: 8),

                    // Inline Filters (show/hide) 
                    if (_showFilters)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Job Type
                            const Text('Job Type', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<String>(
                                value: _filterJobType,
                                isExpanded: true,
                                underline: const SizedBox.shrink(),
                                items: const [
                                  DropdownMenuItem(value: 'All', child: Text('All')),
                                  DropdownMenuItem(value: 'Internship', child: Text('Internship')),
                                  DropdownMenuItem(value: 'Part-time', child: Text('Part-time')),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      _filterJobType = v;
                                    });
                                  }
                                },
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Industry
                            const Text('Industry', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<String>(
                                value: industryDropdownValue,
                                isExpanded: true,
                                underline: const SizedBox.shrink(),
                                items: [
                                  for (int i = 0; i < industryOptions.length; i++)
                                    DropdownMenuItem(
                                      value: industryOptions[i],
                                      child: Text(industryOptions[i]),
                                    ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      _filterIndustry = v;
                                    });
                                  }
                                },
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Skill contains
                            const Text('Skill (contains)', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _skillCtrl,
                              decoration: InputDecoration(
                                hintText: 'e.g. Flutter, AI, Machine Learning',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onChanged: (v) => setState(() {}),
                            ),

                            const SizedBox(height: 12),

                            // Location contains
                            const Text('Location (contains)', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _locCtrl,
                              decoration: InputDecoration(
                                hintText: 'e.g. Singapore, Pasir Panjang',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onChanged: (v) => setState(() {}),
                            ),

                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _filterJobType = 'All';
                                    _filterIndustry = 'All';
                                    _skillCtrl.clear();
                                    _locCtrl.clear();
                                  });
                                },
                                child: const Text('Clear filters'),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (finalList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: Text('No companies match your search or filters.'),
                      ),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 6,
                      childAspectRatio: 0.75,
                      children: finalList.map((company) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JobDetailsPage(company: company),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Hero(
                                tag: company.id ?? '',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    company.imageUrl ?? '',
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                company.companyName ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                company.offerDetails ?? '',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                company.price != null && company.price!.isNotEmpty
                                    ? '${company.price} / ${company.skill ?? 'Skill'}'
                                    : 'Swap Skills',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
