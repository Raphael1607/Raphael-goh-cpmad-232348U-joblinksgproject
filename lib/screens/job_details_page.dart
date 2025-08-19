import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:location/location.dart';
import 'map_page.dart';

import '../model/applied_job.dart';
import '../model/company.dart';
import '../services/firestore_service.dart';

Future<LocationData?> _geocodeToLocationData(String? address) async {
  if (address == null || address.trim().isEmpty) return null;
  try {
    final results = await geo.locationFromAddress(address);
    if (results.isEmpty) return null;
    final first = results.first;
    return LocationData.fromMap({
      'latitude': first.latitude,
      'longitude': first.longitude,
    });
  } catch (_) {
    return null;
  }
}

class JobDetailsPage extends StatelessWidget {
  final Company company;

  const JobDetailsPage({super.key, required this.company});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Details"),
        backgroundColor: Colors.blueGrey.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: company.id ?? '',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  company.imageUrl ?? '',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              company.offerDetails ?? 'Job Title',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              company.companyName ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        "Start: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Text(
                          company.startDate ?? 'N/A',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        "Duration: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Text(
                          company.duration ?? 'N/A',
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text(
              "Description",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(company.jobDescription ?? 'No description provided.'),
            const SizedBox(height: 16),
            const Text(
              "Contact",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(company.contactEmail ?? 'N/A'),
            const SizedBox(height: 16),
            const Text(
              "Skill & Offer",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text("Skill: ${company.skill ?? 'N/A'}"),
            Text("Offer: ${company.price ?? 'N/A'}"),
            const SizedBox(height: 16),
            const Text(
              "Location",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),

            InkWell(
              onTap: () async {
                final locData = await _geocodeToLocationData(company.location);
                if (locData == null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Couldn't find that address on the map.")),
                  );
                  return;
                }
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapPage(userLocation: locData),
                  ),
                );
              },
              child: Text(
                company.location ?? 'N/A',
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.blueGrey,
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final String userId = FirebaseAuth.instance.currentUser!.uid;

                  final hasApplied =
                      await FirestoreService().hasUserApplied(userId, company.id!);
                  if (hasApplied) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You have already applied to this job.')),
                    );
                    return;
                  }

                  final userProfile =
                      await FirestoreService().getUserProfile(userId);

                  final application = AppliedJob(
                    userId: userId,
                    companyId: company.id,
                    companyName: company.companyName,
                    resumeUrl: userProfile?.resumeUrl ?? '',
                    appliedAt: DateTime.now().toIso8601String(),
                  );

                  await FirestoreService().applyToJob(application);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Application submitted successfully!')),
                  );
                },
                child: const Text(
                  "Apply Now",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
