class Family {
  final String id;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final DateTime createdAt;
  final String? invitationCode;

  Family({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberIds,
    required this.createdAt,
    this.invitationCode,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['ownerId'] as String,
      memberIds: List<String>.from(json['memberIds'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      invitationCode: json['invitationCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'invitationCode': invitationCode,
    };
  }
}