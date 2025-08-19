import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../model/applied_job.dart';
import '../model/company.dart';
import '../services/firestore_service.dart';

class AppliedJobsPage extends StatelessWidget {
  AppliedJobsPage({super.key});

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applied Jobs'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade700,
      ),
      body: StreamBuilder<List<AppliedJob>>(
        //// subscribes to live stream
        stream: _firestoreService.streamAppliedJobs(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No jobs applied yet.'));
          }

          final appliedJobs = snapshot.data!;//latest list after each change

          return ListView.builder(
            itemCount: appliedJobs.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final job = appliedJobs[index];

              return FutureBuilder<Company?>(
                future: _firestoreService.getCompanyById(job.companyId!),
                builder: (context, companySnapshot) {
                  if (!companySnapshot.hasData) return const SizedBox();
                  final company = companySnapshot.data!;

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Image.network(
                            company.imageUrl ?? '',
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    company.companyName ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 6),
                                      DropdownButton<String>(
                                        value: job.status,
                                        underline: const SizedBox(),
                                        style: const TextStyle(fontSize: 14, color: Colors.black),
                                        items: const [
                                          DropdownMenuItem(value: 'applied', child: Text('Applied')),
                                          DropdownMenuItem(value: 'offered', child: Text('Offered')),
                                          DropdownMenuItem(value: 'completed', child: Text('Completed')),
                                          DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                                        ],
                                        onChanged: (newStatus) async {
                                          if (newStatus != null) {
                                            if (newStatus == 'completed') {
                                              final completedDate = DateTime.now().toIso8601String();

                                              await _firestoreService.updateApplicationStatusWithDate(
                                                job.applicationId!,
                                                newStatus,
                                                completedDate,
                                              );

                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Job marked as completed! View it in Work History.'),
                                                ),
                                              );
                                            } else {
                                              await _firestoreService.updateApplicationStatus(
                                                job.applicationId!,
                                                newStatus,
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Text('Industry: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(company.industry ?? 'N/A'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('Skill: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(company.skill ?? 'N/A'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('Salary: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(company.price ?? 'N/A'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('Applied: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    job.appliedAt != null
                                        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(job.appliedAt!))
                                        : 'N/A',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
