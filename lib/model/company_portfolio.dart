class PortfolioEntry {
  String? userId;                 
  String? companyId;
  String? companyName;
  String? jobTitle;
  String? location;
  List<String>? achievements;
  List<String>? imageUrls;
  String? mainSkill;
  String? description;
  String? projectDuration;

  String? projectTitle;
  String? role;
  List<String>? responsibilities;

  PortfolioEntry({
    this.userId,                
    this.companyId,
    this.companyName,
    this.jobTitle,
    this.location,
    this.achievements,
    this.imageUrls,
    this.mainSkill,
    this.description,
    this.projectDuration,
    this.projectTitle,
    this.role,
    this.responsibilities,
  });

  PortfolioEntry.fromMap(Map<String, dynamic> data) {
    userId = data['userId'];    
    companyId = data['companyId'];
    companyName = data['companyName'];
    jobTitle = data['jobTitle'];
    location = data['location'];
    achievements = List<String>.from(data['achievements'] ?? []);
    imageUrls = List<String>.from(data['imageUrls'] ?? []);
    mainSkill = data['mainSkill'];
    description = data['description'];
    projectDuration = data['projectDuration'];
    projectTitle = data['projectTitle'];
    role = data['role'];
    responsibilities = List<String>.from(data['responsibilities'] ?? []);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,           
      'companyId': companyId,
      'companyName': companyName,
      'jobTitle': jobTitle,
      'location': location,
      'achievements': achievements ?? [],
      'imageUrls': imageUrls ?? [],
      'mainSkill': mainSkill,
      'description': description,
      'projectDuration': projectDuration,
      'projectTitle': projectTitle,
      'role': role,
      'responsibilities': responsibilities ?? [],
    };
  }
}
