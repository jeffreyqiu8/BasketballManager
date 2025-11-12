import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'save_metadata.dart';
import 'save_manager.dart';
import 'performance_optimizer.dart';
import 'memory_manager.dart';
import 'performance_profiler.dart';

/// Enhanced save manager with performance optimizations for large datasets
class OptimizedSaveManager extends SaveManager {
  final PerformanceOptimizer _optimizer = PerformanceOptimizer();
  final MemoryManager _memoryManager = MemoryManager();
  final PerformanceProfiler _profiler = PerformanceProfiler();

  static const int _defaultPageSize = 20;
  static const int _maxConcurrentOperations = 5;
  
  // Semaphore for limiting concurrent operations
  final Map<String, Completer<void>> _operationLocks = {};
  int _activeOperations = 0;

  /// Get paginated saves with caching and lazy loading
  Future<List<SaveMetadata>> getPaginatedSaves(
    String userId, {
    int offset = 0,
    int limit = _defaultPageSize,
    String? sortBy,
    bool descending = true,
  }) async {
    return _profiler.profileAsyncFunction(
      'getPaginatedSaves',
      () => _getPaginatedSavesImpl(userId, offset, limit, sortBy, descending),
      metadata: {
        'userId': userId,
        'offset': offset,
        'limit': limit,
        'sortBy': sortBy ?? 'lastPlayedDate',
      },
    );
  }

  Future<List<SaveMetadata>> _getPaginatedSavesImpl(
    String userId,
    int offset,
    int limit,
    String? sortBy,
    bool descending,
  ) async {
    // Check cache first
    final cached = _optimizer.getCachedSaveMetadata(userId, offset: offset, limit: limit);
    if (cached.isNotEmpty) {
      return cached.map((item) => SaveMetadata.fromMap(item)).toList();
    }

    // Limit concurrent operations
    await _waitForOperationSlot();

    try {
      _activeOperations++;
      
      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('saveMetadata');

      // Apply sorting
      final sortField = sortBy ?? 'lastPlayedDate';
      query = query.orderBy(sortField, descending: descending);

      // Apply pagination
      if (offset > 0) {
        final offsetSnapshot = await query.limit(offset).get();
        if (offsetSnapshot.docs.isNotEmpty) {
          query = query.startAfterDocument(offsetSnapshot.docs.last);
        }
      }

      final querySnapshot = await query.limit(limit).get();
      final saves = querySnapshot.docs
          .map((doc) => SaveMetadata.fromMap(doc.data()))
          .toList();

      // Cache the results
      _optimizer.cacheSaveMetadata(
        userId,
        saves.map((save) => save.toMap()).toList(),
        offset: offset,
        limit: limit,
      );

      return saves;
    } finally {
      _activeOperations--;
    }
  }

  /// Get save preview data with caching
  Future<Map<String, dynamic>> getSavePreview(String saveId, String userId) async {
    return _profiler.profileAsyncFunction(
      'getSavePreview',
      () => _getSavePreviewImpl(saveId, userId),
      metadata: {'saveId': saveId, 'userId': userId},
    );
  }

  Future<Map<String, dynamic>> _getSavePreviewImpl(String saveId, String userId) async {
    // Check cache first
    final cached = _optimizer.getCachedSavePreview(saveId);
    if (cached.isNotEmpty) {
      return cached;
    }

    await _waitForOperationSlot();

    try {
      _activeOperations++;
      
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('saveMetadata')
          .doc(saveId)
          .get();

      if (!docSnapshot.exists) {
        return {};
      }

      final metadata = SaveMetadata.fromMap(docSnapshot.data()!);
      final preview = {
        'saveId': metadata.saveId,
        'saveName': metadata.saveName,
        'teamName': metadata.teamName,
        'coachName': metadata.coachName,
        'currentSeason': metadata.currentSeason,
        'gamesPlayed': metadata.gamesPlayed,
        'winPercentage': metadata.currentRecord.winPercentage,
        'lastPlayedDate': metadata.lastPlayedDate.toIso8601String(),
        'totalPlaytime': metadata.totalPlaytime.inHours,
        'majorAchievements': metadata.majorAchievements.take(3).toList(),
      };

      // Cache the preview
      _optimizer.cacheSavePreview(saveId, preview);

      return preview;
    } finally {
      _activeOperations--;
    }
  }

  /// Batch load multiple save previews efficiently
  Future<Map<String, Map<String, dynamic>>> batchLoadSavePreviews(
    List<String> saveIds,
    String userId,
  ) async {
    return _profiler.profileAsyncFunction(
      'batchLoadSavePreviews',
      () => _batchLoadSavePreviewsImpl(saveIds, userId),
      metadata: {'saveCount': saveIds.length, 'userId': userId},
    );
  }

  Future<Map<String, Map<String, dynamic>>> _batchLoadSavePreviewsImpl(
    List<String> saveIds,
    String userId,
  ) async {
    final results = <String, Map<String, dynamic>>{};
    final uncachedIds = <String>[];

    // Check cache for each save
    for (final saveId in saveIds) {
      final cached = _optimizer.getCachedSavePreview(saveId);
      if (cached.isNotEmpty) {
        results[saveId] = cached;
      } else {
        uncachedIds.add(saveId);
      }
    }

    // Batch load uncached saves
    if (uncachedIds.isNotEmpty) {
      const batchSize = 10;
      for (int i = 0; i < uncachedIds.length; i += batchSize) {
        final batch = uncachedIds.skip(i).take(batchSize);
        final batchFutures = batch.map((saveId) => getSavePreview(saveId, userId));
        final batchResults = await Future.wait(batchFutures);
        
        for (int j = 0; j < batch.length; j++) {
          final saveId = batch.elementAt(j);
          results[saveId] = batchResults[j];
        }

        // Allow other operations between batches
        await Future.delayed(Duration.zero);
      }
    }

    return results;
  }

