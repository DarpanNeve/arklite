class UserModel {
  String? id;
  String? name;
  String? email;
  DateTime? createdAt;
  
  UserModel({
    this.id,
    this.name,
    this.email,
    this.createdAt,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt,
    };
  }
  
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      createdAt: map['createdAt']?.toDate(),
    );
  }
}

