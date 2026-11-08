import '../models/admin_space.dart';

abstract class AdminSpaceRepository {
  Future<List<AdminSpace>> fetchSpaces();

  Future<void> addSpace(AdminSpace space);
}
