# Save File Backup and Recovery System

This document explains how to use the comprehensive backup and recovery system implemented for the basketball manager game.

## Overview

The backup system provides:
- Automatic backup creation during save operations
- Manual backup creation on demand
- Save file validation and corruption detection
- Recovery from backup files
- Export/import with validation
- Cleanup of old backups

## Core Components

### SaveBackupService
The main service handling all backup operations:
- `createAutomaticBackup()` - Creates backups automatically based on time intervals
- `createManualBackup()` - Creates backups on user request
- `validateSaveFile()` - Checks save file integrity
- `recoverFromBackup()` - Restores save from backup
- `exportSaveWithValidation()` - Exports save with validation data
- `importSaveWithValidation()` - Imports save with validation checks

### SaveManager Integration
The SaveManager class has been enhanced with backup functionality:
- `createBackup()` - Creates manual backup
- `validateSave()` - Validates save file
- `recoverSave()` - Recovers from backup
- `getBackups()` - Lists available backups

### SaveRecoveryWidget
UI component for managing save recovery:
- Displays save validation status
- Shows available backups
- Provides recovery options
- Handles backup creation

## Usage Examples

### Basic Backup Creation
```dart
final saveManager = SaveManager();

// Create manual backup
final backupId = await saveManager.createBackup(saveId, userId);

// Validate save
final validationResult = await saveManager.validateSave(saveId, userId);

if (!validationResult.isValid) {
  // Handle validation errors
  print('Save has issues: ${validationResult.errors}');
}
```

### Recovery from Corruption
```dart
// Attempt to load save with automatic recovery
try {
  final gameState = await saveManager.loadSave(saveId, userId);
} catch (e) {
  if (e.toString().contains('corrupted')) {
    // Save was corrupted and recovered
    // Handle the recovered save ID from the exception message
  }
}

// Manual recovery
final recoveredSaveId = await saveManager.recoverSave(saveId, userId);
```

### Export/Import with Validation
```dart
// Export save
await saveManager.exportSave(saveId, '/path/to/export.json', userId);

// Import save
final newSaveId = await saveManager.importSave('/path/to/import.json', userId);
```

### Using the Recovery Widget
```dart
SaveRecoveryWidget(
  saveId: 'your_save_id',
  userId: 'user_id',
  validationResult: validationResult, // Optional
  onRecoveryComplete: () {
    // Handle recovery completion
  },
)
```

## Validation Levels

The system uses different corruption levels:

- **None**: Save file is completely valid
- **Minor**: Small issues that don't affect functionality
- **Moderate**: Issues that may cause problems but save is still usable
- **Severe**: Major corruption requiring recovery
- **Missing**: Save file not found

## Backup Types

- **Automatic**: Created automatically during save operations (max once per 24 hours)
- **Manual**: Created on user request
- **PreUpdate**: Created before major game updates (future use)

## Configuration

Key constants in SaveBackupService:
- `_maxBackupsPerSave = 5` - Maximum backups kept per save
- `_autoBackupIntervalHours = 24` - Hours between automatic backups

## Error Handling

All backup operations use the `SaveBackupException` class for error reporting:

```dart
try {
  await backupService.createManualBackup(saveId, userId);
} catch (SaveBackupException e) {
  print('Backup failed: ${e.message}');
}
```

## Best Practices

1. **Always validate before critical operations**: Check save integrity before major changes
2. **Create manual backups before updates**: Backup before game version updates
3. **Monitor backup count**: Ensure backups are being created and cleaned up properly
4. **Handle recovery gracefully**: Provide clear user feedback during recovery operations
5. **Test import/export**: Verify exported saves can be imported successfully

## Integration Notes

- The backup system integrates seamlessly with the existing SaveManager
- Automatic backups are created during normal save operations
- The UI components can be easily integrated into existing save management screens
- All operations are asynchronous and should be handled with proper error handling

## Future Enhancements

Potential improvements:
- Cloud backup storage
- Incremental backups for large saves
- Backup compression
- Scheduled backup creation
- Backup sharing between users
- Advanced corruption repair algorithms
