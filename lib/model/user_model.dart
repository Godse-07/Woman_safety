class UserModel {
  String? id;
  String? name;
  String? number;
  String? child_mail;
  String? parent_email;
  String? type;

  UserModel(
      {this.name,
      this.number,
      this.child_mail,
      this.parent_email,
      this.id,
      this.type});

  Map<String, dynamic> toJson() => {
        'name': name,
        'number': number,
        'mail': child_mail,
        'gemail': parent_email,
        'id': id,
        'type': type,
      };
}
