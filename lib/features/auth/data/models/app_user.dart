/// A signed-in user. Maps to a Firestore `users/{uid}` document.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.docCount = 0,
    this.questionCount = 0,
    this.storageBytes = 0,
    this.subscription = 'FREE',
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final int docCount;
  final int questionCount;
  final int storageBytes;
  final String subscription;

  /// First letter of the name (or email) for avatar fallbacks.
  String get initial {
    final source = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : email;
    return source.isEmpty ? '?' : source[0].toUpperCase();
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'docCount': docCount,
        'questionCount': questionCount,
        'storageBytes': storageBytes,
        'subscription': subscription,
      };

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        email: (map['email'] ?? '') as String,
        displayName: map['displayName'] as String?,
        photoUrl: map['photoUrl'] as String?,
        docCount: (map['docCount'] ?? 0) as int,
        questionCount: (map['questionCount'] ?? 0) as int,
        storageBytes: (map['storageBytes'] ?? 0) as int,
        subscription: (map['subscription'] ?? 'FREE') as String,
      );

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    int? docCount,
    int? questionCount,
    int? storageBytes,
    String? subscription,
  }) =>
      AppUser(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        docCount: docCount ?? this.docCount,
        questionCount: questionCount ?? this.questionCount,
        storageBytes: storageBytes ?? this.storageBytes,
        subscription: subscription ?? this.subscription,
      );
}
