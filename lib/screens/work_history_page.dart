import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'dart:typed_data';


import '../model/company.dart';
import '../model/applied_job.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';
import 'company_portfolio_page.dart';

class WorkHistoryPage extends StatelessWidget {
  const WorkHistoryPage({super.key});

  Future<void> _exportPdf(BuildContext context, List<AppliedJob> completedJobs) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final profile = await FirestoreService().getUserProfile(uid);

      if (profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile not found. Please complete your profile first.')),
        );
        return;
      }

      // Show simple progress while generating
       showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );


// Build the PDF bytes using your PdfService.
    // -profile: for header/contact info
    //  completedJobs: to render experience sections
      final bytes = await PdfService().buildWorkHistoryResume(
        profile: profile,
        completedJobs: completedJobs,
        // detailed: true, // now up to 6 images per project if true if not defualt false 3
      );

      // Close progress
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // open the preveiw pdf pass the bytes
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ResumePreviewScreen(pdfBytes: bytes),
        ),
      );
    } catch (e) {
      // Close progress if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<List<AppliedJob>>(
      stream: FirestoreService().streamCompletedJobs(userId),
      builder: (context, snapshot) {
        final hasData = snapshot.hasData && snapshot.data!.isNotEmpty;
        final completedJobs = hasData ? snapshot.data! : <AppliedJob>[];

        Widget body;
        if (snapshot.connectionState == ConnectionState.waiting) {
          body = const Center(child: CircularProgressIndicator());
        } else if (!hasData) {
          body = const Center(
            child: Text(
              'No completed jobs yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        } else {
          // Group by completed date 
          final Map<String, List<AppliedJob>> groupedJobs = {};
          for (final job in completedJobs) {
            final dt = (job.completedAt != null)
                ? (DateTime.tryParse(job.completedAt!)?.toLocal() ?? DateTime.now())
                : DateTime.now();
            final dateKey = DateFormat('dd MMM yyyy').format(dt);
            groupedJobs.putIfAbsent(dateKey, () => []).add(job);
          }

          final List<Widget> jobWidgets = [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Completed Jobs',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ];

          for (final date in groupedJobs.keys) {
            jobWidgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  date,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
            );

            for (final job in groupedJobs[date]!) {
              jobWidgets.add(
                FutureBuilder<Company?>(
                  future: FirestoreService().getCompanyById(job.companyId ?? ''),
                  builder: (context, companySnap) {
                    if (!companySnap.hasData) return const SizedBox();
                    final company = companySnap.data!;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CompanyPortfolioPage(
                              companyId: job.companyId ?? '',
                              companyName: company.companyName ?? '',
                              jobTitle: company.jobType ?? 'N/A',
                              location: company.location ?? 'N/A',
                            ),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  company.imageUrl ?? '',
                                  height: 70,
                                  width: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      company.companyName ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Duration: ${company.duration ?? 'N/A'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Start Date: ${company.startDate ?? 'N/A'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }
          }

          body = ListView(
            padding: const EdgeInsets.all(12),
            children: jobWidgets,
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Work History'),
            centerTitle: true,
            backgroundColor: Colors.blueGrey.shade700,
            actions: [
              if (hasData)
                IconButton(
                  tooltip: 'Preview & Download PDF',
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () => _exportPdf(context, completedJobs),
                ),
            ],
          ),
          body: body,
        );
      },
    );
  }
}

/// A simple full-screen preview page with an explicit Download/Share button in the app bar.

class _ResumePreviewScreen extends StatelessWidget {

   // The raw PDF file in memory (bytes) that we will preview/share.
  final Uint8List pdfBytes;
  const _ResumePreviewScreen({required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Resume'),
        backgroundColor: Colors.blueGrey.shade700,
        actions: [
          IconButton(
            tooltip: 'Download / Share',
            icon: const Icon(Icons.download),
            onPressed: () async {
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: 'JobLinkSG-Resume.pdf',
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
          // A builder that returns the PDF bytes to display/print.
        build: (format) async => pdfBytes,

        // Lock UI options so users can’t change paper size/orientation here.
        canChangePageFormat: false,
        canChangeOrientation: false,

         // Allow the built-in print and share actions in PdfPreview.
        allowPrinting: true,
        allowSharing: true,

  // Default to A4 paper (from pdf package PdfPageFormat).
        initialPageFormat: PdfPageFormat.a4,
          
            // Suggested filename used by built-in actions.
        pdfFileName: 'JobLinkSG-Resume.pdf',

          canDebug: false, //  hides the switch
      ),
    );
  }
}
