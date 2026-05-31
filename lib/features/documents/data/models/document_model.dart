import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants.dart';

/// A user's uploaded document and its AI-derived insights.
/// Maps to `users/{uid}/documents/{docId}` in Firestore.
class DocumentModel {
  const DocumentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.sizeBytes,
    required this.status,
    this.pages = 0,
    this.storagePath,
    this.downloadUrl,
    this.summary,
    this.keyPoints = const [],
    this.extractedText = '',
    this.folderId,
    this.favorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String type; // pdf | docx | txt
  final int sizeBytes;
  final DocStatus status;
  final int pages;
  final String? storagePath;
  final String? downloadUrl;
  final String? summary;
  final List<String> keyPoints;
  final String extractedText;
  final String? folderId;
  final bool favorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isReady => status == DocStatus.ready;

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type,
        'sizeBytes': sizeBytes,
        'status': status.name,
        'pages': pages,
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'summary': summary,
        'keyPoints': keyPoints,
        'extractedText': extractedText,
        'folderId': folderId,
        'favorite': favorite,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory DocumentModel.fromMap(String id, Map<String, dynamic> map) {
    return DocumentModel(
      id: id,
      name: (map['name'] ?? 'Untitled') as String,
      type: (map['type'] ?? 'txt') as String,
      sizeBytes: (map['sizeBytes'] ?? 0) as int,
      status: DocStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => DocStatus.ready,
      ),
      pages: (map['pages'] ?? 0) as int,
      storagePath: map['storagePath'] as String?,
      downloadUrl: map['downloadUrl'] as String?,
      summary: map['summary'] as String?,
      keyPoints:
          (map['keyPoints'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      extractedText: (map['extractedText'] ?? '') as String,
      folderId: map['folderId'] as String?,
      favorite: (map['favorite'] ?? false) as bool,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  DocumentModel copyWith({
    String? name,
    DocStatus? status,
    int? pages,
    String? storagePath,
    String? downloadUrl,
    String? summary,
    List<String>? keyPoints,
    String? extractedText,
    String? folderId,
    bool? favorite,
    DateTime? updatedAt,
  }) =>
      DocumentModel(
        id: id,
        name: name ?? this.name,
        type: type,
        sizeBytes: sizeBytes,
        status: status ?? this.status,
        pages: pages ?? this.pages,
        storagePath: storagePath ?? this.storagePath,
        downloadUrl: downloadUrl ?? this.downloadUrl,
        summary: summary ?? this.summary,
        keyPoints: keyPoints ?? this.keyPoints,
        extractedText: extractedText ?? this.extractedText,
        folderId: folderId ?? this.folderId,
        favorite: favorite ?? this.favorite,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
