class CollegeCategory {
  final String categoryName;
  final List<String> colleges;

  const CollegeCategory({
    required this.categoryName,
    required this.colleges,
  });
}

class TirupatiColleges {
  static const String otherOption = 'Other';

  /// Government & Public Institutions
  static const List<String> governmentPublic = [
    'IIT Tirupati (Indian Institute of Technology)',
    'SVUCE (Sri Venkateswara University College of Engineering)',
    'SPMVV (Sri Padmavati Mahila Visvavidyalayam - Women\'s University)',
  ];

  /// Private Universities & Engineering Colleges
  static const List<String> privateUniversities = [
    'Annamacharya Institute of Technology and Sciences, Tirupati (AITS TPT)',
    'Mohan Babu University (formerly Sree Vidyanikethan Engineering College)',
    'Sri Venkateswara College of Engineering (SVCE)',
    'Chadalawada Ramanamma Engineering College (CREC)',
    'Sree Rama Engineering College',
    'Siddartha Educational Academy Group of Institutions',
    'KMM Institute of Technology and Science',
    'Priyadarshini Institute of Technology',
    'JB Women\'s Engineering College',
  ];

  /// Categorized list of all institutions
  static const List<CollegeCategory> categories = [
    CollegeCategory(
      categoryName: 'Government & Public Institutions',
      colleges: governmentPublic,
    ),
    CollegeCategory(
      categoryName: 'Private Universities & Engineering Colleges',
      colleges: privateUniversities,
    ),
  ];

  /// Flattened list of all colleges including 'Other' option
  static List<String> get allColleges => [
        ...governmentPublic,
        ...privateUniversities,
        otherOption,
      ];

  /// Default college selection
  static const String defaultCollege =
      'Annamacharya Institute of Technology and Sciences, Tirupati (AITS TPT)';
}
