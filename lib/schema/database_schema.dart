import 'package:supabase_flutter/supabase_flutter.dart';

/// Column names for users table
class Users {
  static const String id = 'id';
  static const String firstName = 'first_name';
  static const String lastName = 'last_name';
  static const String email = 'email';
  static const String profilePictureUrl = 'profile_picture_url';
  static const String preferredLanguage = 'preferred_language';
  static const String dateOfBirth = 'date_of_birth';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String lastLoggedIn = 'last_logged_in';
  static const String isActive = 'is_active';
  static const String isVerified = 'is_verified';
  static const String dataIsTrainable = 'data_is_trainable';
  static const String marketingOptIn = 'marketing_opt_in';
  static const String timezone = 'timezone';
}

class ReportLocations {
  static const String id = 'id';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String address = 'address';
  static const String osmId = 'osm_id';
}

class Reports {
  static const String id = 'id';
  static const String userId = 'user_id';
  static const String severity = 'severity';
  static const String status = 'status';
  static const String isPublic = 'is_public';
  static const String osmWayId = 'osm_way_id';
  static const String locationId = 'location_id';
  static const String submittedAt = 'submitted_at';
  static const String updatedAt = 'updated_at';
  static const String expiredAt = 'expired_at';
  static const String isExpired = 'is_expired';
}

class ReportsTrainable {
  static const String id = 'id';
  static const String reportId = 'report_id';
  static const String severity = 'severity';
  static const String updatedAt = 'updated_at';
}

class ReportContents {
  static const String id = 'id';
  static const String reportId = 'report_id';
  static const String language = 'language';
  static const String reportText = 'report_text';
  static const String audioUrl = 'audio_url';
  static const String mediaUrls = 'media_urls';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

class ReportFlags {
  static const String id = 'id';
  static const String reportId = 'report_id';
  static const String flaggedBy = 'flagged_by';
  static const String reason = 'reason';
  static const String createdAt = 'created_at';
}

/// Database schema definitions and helper methods
class DatabaseSchema {
  /// Table names
  static const String users = 'users';
  static const String reportLocations = 'report_locations';
  static const String reports = 'reports';
  static const String reportContents = 'report_contents';
  static const String reportFlags = 'report_flags';
  static const String reportsTrainable = 'reports_trainable';

  /// Helper method to create a new user record
  static Map<String, dynamic> createUserRecord({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    String? profilePictureUrl,
    String preferredLanguage = 'en',
    required DateTime dateOfBirth,
    required bool dataIsTrainable,
    required bool marketingOptIn,
    required String timezone,
  }) {
    final now = DateTime.now().toIso8601String();
    return {
      Users.id: id,
      Users.firstName: firstName,
      Users.lastName: lastName,
      Users.email: email,
      Users.profilePictureUrl: profilePictureUrl,
      Users.preferredLanguage: preferredLanguage,
      Users.dateOfBirth: dateOfBirth.toIso8601String(),
      Users.createdAt: now,
      Users.updatedAt: now,
      Users.lastLoggedIn: now,
      Users.isActive: true,
      Users.isVerified: false,
      Users.dataIsTrainable: dataIsTrainable,
      Users.marketingOptIn: marketingOptIn,
      Users.timezone: timezone,
    };
  }

  /// Helper method to update user's last login
  static Map<String, dynamic> updateLastLogin() {
    final now = DateTime.now().toIso8601String();
    return {
      Users.lastLoggedIn: now,
      Users.updatedAt: now,
    };
  }

  /// Helper method to verify user
  static Map<String, dynamic> verifyUser() {
    final now = DateTime.now().toIso8601String();
    return {
      Users.isVerified: true,
      Users.updatedAt: now,
    };
  }

  /// Helper method to deactivate user
  static Map<String, dynamic> deactivateUser() {
    final now = DateTime.now().toIso8601String();
    return {
      Users.isActive: false,
      Users.updatedAt: now,
    };
  }