  /// Search saves with optimized querying
  Future<List<SaveMetadata>> searchSaves(
    String userId,
    String searchTerm, {
    int limit = 50,
  }) async {
    return _profiler.profileAsyncFunction(
      'searchSaves',
      () => _searchSavesImpl(userId, searchTerm, limit),
      metadata: {'userId': userId, 'searchTerm': searchTerm, 'limit': limit},
    );
  }

  Future<List<SaveMetadata>> _searchSavesImpl(
    String userId,
    String searchTerm,
    int limit,
  ) async {
    await _waitForOperationSlot();

    try {
      _activeOperations++;
      
      final lowerSearchTerm = searchTerm.toLowerCase();
      
      // Search by save name
      final nameQuery = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('saveMetadata')
          .where('saveName', isGreaterThanOrEqualTo: searchTerm)
          .where('saveName', isLessThan: '$searchTerm\uf8ff')
          .limit(limit);

      // Search by team name
      final teamQuery = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('saveMetadata')
          .where('teamName', isGreaterThanOrEqualTo: searchTerm)
          .where('teamName', isLessThan: '$searchTerm\uf8ff')
          .limit(limit);

      final nameResults = await nameQuery.get();
      final teamResults = await teamQuery.get();

      final allResults = <SaveMetadata>[];
      final seenIds = <String>{};

      // Combine results and remove duplicates
      for (final doc in [...nameResults.docs, ...teamResults.docs]) {
        final metadata = SaveMetadata.fromMap(doc.data());
        if (!seenIds.contains(metadata.saveId)) {
          seenIds.add(metadata.saveId);
          allResults.add(metadata);
        }
      }

      // Sort by relevance (exact matches first, then partial matches)
      allResults.sort((a, b) {
        final aExact = a.saveName.toLowerCase() == lowerSearchTerm ||
                      a.teamName.toLowerCase() == lowerSearchTerm;
        final bExact = b.saveName.toLowerCase() == lowerSearchTerm ||
                      b.teamName.toLowerCase() == lowerSearchTerm;
        
        if (aExact && !bExact) return -1;
        if (!aExact && bExact) return 1;
        
        // Secondary sort by last played date
        return b.lastPlayedDate.compareTo(a.lastPlayedDate);
      });

      return allResults.take(limit).toList();
    } finally {
      _activeOperations--;
    }
  }

  /// Optimized save deletion with cache invalidation
  @override
  Future<void> deleteSave(String saveId, String userId) async {
    await _profiler.profileAsyncFunction(
      'deleteSave',
      () => _deleteSaveImpl(saveId, userId),
      metadata: {'saveId': saveId, 'userId': userId},
    );
  }

  Future<void> _deleteSaveImpl(String saveId, String userId) async {
    await _waitForOperationSlot();

    try {
      _activeOperations++;
      
      // Delete from Firestore
      await super.deleteSave(saveId, userId);
      
      // Invalidate related caches
      _optimizer.invalidateRelatedCaches('save_data', saveId);
      _optimizer.invalidateRelatedCaches('save_data', userId);
    } finally {
      _activeOperations--;
    }
  }

  /// Optimized save creation with immediate caching
  @override
  Future<String> createNewSave(dynamic data, String userId) async {
    return _profiler.profileAsyncFunction(
      'createNewSave',
      () => _createNewSaveImpl(data, userId),
      metadata: {'userId': userId},
    );
  }

  Future<String> _createNewSaveImpl(dynamic data, String userId) async {
    await _waitForOperationSlot();

    try {
      _activeOperations++;
      
      final saveId = await super.createNewSave(data, userId);
      
      // Invalidate save list cache to force refresh
      _optimizer.invalidateRelatedCaches('save_data', userId);
      
      return saveId;
    } finally {
      _activeOperations--;
    }
  }

  /// Get memory and performance statistics
  Map<String, dynamic> getPerformanceStatistics() {
    return {
      'cache': _optimizer.getCacheStatistics(),
      'memory': _memoryManager.getMemoryStatistics(),
      'performance': _profiler.getAllStats(),
      'activeOperations': _activeOperations,
      'operationLocks': _operationLocks.length,
    };
  }

  /// Optimize memory usage and clear expired caches
  void optimizePerformance() {
    _optimizer.optimizeMemoryUsage();
    _memoryManager.performCleanup();
    _profiler.clear();
  }

  /// Preload frequently accessed data
  Future<void> preloadUserData(String userId) async {
    await _profiler.profileAsyncFunction(
      'preloadUserData',
      () => _preloadUserDataImpl(userId),
      metadata: {'userId': userId},
    );
  }

  Future<void> _preloadUserDataImpl(String userId) async {
    // Preload first page of saves
    await getPaginatedSaves(userId, limit: _defaultPageSize);
    
    // Preload recent saves previews
    final recentSaves = await getPaginatedSaves(userId, limit: 5);
    if (recentSaves.isNotEmpty) {
      final saveIds = recentSaves.map((save) => save.saveId).toList();
      await batchLoadSavePreviews(saveIds, userId);
    }
  }

  /// Wait for an available operation slot to prevent overwhelming the system
  Future<void> _waitForOperationSlot() async {
    while (_activeOperations >= _maxConcurrentOperations) {
      await Future.delayed(Duration(milliseconds: 10));
    }
  }

  /// Dispose resources and clear caches
  void dispose() {
    _optimizer.clearAllCaches();
    _memoryManager.clearAll();
    _profiler.clear();
    _operationLocks.clear();
  }
}