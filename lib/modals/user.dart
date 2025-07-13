import 'package:get/get.dart';

class UserAccount {
  var id = ''.obs;
  var name = 'Unknown'.obs;
  var email = 'No Email'.obs;
  var profilePicture = ''.obs;
  var password = '********'.obs;
  var resumes = <Resume>[].obs;

  // Constructor
  UserAccount({
    String? id,
    String? name,
    String? email,
    String? profilePicture,
    String? password,
    List<Resume>? resumes,
  }) {
    this.id.value = id ?? '';
    this.name.value = name ?? 'Unknown';
    this.email.value = email ?? 'No Email';
    this.profilePicture.value = profilePicture ?? '';
    this.password.value = password ?? '';
    if (resumes != null) {
      this.resumes.assignAll(resumes);
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id.value,
      'name': name.value,
      'email': email.value,
      'profilePicture': profilePicture.value,
      'password': password.value,
      'resumes': resumes.map((resume) => resume.toJson()).toList(),
    };
  }

  // Convert from JSON
  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profilePicture: json['profilePicture'],
      password: json['password'],
      resumes:
          (json['resumes'] as List<dynamic>?)
              ?.map((resume) => Resume.fromJson(resume))
              .toList() ??
          [],
    );
  }
}

class Resume {
  var name = 'No data'.obs;
  var email = 'No data'.obs;
  var phone = 'No data'.obs;
  var skills = 'No data'.obs;
  var education = 'No data'.obs;
  var projects = 'No data'.obs;
  var jobRoles = <String>[].obs;

  // Constructor
  Resume({
    String? name,
    String? email,
    String? phone,
    String? skills,
    String? education,
    String? projects,
    List<String>? jobRoles,
  }) {
    this.name.value = name ?? 'No data';
    this.email.value = email ?? 'No data';
    this.phone.value = phone ?? 'No data';
    this.skills.value = skills ?? 'No data';
    this.education.value = education ?? 'No data';
    this.projects.value = projects ?? 'No data';
    if (jobRoles != null) {
      this.jobRoles.assignAll(jobRoles);
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name.value,
      'email': email.value,
      'phone': phone.value,
      'skills': skills.value,
      'education': education.value,
      'projects': projects.value,
      'jobRoles': jobRoles.toList(),
    };
  }

  // Convert from JSON
  factory Resume.fromJson(Map<String, dynamic> json) {
    return Resume(
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      skills: json['skills'],
      education: json['education'],
      projects: json['projects'],
      jobRoles:
          (json['jobRoles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
