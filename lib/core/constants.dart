/// App-wide constants. Magic numbers, keys, and limits live here.
abstract final class AppConstants {
  static const String appName = 'Distill';
  static const String tagline = 'Read less. Understand more.';

  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50MB
  static const List<String> allowedExtensions = ['pdf', 'docx', 'txt'];

  /// Max characters of extracted text sent to the model as context. Keeps
  /// requests within token limits and the free tier friendly.
  static const int maxContextChars = 24000;

  // SharedPreferences keys.
  static const String prefOnboardingSeen = 'onboarding_seen';
  static const String prefThemeMode = 'theme_mode';
}

/// Lifecycle of a document as it moves through the AI pipeline.
enum DocStatus { uploading, extracting, summarizing, ready, error }

extension DocStatusX on DocStatus {
  String get label => switch (this) {
        DocStatus.uploading => 'Uploading',
        DocStatus.extracting => 'Extracting text',
        DocStatus.summarizing => 'Generating AI summary',
        DocStatus.ready => 'Summarized',
        DocStatus.error => 'Failed',
      };

  bool get isProcessing =>
      this == DocStatus.uploading ||
      this == DocStatus.extracting ||
      this == DocStatus.summarizing;
}
