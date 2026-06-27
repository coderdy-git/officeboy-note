import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../auth/google_auth_service.dart';
import '../database/database.dart';

/// Custom HTTP client that injects auth headers into every request.
class _AuthClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _headers;

  _AuthClient(this._inner, this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

/// Service for backup/restore to Google Drive.
class GoogleDriveService {
  final GoogleAuthService _authService;
  final AppDatabase _db;

  GoogleDriveService(this._authService, this._db);

  static const _folderName = 'OfficeBoyNote-Backups';
  static const _fileNamePrefix = 'office_boy_backup';

  /// Build an authenticated Drive API client.
  Future<drive.DriveApi> _getDriveApi() async {
    final headers = await _authService.getAuthHeaders();
    final client = _AuthClient(http.Client(), headers);
    return drive.DriveApi(client);
  }

  /// Find or create the backup folder on Google Drive.
  Future<String> _getBackupFolderId(drive.DriveApi api) async {
    // Search for existing folder
    final existing = await api.files.list(
      q: "mimeType='application/vnd.google-apps.folder' and name='$_folderName' and trashed=false",
      spaces: 'drive',
      pageSize: 1,
    );

    if (existing.files?.isNotEmpty ?? false) {
      return existing.files!.first.id!;
    }

    // Create new folder
    final folder = drive.File()
      ..name = _folderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final created = await api.files.create(folder);
    return created.id!;
  }

  /// Backup all attendance records to Google Drive (overwrite existing).
  Future<String> backup() async {
    final api = await _getDriveApi();
    final folderId = await _getBackupFolderId(api);

    // Export database records to JSON
    final allData = await _db.exportAllData();
    final now = DateTime.now();

    final jsonString = const JsonEncoder.withIndent('  ').convert({
      'exportedAt': now.toIso8601String(),
      'recordCount': (allData['attendance'] as List).length + (allData['staffs'] as List).length,
      'records': allData,
    });

    final jsonBytes = utf8.encode(jsonString);
    final media = drive.Media(
      Stream.value(jsonBytes),
      jsonBytes.length,
      contentType: 'application/json',
    );
    
    final fileName = '$_fileNamePrefix.json';

    // Cari file backup lama
    final existingFiles = await api.files.list(
      q: "name = '$fileName' and '$folderId' in parents and trashed=false",
      spaces: 'drive',
      pageSize: 1,
    );

    if (existingFiles.files?.isNotEmpty ?? false) {
      // Update file yang sudah ada
      final existingFileId = existingFiles.files!.first.id!;
      await api.files.update(
        drive.File(),
        existingFileId,
        uploadMedia: media,
      );
      return fileName;
    } else {
      // Buat file baru jika belum ada
      final file = drive.File()
        ..name = fileName
        ..parents = [folderId]
        ..mimeType = 'application/json';

      await api.files.create(
        file,
        uploadMedia: media,
      );
      return fileName;
    }
  }

  /// Restore from the latest backup on Google Drive.
  Future<Map<String, dynamic>?> restore() async {
    final api = await _getDriveApi();

    // Cari file backup
    final files = await api.files.list(
      q: "name = '${_fileNamePrefix}.json' and trashed=false",
      orderBy: 'createdTime desc',
      pageSize: 1,
      spaces: 'drive',
    );

    if (files.files?.isEmpty ?? true) {
      // Coba cari file backup format lama jika format baru tidak ada
      final oldFiles = await api.files.list(
        q: "mimeType='application/json' and name contains '$_fileNamePrefix' and trashed=false",
        orderBy: 'createdTime desc',
        pageSize: 1,
        spaces: 'drive',
      );
      if (oldFiles.files?.isEmpty ?? true) {
        return null;
      }
      files.files = oldFiles.files;
    }

    final backupFile = files.files!.first;

    // Download file content
    final media = await api.files.get(
      backupFile.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final List<int> bytes = [];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    
    final String content = utf8.decode(bytes);
    final Map<String, dynamic> data = jsonDecode(content) as Map<String, dynamic>;
    final recordsData = data['records'];
    
    int imported = 0;
    if (recordsData is Map<String, dynamic>) {
      // New format (Map containing attendance and staffs)
      imported = await _db.importAllData(recordsData);
    } else if (recordsData is List) {
      // Legacy format (List of attendance records)
      final legacyList = recordsData.cast<Map<String, dynamic>>();
      imported = await _db.importRecords(legacyList);
    }

    return {
      'importedCount': imported,
      'backupName': backupFile.name ?? '',
      'totalRecords': imported,
    };
  }

  /// List available backup files on Google Drive.
  Future<List<Map<String, String>>> listBackups() async {
    final api = await _getDriveApi();

    final result = await api.files.list(
      q: "mimeType='application/json' and name contains '$_fileNamePrefix' and trashed=false",
      orderBy: 'createdTime desc',
      pageSize: 20,
      spaces: 'drive',
    );

    return (result.files ?? [])
        .map((f) => <String, String>{
              'id': f.id ?? '',
              'name': f.name ?? '',
              'createdTime': f.createdTime?.toIso8601String() ?? '',
            })
        .toList();
  }
}
