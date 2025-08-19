class Company {
  String? id;
  String? companyName;
  String? industry;
  String? imageUrl;
  String? offerDetails;
  String? price;
  String? skill;

 
  String? location;
  String? jobType;
  String? startDate;
  String? duration;
  String? contactEmail;
  String? jobDescription;

  Company({
    this.id,
    this.companyName,
    this.industry,
    this.imageUrl,
    this.offerDetails,
    this.price,
    this.skill,
    this.location,
    this.jobType,
    this.startDate,
    this.duration,
    this.contactEmail,
    this.jobDescription,
  });

  Company.fromMap(Map<String, dynamic> data, String docId) {
    id = docId;
    companyName = data['companyName'];
    industry = data['industry'];
    imageUrl = data['companyImage'];
    offerDetails = data['offerDetails'];
    price = data['price'];
    skill = data['skill'];

  
    location = data['location'];
    jobType = data['jobType'];
    startDate = data['startDate'];
    duration = data['duration'];
    contactEmail = data['contactEmail'];
    jobDescription = data['jobDescription'];
  }

  // Map<String, dynamic> toMap() {
  //   return {
  //     'companyName': companyName,
  //     'industry': industry,
  //     'companyImage': imageUrl,
  //     'offerDetails': offerDetails,
  //     'price': price,
  //     'skill': skill,

  
  //     'location': location,
  //     'jobType': jobType,
  //     'startDate': startDate,
  //     'duration': duration,
  //     'contactEmail': contactEmail,
  //     'jobDescription': jobDescription,
  //   };
  // }
}
