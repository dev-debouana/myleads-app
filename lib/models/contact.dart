/// Contact entity for the local SQLite database.
class Contact {
  final String id;
  String firstName;
  String lastName;
  String? jobTitle;
  String? company;
  String? phone;
  String? email;
  String? source;
  String? project1;
  String? project1Budget;
  String? project2;
  String? project2Budget;
  String? interest;
  String? notes;
  List<String> tags;
  String status; // 'hot' | 'warm' | 'cold'
  DateTime createdAt;
  DateTime? lastContactDate;
  String? avatarColor;
  String captureMethod; // 'scan' | 'qr' | 'nfc' | 'manual'
  String ownerId; // foreign key to UserAccount.id
  String? photoPath; // local file path to contact photo

  Contact({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.jobTitle,
    this.company,
    this.phone,
    this.email,
    this.source,
    this.project1,
    this.project1Budget,
    this.project2,
    this.project2Budget,
    this.interest,
    this.notes,
    List<String>? tags,
    this.status = 'warm',
    DateTime? createdAt,
    this.lastContactDate,
    this.avatarColor,
    this.captureMethod = 'manual',
    this.ownerId = '',
    this.photoPath,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now();

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  String get subtitle {
    final parts = <String>[];
    if (jobTitle != null && jobTitle!.isNotEmpty) parts.add(jobTitle!);
    if (company != null && company!.isNotEmpty) parts.add(company!);
    return parts.join(' - ');
  }

  Contact copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? jobTitle,
    String? company,
    String? phone,
    String? email,
    String? source,
    String? project1,
    String? project1Budget,
    String? project2,
    String? project2Budget,
    String? interest,
    String? notes,
    List<String>? tags,
    String? status,
    DateTime? createdAt,
    DateTime? lastContactDate,
    String? avatarColor,
    String? captureMethod,
    String? ownerId,
    String? photoPath,
  }) {
    return Contact(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      source: source ?? this.source,
      project1: project1 ?? this.project1,
      project1Budget: project1Budget ?? this.project1Budget,
      project2: project2 ?? this.project2,
      project2Budget: project2Budget ?? this.project2Budget,
      interest: interest ?? this.interest,
      notes: notes ?? this.notes,
      tags: tags ?? List.from(this.tags),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      avatarColor: avatarColor ?? this.avatarColor,
      captureMethod: captureMethod ?? this.captureMethod,
      ownerId: ownerId ?? this.ownerId,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'jobTitle': jobTitle,
        'company': company,
        'phone': phone,
        'email': email,
        'source': source,
        'project1': project1,
        'project1Budget': project1Budget,
        'project2': project2,
        'project2Budget': project2Budget,
        'interest': interest,
        'notes': notes,
        'tags': tags,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'lastContactDate': lastContactDate?.toIso8601String(),
        'avatarColor': avatarColor,
        'captureMethod': captureMethod,
        'ownerId': ownerId,
        'photoPath': photoPath,
      };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        jobTitle: json['jobTitle'] as String?,
        company: json['company'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        source: json['source'] as String?,
        project1: json['project1'] as String?,
        project1Budget: json['project1Budget'] as String?,
        project2: json['project2'] as String?,
        project2Budget: json['project2Budget'] as String?,
        interest: json['interest'] as String?,
        notes: json['notes'] as String?,
        tags: (json['tags'] as List?)?.cast<String>() ?? [],
        status: json['status'] as String? ?? 'warm',
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastContactDate: json['lastContactDate'] != null
            ? DateTime.parse(json['lastContactDate'] as String)
            : null,
        avatarColor: json['avatarColor'] as String?,
        captureMethod: json['captureMethod'] as String? ?? 'manual',
        ownerId: json['ownerId'] as String? ?? '',
        photoPath: json['photoPath'] as String?,
      );
}
