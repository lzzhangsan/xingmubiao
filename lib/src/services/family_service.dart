import 'package:xingmubiao/src/models/family.dart';
import 'package:xingmubiao/src/models/user.dart';

class FamilyService {
  // 模拟家庭数据
  static final List<Family> _families = [
    Family(
      id: 'family1',
      name: '小明的家庭',
      ownerId: 'parent1',
      memberIds: ['parent1', 'child1'],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      invitationCode: 'FAMILY123',
    ),
  ];

  // 模拟用户数据
  static final List<User> _users = [
    User(
      id: 'parent1',
      name: '爸爸',
      email: 'parent@example.com',
      role: 'parent',
      avatarUrl: '',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    User(
      id: 'child1',
      name: '小明',
      email: 'child@example.com',
      role: 'child',
      avatarUrl: '',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
    ),
  ];

  static Future<List<Family>> getFamilies() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    return _families;
  }

  static Future<Family> getFamilyById(String familyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final family = _families.firstWhere((f) => f.id == familyId);
    return family;
  }

  static Future<Family> createFamily(Family family) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _families.add(family);
    return family;
  }

  static Future<void> updateFamily(Family family) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _families.indexWhere((f) => f.id == family.id);
    if (index != -1) {
      _families[index] = family;
    }
  }

  static Future<void> deleteFamily(String familyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _families.removeWhere((f) => f.id == familyId);
  }

  static Future<Family> addMemberToFamily(String familyId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _families.indexWhere((f) => f.id == familyId);
    if (index != -1) {
      final family = _families[index];
      if (!family.memberIds.contains(userId)) {
        family.memberIds.add(userId);
        _families[index] = family;
      }
      return family;
    }
    throw Exception('Family not found');
  }

  static Future<Family> removeMemberFromFamily(String familyId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _families.indexWhere((f) => f.id == familyId);
    if (index != -1) {
      final family = _families[index];
      family.memberIds.remove(userId);
      _families[index] = family;
      return family;
    }
    throw Exception('Family not found');
  }

  static Future<List<User>> getFamilyMembers(String familyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final family = _families.firstWhere((f) => f.id == familyId);
    return _users.where((user) => family.memberIds.contains(user.id)).toList();
  }

  static Future<Family?> getFamilyByInvitationCode(String invitationCode) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _families.firstWhere((f) => f.invitationCode == invitationCode);
    } catch (e) {
      return null;
    }
  }
}