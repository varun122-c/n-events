class DepartmentCategory {
  final String categoryName;
  final List<String> departments;

  const DepartmentCategory({
    required this.categoryName,
    required this.departments,
  });
}

class AitsDepartments {
  static const String collegeName =
      'Annamacharya Institute of Technology and Sciences, Tirupati (AITS TPT)';

  /// Undergraduate Departments (B.Tech)
  static const List<String> undergraduateBTech = [
    'Computer Science and Engineering (CSE)',
    'Electronics and Communication Engineering (ECE)',
    'Electrical and Electronics Engineering (EEE)',
    'Artificial Intelligence and Data Science (AI&DS)',
    'Artificial Intelligence and Machine Learning (AI&ML)',
    'Computer Science and Engineering (Data Science)',
    'Computer Science and Information Technology (CS&IT)',
    'Computer Science and Engineering (IoT, Cyber Security including Blockchain Technology)',
    'Mechanical Engineering (ME)',
    'Civil Engineering (CE)',
  ];

  /// Postgraduate & Professional Departments
  static const List<String> postgraduateAndProfessional = [
    'Department of Master of Business Administration (MBA)',
    'Department of Master of Computer Applications (MCA)',
    'M.Tech - Digital Electronics & Communication Systems',
    'M.Tech - Power Systems',
    'M.Tech - Structural Engineering',
    'M.Tech - Production Engineering',
    'M.Tech - Computer Science and Engineering (CSE)',
  ];

  /// Foundation & Sciences Department
  static const List<String> foundationAndSciences = [
    'Department of Humanities and Basic Sciences (H&S)',
  ];

  /// Categorized list of all departments
  static const List<DepartmentCategory> categories = [
    DepartmentCategory(
      categoryName: 'Undergraduate Departments (B.Tech)',
      departments: undergraduateBTech,
    ),
    DepartmentCategory(
      categoryName: 'Postgraduate & Professional Departments',
      departments: postgraduateAndProfessional,
    ),
    DepartmentCategory(
      categoryName: 'Foundation & Sciences Department',
      departments: foundationAndSciences,
    ),
  ];

  /// Flattened list of all academic department names
  static List<String> get allDepartments => [
        ...undergraduateBTech,
        ...postgraduateAndProfessional,
        ...foundationAndSciences,
      ];

  /// Default department for initial selections
  static const String defaultDepartment =
      'Computer Science and Engineering (CSE)';
}