  /// Helper method to reactivate user
  static Map<String, dynamic> reactivateUser() {
    final now = DateTime.now().toIso8601String();
    return {
      Users.isActive: true,
      Users.updatedAt: now,
    };
  }

  /// Helper method to update user profile
  static Map<String, dynamic> updateUserProfile({
    String? firstName,
    String? lastName,
    String? profilePictureUrl,
    String? preferredLanguage,
    DateTime? dateOfBirth,
    String? timezone,
  }) {
    final updates = <String, dynamic>{
      Users.updatedAt: DateTime.now().toIso8601String(),
    };

    if (firstName != null) updates[Users.firstName] = firstName;
    if (lastName != null) updates[Users.lastName] = lastName;
    if (profilePictureUrl != null) updates[Users.profilePictureUrl] = profilePictureUrl;
    if (preferredLanguage != null) updates[Users.preferredLanguage] = preferredLanguage;
    if (dateOfBirth != null) updates[Users.dateOfBirth] = dateOfBirth.toIso8601String();
    if (timezone != null) updates[Users.timezone] = timezone;

    return updates;
  }

  /// Helper method to create a new report location record
  static Map<String, dynamic> createReportLocationRecord({
    required double latitude,
    required double longitude,
    required String address,
    required String osmId,
  }) {
    return {
      ReportLocations.latitude: latitude,
      ReportLocations.longitude: longitude,
      ReportLocations.address: address,
      ReportLocations.osmId: osmId,
    };
  }

  /// Helper method to create a new report record
  static Map<String, dynamic> createReportRecord({
    required String userId,
    required double severity,
    required int status,
    required bool isPublic,
    required String osmWayId,
    required int locationId,
    DateTime? submittedAt,
    DateTime? updatedAt,
    DateTime? expiredAt,
    bool isExpired = false,
  }) {
    final now = DateTime.now().toIso8601String();
    return {
      Reports.userId: userId,
      Reports.severity: severity,
      Reports.status: status,
      Reports.isPublic: isPublic,
      Reports.osmWayId: osmWayId,
      Reports.locationId: locationId,
      Reports.submittedAt: submittedAt?.toIso8601String() ?? now,
      Reports.updatedAt: updatedAt?.toIso8601String() ?? now,
      Reports.expiredAt: expiredAt?.toIso8601String(),
      Reports.isExpired: isExpired,
    };
  }

  /// Helper method to create a new report content record
  static Map<String, dynamic> createReportContentRecord({
    required int reportId,
    required String language,
    required String reportText,
    String? audioUrl,
    String? mediaUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now().toIso8601String();
    return {
      ReportContents.reportId: reportId,
      ReportContents.language: language,
      ReportContents.reportText: reportText,
      ReportContents.audioUrl: audioUrl,
      ReportContents.mediaUrls: mediaUrls,
      ReportContents.createdAt: createdAt?.toIso8601String() ?? now,
      ReportContents.updatedAt: updatedAt?.toIso8601String() ?? now,
    };
  }

  /// Helper method to create a new report flag record
  static Map<String, dynamic> createReportFlagRecord({
    required int reportId,
    required String flaggedBy,
    required String reason,
    DateTime? createdAt,
  }) {
    final now = DateTime.now().toIso8601String();
    return {
      ReportFlags.reportId: reportId,
      ReportFlags.flaggedBy: flaggedBy,
      ReportFlags.reason: reason,
      ReportFlags.createdAt: createdAt?.toIso8601String() ?? now,
    };
  }

  /// Helper method to create a new reports_trainable record
  static Map<String, dynamic> createReportsTrainableRecord({
    required int reportId,
    required int severity,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now().toIso8601String();
    return {
      ReportsTrainable.reportId: reportId,
      ReportsTrainable.severity: severity,
      ReportsTrainable.updatedAt: updatedAt?.toIso8601String() ?? now,
    };
  }
} 