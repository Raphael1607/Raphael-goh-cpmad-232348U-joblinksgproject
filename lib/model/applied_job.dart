class AppliedJob {
  String? applicationId;
  String? userId;
  String? companyId;
  String? companyName; 
  String? resumeUrl;
  String? appliedAt;
  String? status;
  String? completedAt; 
  // List<Map<String, dynamic>>? projects; 

  AppliedJob({
    this.applicationId,
    this.userId,
    this.companyId,
    this.companyName,
    this.resumeUrl,
    this.appliedAt,
    this.status = 'applied',
    this.completedAt,

  });

  AppliedJob.fromMap(Map<String, dynamic> data, String docId) {
    applicationId = docId;
    userId = data['userId'];
    companyId = data['companyId'];
    companyName = data['companyName'];
    resumeUrl = data['resumeUrl'];
    appliedAt = data['appliedAt'];
    status = data['status'];
    completedAt = data['completedAt'];
 
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'companyId': companyId,
      'companyName': companyName,
      'resumeUrl': resumeUrl,
      'appliedAt': appliedAt,
      'status': status,
      'completedAt': completedAt,
 
    };
  }
}
