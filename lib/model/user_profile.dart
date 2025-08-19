class UserProfile {
  String? uid;
  String? username;
  String? email;
  String? profileImageUrl;
  String? phone;
  String? location;
  String? education;
  String? experience;
  String? resumeUrl;

  UserProfile({
    this.uid,
    this.username,
    this.email,
    this.profileImageUrl,
    this.phone,
    this.location,
    this.education,
    this.experience,
    this.resumeUrl,
  });

  UserProfile.fromMap(Map<String, dynamic> data) {
    uid = data['uid'];
    username = data['username'];
    email = data['email'];
    profileImageUrl = data['profileImageUrl'];
    phone = data['phone'];
    location = data['location'];
    education = data['education'];
    experience = data['experience'];
    resumeUrl = data['resumeUrl'];
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'phone': phone,
      'location': location,
      'education': education,
      'experience': experience,
      'resumeUrl': resumeUrl,
    };
  }
}
