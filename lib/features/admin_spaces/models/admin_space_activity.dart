class AdminSpaceActivity {
  const AdminSpaceActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.actor = '관리자',
  });

  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final String actor;
}
