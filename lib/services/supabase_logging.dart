import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseLogging {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> log({
    required String eventType,
    String? description,
    Map<String, dynamic>? metadata,
    int? statusCode,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      await _supabase
          .from('logs')
          .insert({
            'user_id': userId,
            'event_type': eventType,
            'description': description,
            'metadata': metadata,
            'status_code': statusCode,
          });

      if (kDebugMode) {
        print('Logged event: $eventType');
        if (description != null) print('Description: $description');
        if (metadata != null) print('Metadata: $metadata');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging to Supabase: $e');
      }
    }
  }

  /// Log an error event
  static Future<void> logError({
    required String description,
    required int statusCode,
    required String error,
    required String eventType,
    Map<String, dynamic>? metadata,
  }) async {
    final errorMetadata = {
      'error': error.toString(),
      if (error is Error) 'stackTrace': error.stackTrace?.toString(),
      ...?metadata,
    };

    await log(
      eventType: '[Error][$eventType]',
      description: description,
      metadata: errorMetadata,
      statusCode: statusCode,
    );
  }

} 