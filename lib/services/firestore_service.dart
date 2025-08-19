import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../model/applied_job.dart';
import '../model/company.dart';
import '../model/company_portfolio.dart';
import '../model/user_profile.dart';

/// Helper wrapper: carry Firestore docId together with the entry data
class PortfolioItem {
  final String id;
  final PortfolioEntry entry;
  PortfolioItem({required this.id, required this.entry});
}

class FirestoreService {
  // ==================== Companies ====================
  final CollectionReference companyCollection =
      FirebaseFirestore.instance.collection('companies');

  Future<List<Company>> getCompanies() async {
    final List<Company> companyList = [];
    final QuerySnapshot snapshot = await companyCollection.get();
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      companyList.add(Company.fromMap(data, doc.id));
    }
    return companyList;
  }

  Future<Company?> getCompanyById(String companyId) async {
    final DocumentSnapshot doc = await companyCollection.doc(companyId).get();
    if (doc.exists) {
      return Company.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // ==================== Profiles ====================
  final CollectionReference profileCollection =
      FirebaseFirestore.instance.collection('profiles');

  Future<void> createUserProfile(UserProfile user) async {
    await profileCollection.doc(user.uid).set(user.toMap());
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final DocumentSnapshot doc = await profileCollection.doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Stream<UserProfile?> streamUserProfile(String uid) {
    return profileCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  Future<void> updateUserProfile(UserProfile user) async {
    await profileCollection.doc(user.uid).update(user.toMap());
  }

  Future<String?> uploadProfileImage(File imageFile, String uid) async {
    try {
      final Reference ref =
          FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
      await ref.putFile(imageFile);
      final String url = await ref.getDownloadURL();
      return url;
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadResumeFile(File file, String uid) async {
    try {
      final String ext = file.path.split('.').last;
      final Reference ref =
          FirebaseStorage.instance.ref().child('resumes/$uid.$ext');
      await ref.putFile(file);
      final String url = await ref.getDownloadURL();
      return url;
    } catch (_) {
      return null;
    }
  }

  /// Get only the resume URL (used by SwipeToApplyPage).
  Future<String?> getUserResumeUrlOnly(String uid) async {
    final user = await getUserProfile(uid);
    return user?.resumeUrl;
    }

  // ==================== Applied Jobs ====================
  final CollectionReference appliedCollection =
      FirebaseFirestore.instance.collection('applied_jobs');

  Future<void> applyToJob(AppliedJob job) async {
    final DocumentReference docRef = appliedCollection.doc();
    await docRef.set(job.toMap());
  }

  Stream<List<AppliedJob>> streamAppliedJobs(String uid) {
    return appliedCollection
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final List<AppliedJob> jobList = [];
      //walks through every document currently matching the query
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        //turn it into your typed model, keeping the Firestore document ID.
        jobList.add(AppliedJob.fromMap(data, doc.id));
      }
      return jobList;
    });
  }

  /// Reactive stream of completed jobs (used by WorkHistoryPage)
  Stream<List<AppliedJob>> streamCompletedJobs(String uid) {
    return appliedCollection
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
      final List<AppliedJob> list = [];
      for (final d in snapshot.docs) {
        list.add(AppliedJob.fromMap(d.data() as Map<String, dynamic>, d.id));
      }
      return list;
    });
  }

  Future<void> updateApplicationStatus(
      String applicationId, String newStatus) async {
    await appliedCollection.doc(applicationId).update({'status': newStatus});
  }

  Future<void> updateApplicationStatusWithDate(
      String applicationId, String newStatus, String completedAt) async {
    await appliedCollection.doc(applicationId).update({
      'status': newStatus,
      'completedAt': completedAt,
    });
  }

  Future<bool> hasUserApplied(String userId, String companyId) async {
    final QuerySnapshot snapshot = await appliedCollection
        .where('userId', isEqualTo: userId)
        .where('companyId', isEqualTo: companyId)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // ==================== Company Portfolio  ====================
  final CollectionReference portfolioCollection =
      FirebaseFirestore.instance.collection('company_portfolios');

  /// Read only this user's entries for a company
  Future<List<PortfolioItem>> getMyPortfolioItemsByCompanyId({
    required String companyId,
    required String uid,
  }) async {
    final QuerySnapshot snapshot = await portfolioCollection
        .where('companyId', isEqualTo: companyId)
        .where('userId', isEqualTo: uid)
        .get();

    final List<PortfolioItem> items = [];
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      items.add(PortfolioItem(id: doc.id, entry: PortfolioEntry.fromMap(data)));
    }
    return items;
  }

  /// Delete an entry (used by CompanyPortfolioPage)
  Future<void> deletePortfolioEntry(String docId) async {
    await portfolioCollection.doc(docId).delete();
  }

  // ==================== Storage helpers for portfolio images ====================
  Future<List<String>> uploadPortfolioImages({
    required String companyId,
    required String docId,
    required List<File> files,
  }) async {
    final FirebaseStorage storage = FirebaseStorage.instance;
    final List<String> urls = [];

    for (int i = 0; i < files.length; i++) {
      final File file = files[i];
      final int ts = DateTime.now().millisecondsSinceEpoch;
      final String path = 'company_portfolios/$companyId/$docId/${ts}_$i.jpg';

      final Reference ref = storage.ref().child(path);
      await ref.putFile(file);
      final String url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  Future<void> deleteStorageFileFromUrl(String downloadUrl) async {
    try {
      final Reference ref = FirebaseStorage.instance.refFromURL(downloadUrl);
      await ref.delete();
    } catch (_) {
      // ignore if not found or not our bucket
    }
  }

  // ==================== One-call create/update with uploads  ====================
  Future<void> upsertMyPortfolioEntry({
    required String uid,
    required String companyId,
    String? docId,
    required PortfolioEntry entry,
    required List<File> newFiles,
    required List<String> keepUrls,
    List<String> removeUrls = const [],
  }) async {
    // Ensure we have a document ID to upload under
    DocumentReference docRef;
    if (docId == null) {
      docRef = portfolioCollection.doc();
    } else {
      docRef = portfolioCollection.doc(docId);
    }
    final String resolvedId = docRef.id;

    // 1) Upload new images (if any)
    List<String> uploadedUrls = [];
    if (newFiles.isNotEmpty) {
      uploadedUrls = await uploadPortfolioImages(
        companyId: companyId,
        docId: resolvedId,
        files: newFiles,
      );
    }

    // 2) Delete any images the user removed (when editing)
    if (removeUrls.isNotEmpty) {
      for (final url in removeUrls) {
        await deleteStorageFileFromUrl(url);
      }
    }

    // 3) Merge URLs we keep + newly uploaded URLs
    final List<String> mergedUrls = List<String>.from(keepUrls);
    for (final u in uploadedUrls) {
      mergedUrls.add(u);
    }
    entry.imageUrls = mergedUrls;

    // 4) Save with userId stamped
    final Map<String, dynamic> data = entry.toMap();
    data['userId'] = uid;

    if (docId == null) {
      await docRef.set(data);
    } else {
      await docRef.update(data);
    }
  }
}
