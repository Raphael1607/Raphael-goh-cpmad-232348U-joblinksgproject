
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../model/user_profile.dart';
import '../model/applied_job.dart';
import '../model/company.dart';
import '../model/company_portfolio.dart';
import 'firestore_service.dart';

//Stores the raw project info you already use in the app (title, role, skills, achievements, image URLs)
class _ProjectData {
  final PortfolioEntry entry;
  final List<pw.ImageProvider> images;
  _ProjectData({required this.entry, required this.images});
}


//The company document (name, description, duration) used for the job header in the PDF.
class _JobData {
  final Company company;
  final AppliedJob job;
  final List<_ProjectData> projects;
  _JobData({required this.company, required this.job, required this.projects});
}



class PdfService {
  final _fs = FirestoreService();// Reuse your Firestore service to fetch data.

  /// Builds a Work History PDF with organized per-project sections.

  Future<Uint8List> buildWorkHistoryResume({
    required UserProfile profile,// Used for the top header (name/contact).
    required List<AppliedJob> completedJobs,// The jobs to include in the PDF.
    bool detailed = false,
  }) async {
    // Most recent first
    completedJobs.sort((a, b) => (b.completedAt ?? '').compareTo(a.completedAt ?? ''));

    // Fetch companies and portfolio entries
    final companies = <String, Company?>{};
    final portfolios = <String, List<PortfolioEntry>>{};
    final uid = profile.uid ?? '';


  // For each completed job, fetch its Company doc and this user's portfolio entries for that company.
    for (final job in completedJobs) {
      final cid = job.companyId ?? '';
      if (cid.isEmpty) continue;

      companies[cid] = await _fs.getCompanyById(cid);      // Company header/data
      final items = await _fs.getMyPortfolioItemsByCompanyId(companyId: cid, uid: uid);  // Only this user's projects
      portfolios[cid] = items.map((e) => e.entry).toList(); // Keep just the PortfolioEntry
    }

    // Preload images PER project (so build is sync)
    final maxImagesPerProject = detailed ? 6 : 3;
    final jobs = <_JobData>[];


//Loop over each completed job we want to include in the PDF.
    for (final job in completedJobs) {
      final cid = job.companyId ?? '';
      final company = companies[cid];
      if (company == null) continue;


//Look up the cached portfolio entries for this company (cid).
      final entries = portfolios[cid] ?? const <PortfolioEntry>[];
      final projects = <_ProjectData>[];

      for (final e in entries) {

        final urls = (e.imageUrls ?? const <String>[])  
              // If entry has no images, use an empty list (avoid null).
            .where((u) => u.trim().isNotEmpty)

            .take(maxImagesPerProject)
            //make as a List so you can iterate it multiple times if needed.
            .toList();

        final imgs = <pw.ImageProvider>[];
        for (final u in urls) {
          try {
            imgs.add(await networkImage(u));
          } catch (_) {
            // skip failed image loads
          }
        }
        projects.add(_ProjectData(entry: e, images: imgs));
      }

      jobs.add(_JobData(company: company, job: job, projects: projects));
    }

    // Create PDF
    final doc = pw.Document();

//Define some reusable text styles
    final h1 = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);
    final section = pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold);
    final small = pw.TextStyle(fontSize: 10, color: PdfColors.grey700);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('JobLinkSG', style: small),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: small),
          ],
        ),
        build: (context) {
          final widgets = <pw.Widget>[];

          // Header (name, contact, summary)
          widgets.add(_header(profile));
          widgets.add(pw.SizedBox(height: 10));
widgets.add(pw.Divider(color: PdfColors.grey800, thickness: 1.2));
          widgets.add(pw.SizedBox(height: 10));

          widgets.add(pw.Text('Experience', style: h1));
          widgets.add(pw.SizedBox(height: 6));

          for (int i = 0; i < jobs.length; i++) {
            final j = jobs[i];

            // Job header 
            widgets.add(_jobHeader(j.company));
            widgets.add(pw.SizedBox(height: 6));

            // Short job description
            final desc = (j.company.jobDescription ?? '').trim();
            if (desc.isNotEmpty) {
              widgets.add(pw.Text(_truncate(desc, 300), style: const pw.TextStyle(fontSize: 10)));
              widgets.add(pw.SizedBox(height: 8));
            }

            // Per-project blocks
            for (final p in j.projects) {
              widgets.add(_projectBlock(p, section: section));
              widgets.add(pw.SizedBox(height: 10));
            }

            // Divider between companies
            if (i != jobs.length - 1) {
              widgets.add(pw.SizedBox(height: 6));
              widgets.add(pw.Divider(color: PdfColors.black));
              widgets.add(pw.SizedBox(height: 6));
            }
          }

          return widgets;
        },
      ),
    );

    return doc.save();//returns Uint8List
  }

  // ---------- Top header ----------
  pw.Widget _header(UserProfile p) {
    final items = <pw.Widget>[
      pw.Text(
        (p.username ?? 'Your Name').trim().isEmpty ? 'Your Name' : (p.username ?? ''),
        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
      ),
    ];

    void addLine(String? v) {
      if (v != null && v.trim().isNotEmpty) items.add(pw.Text(v.trim()));
    }

    addLine(p.email);
    addLine(p.phone);
    addLine(p.location);

    if ((p.education ?? '').trim().isNotEmpty || (p.experience ?? '').trim().isNotEmpty) {
      items.add(pw.SizedBox(height: 6));
      if ((p.education ?? '').trim().isNotEmpty) {
        items.add(pw.Text('Education: ${p.education!.trim()}', style: const pw.TextStyle(fontSize: 10)));
      }
      if ((p.experience ?? '').trim().isNotEmpty) {
        items.add(pw.Text('Experience: ${p.experience!.trim()}', style: const pw.TextStyle(fontSize: 10)));
      }
    }

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: items);
  }

  // ---------- Job header  ----------
  pw.Widget _jobHeader(Company c) {
    final role = (c.offerDetails?.trim().isNotEmpty ?? false) ? c.offerDetails!.trim() : (c.jobType ?? 'Role');

    final dateBits = <String>[];
    if ((c.startDate ?? '').trim().isNotEmpty) dateBits.add(c.startDate!.trim());
    if ((c.duration ?? '').trim().isNotEmpty) dateBits.add(c.duration!.trim());
    final dateLine = dateBits.join(', ');

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(c.companyName ?? 'Company',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(role, style: const pw.TextStyle(fontSize: 12)),
              if (dateLine.isNotEmpty) pw.Text(dateLine, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- One project block (title to images to skillsto role to responsibilities to achievements) ----------
  pw.Widget _projectBlock(_ProjectData p, {required pw.TextStyle section}) {
    final e = p.entry;
    final title = (e.projectTitle ?? '').trim();

    final widgets = <pw.Widget>[];

    // Project Title
    widgets.add(pw.Text('Project Title', style: section));
    widgets.add(pw.Text(title.isEmpty ? 'Untitled project' : title));
    widgets.add(pw.SizedBox(height: 6));

    // Images
    if (p.images.isNotEmpty) {
      widgets.add(_imageGrid(p.images, perRow: 3));
      widgets.add(pw.SizedBox(height: 6));
    }

    // Skills
    final skills = (e.mainSkill ?? '').trim();
    if (skills.isNotEmpty) {
      widgets.add(pw.Text('Skills', style: section));
      widgets.add(pw.Text(skills));
      widgets.add(pw.SizedBox(height: 4));
    }

    // Role
    final role = (e.role ?? '').trim();
    if (role.isNotEmpty) {
      widgets.add(pw.Text('Role', style: section));
      widgets.add(pw.Text(role));
      widgets.add(pw.SizedBox(height: 4));
    }

    // Responsibilities
    final resp = e.responsibilities ?? const <String>[];
    if (resp.isNotEmpty) {
      widgets.add(pw.Text('Responsibilities', style: section));
      widgets.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: resp.where((s) => s.trim().isNotEmpty).map((s) => pw.Bullet(text: s.trim())).toList(),
        ),
      );
      widgets.add(pw.SizedBox(height: 4));
    }

    // Achievements
    final ach = e.achievements ?? const <String>[];
    if (ach.isNotEmpty) {
      widgets.add(pw.Text('Achievements', style: section));
      widgets.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: ach.where((s) => s.trim().isNotEmpty).map((s) => pw.Bullet(text: s.trim())).toList(),
        ),
      );
    }

    // Descriptio
    final desc = (e.description ?? '').trim();
    if (desc.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 4));
      widgets.add(pw.Text('Description', style: section));
      widgets.add(pw.Text(desc, style: const pw.TextStyle(fontSize: 10)));
    }

    // Timeline 
    final dur = (e.projectDuration ?? '').trim();
    if (dur.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 4));
      widgets.add(pw.Text('Timeline', style: section));
      widgets.add(pw.Text(dur, style: const pw.TextStyle(fontSize: 10)));
    }

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: widgets);
  }

  // ---------- Image grid ----------
  pw.Widget _imageGrid(List<pw.ImageProvider> images, {int perRow = 3}) {
    final cells = images
        .map(
          (img) => pw.Container(
            width: 100,
            height: 70,
            margin: const pw.EdgeInsets.only(right: 6, bottom: 6),
            decoration: pw.BoxDecoration(
              image: pw.DecorationImage(image: img, fit: pw.BoxFit.cover),
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            ),
          ),
        )
        .toList();

    final rows = <pw.Widget>[];
    for (int i = 0; i < cells.length; i += perRow) {
      final end = math.min(i + perRow, cells.length);
      rows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: cells.sublist(i, end),
        ),
      );
    }

    return pw.Column(children: rows);
  }

  // ---------- Helpers ----------
  String _truncate(String s, int maxChars) {
    if (s.length <= maxChars) return s;
    return s.substring(0, maxChars - 1).trimRight() + '…';
  }
}
