import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Centralized permission handler for consistent permission requests
class PermissionHandler {
  /// Request camera permission
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();
    
    if (!context.mounted) return false;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        context,
        'Camera Permission Required',
        'Camera permission is permanently denied. Please enable it in app settings.',
        () => openAppSettings(),
      );
      return false;
    }
    
    if (status.isDenied) {
      _showPermissionDialog(
        context,
        'Camera Permission Required',
        'Camera permission is needed to scan documents. Please grant the permission.',
        () => requestCameraPermission(context),
      );
      return false;
    }
    
    return false;
  }

  /// Request storage permissions (handles both old and new Android versions)
  static Future<bool> requestStoragePermission(BuildContext context) async {
    // For Android 13+, we need READ_MEDIA_IMAGES
    // For Android 12 and below, we need READ_EXTERNAL_STORAGE and WRITE_EXTERNAL_STORAGE
    if (await _isAndroid13OrHigher()) {
      final status = await Permission.photos.request();
      
      if (!context.mounted) return false;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isPermanentlyDenied) {
        _showPermissionDialog(
          context,
          'Storage Permission Required',
          'Storage permission is permanently denied. Please enable it in app settings.',
          () => openAppSettings(),
        );
        return false;
      }
      
      if (status.isDenied) {
        _showPermissionDialog(
          context,
          'Storage Permission Required',
          'Storage permission is needed to access and save documents. Please grant the permission.',
          () => requestStoragePermission(context),
        );
        return false;
      }
    } else {
      // For Android 12 and below
      final storageStatus = await Permission.storage.request();
      
      if (!context.mounted) return false;
      
      if (storageStatus.isGranted) {
        return true;
      }
      
      if (storageStatus.isPermanentlyDenied) {
        _showPermissionDialog(
          context,
          'Storage Permission Required',
          'Storage permission is permanently denied. Please enable it in app settings.',
          () => openAppSettings(),
        );
        return false;
      }
      
      if (storageStatus.isDenied) {
        _showPermissionDialog(
          context,
          'Storage Permission Required',
          'Storage permission is needed to access and save documents. Please grant the permission.',
          () => requestStoragePermission(context),
        );
        return false;
      }
    }
    
    return false;
  }

  /// Request multiple permissions at once
  static Future<Map<Permission, PermissionStatus>> requestMultiplePermissions(
    BuildContext context,
    List<Permission> permissions,
  ) async {
    final statuses = await permissions.request();
    
    if (!context.mounted) return statuses;
    
    // Check if any permissions are permanently denied
    final permanentlyDenied = statuses.entries
        .where((entry) => entry.value.isPermanentlyDenied)
        .map((entry) => entry.key)
        .toList();
    
    if (permanentlyDenied.isNotEmpty) {
      _showPermissionDialog(
        context,
        'Permissions Required',
        'Some permissions are permanently denied. Please enable them in app settings.',
        () => openAppSettings(),
      );
    }
    
    return statuses;
  }

  /// Check if a specific permission is granted
  static Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// Check if running on Android 13 or higher
  static Future<bool> _isAndroid13OrHigher() async {
    // This is a simplified check - in production you'd want to use device_info_plus
    // For now, we'll assume we need to handle both cases
    try {
      // Try to request photos permission (Android 13+)
      final status = await Permission.photos.status;
      return status != PermissionStatus.denied;
    } catch (e) {
      return false;
    }
  }

  /// Show permission dialog
  static void _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onAction,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onAction();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  /// Check and request all required permissions
  static Future<bool> checkAndRequestAllPermissions(BuildContext context) async {
    final cameraGranted = await requestCameraPermission(context);
    if (!context.mounted) return false;
    final storageGranted = await requestStoragePermission(context);
    
    return cameraGranted && storageGranted;
  }
}