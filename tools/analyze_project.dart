import 'dart:io';

void main() async {
  print('=== Basketball Manager Project Analysis ===\n');
  
  final analyzer = ProjectAnalyzer();
  await analyzer.analyze();
  analyzer.generateReport();
}

class ProjectAnalyzer {
  final Map<String, FileInfo> files = {};
  final Map<String, Set<String>> importGraph = {};
  final Set<String> testFiles = {};
  
  Future<void> analyze() async {
    print('Step 1: Scanning project files...');
    await scanDirectory(Directory('lib'));
    await scanDirectory(Directory('test'));
    
    print('Step 2: Analyzing imports and dependencies...');
    for (var file in files.values) {
      await analyzeFile(file);
    }
    
    print('Step 3: Categorizing files...');
    categorizeFiles();
    
    print('Step 4: Identifying duplicates...');
    identifyDuplicates();
    
    print('\nAnalysis complete!\n');
  }
  
  Future<void> scanDirectory(Directory dir) async {
    if (!await dir.exists()) return;
    
    await for (var entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final relativePath = entity.path.replaceAll('\\', '/');
        final isTest = relativePath.startsWith('test/');
        
        files[relativePath] = FileInfo(
          path: relativePath,
          isTest: isTest,
        );
        
        if (isTest) {
          testFiles.add(relativePath);
        }
      }
    }
  }
  
  Future<void> analyzeFile(FileInfo fileInfo) async {
    final file = File(fileInfo.path);
    final content = await file.readAsString();
    final lines = content.split('\n');
    
    // Check for special markers
    if (fileInfo.path.contains('example')) {
      fileInfo.isExample = true;
    }
    
    if (fileInfo.path.endsWith('.md') || fileInfo.path.contains('README')) {
      fileInfo.isDocumentation = true;
    }
    
    // Extract imports
    for (var line in lines) {
      line = line.trim();
      
      if (line.startsWith('import ')) {
        final match = RegExp(r'''import\s+['"]([^'"]+)['"]''').firstMatch(line);
        if (match != null) {
          var importPath = match.group(1)!;
          
          // Convert package imports to file paths
          if (importPath.startsWith('package:BasketballManager/')) {
            importPath = 'lib/${importPath.substring('package:BasketballManager/'.length)}';
          } else if (importPath.startsWith('package:basketball_manager/')) {
            importPath = 'lib/${importPath.substring('package:basketball_manager/'.length)}';
          } else if (importPath.startsWith('../') || importPath.startsWith('./')) {
            // Handle relative imports
            importPath = resolveRelativePath(fileInfo.path, importPath);
          } else if (!importPath.startsWith('package:') && !importPath.startsWith('dart:')) {
            // Relative import without prefix
            importPath = resolveRelativePath(fileInfo.path, importPath);
          }
          
          if (importPath.startsWith('lib/') || importPath.startsWith('test/')) {
            fileInfo.imports.add(importPath);
            
            // Build reverse dependency graph
            if (!importGraph.containsKey(importPath)) {
              importGraph[importPath] = {};
            }
            importGraph[importPath]!.add(fileInfo.path);
          }
        }
      }
    }
  }
  
  String resolveRelativePath(String fromPath, String importPath) {
    final parts = fromPath.split('/');
    parts.removeLast(); // Remove filename
    
    final importParts = importPath.split('/');
    for (var part in importParts) {
      if (part == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else if (part != '.') {
        parts.add(part);
      }
    }
    
    return parts.join('/');
  }
  
  void categorizeFiles() {
    for (var fileInfo in files.values) {
      if (fileInfo.isTest) {
        fileInfo.status = FileStatus.test;
        continue;
      }
      
      if (fileInfo.isDocumentation) {
        fileInfo.status = FileStatus.documentation;
        continue;
      }
      
      if (fileInfo.isExample) {
        fileInfo.status = FileStatus.example;
        continue;
      }
      
      // Check if file is imported
      final importedBy = importGraph[fileInfo.path] ?? {};
      final importedByProduction = importedBy.where((f) => !testFiles.contains(f)).toSet();
      
      if (importedByProduction.isEmpty && importedBy.isEmpty) {
        fileInfo.status = FileStatus.unused;
      } else if (importedByProduction.isEmpty && importedBy.isNotEmpty) {
        fileInfo.status = FileStatus.testOnly;
      } else {
        fileInfo.status = FileStatus.active;
      }
      
      fileInfo.importedBy = importedBy.toList()..sort();
    }
  }
  
  void identifyDuplicates() {
    final patterns = {
      'optimized': RegExp(r'optimized_(.+)\.dart$'),
      'enhanced': RegExp(r'enhanced_(.+)\.dart$'),
    };
    
    for (var fileInfo in files.values) {
      if (fileInfo.isTest) continue;
      
      for (var entry in patterns.entries) {
        final match = entry.value.firstMatch(fileInfo.path);
        if (match != null) {
          final baseName = match.group(1);
          final baseFile = fileInfo.path.replaceAll(entry.value, '$baseName.dart');
          
          if (files.containsKey(baseFile)) {
            fileInfo.isDuplicate = true;
            fileInfo.duplicateOf = baseFile;
          }
        }
      }
    }
  }
  
  void generateReport() {
    print('=' * 80);
    print('PROJECT ANALYSIS REPORT');
    print('=' * 80);
    print('');
    
    // Summary statistics
    final libFiles = files.values.where((f) => f.path.startsWith('lib/')).toList();
    final activeFiles = libFiles.where((f) => f.status == FileStatus.active).length;
    final unusedFiles = libFiles.where((f) => f.status == FileStatus.unused).length;
    final testOnlyFiles = libFiles.where((f) => f.status == FileStatus.testOnly).length;
    final exampleFiles = libFiles.where((f) => f.status == FileStatus.example).length;
    final docFiles = libFiles.where((f) => f.status == FileStatus.documentation).length;
    final duplicateFiles = libFiles.where((f) => f.isDuplicate).length;
    
    print('SUMMARY');
    print('-' * 80);
    print('Total files in lib/: ${libFiles.length}');
    print('Active (used in production): $activeFiles');
    print('Test-only (only imported by tests): $testOnlyFiles');
    print('Unused (not imported anywhere): $unusedFiles');
    print('Example files: $exampleFiles');
    print('Documentation files: $docFiles');
    print('Duplicate implementations: $duplicateFiles');
    print('');
    
    // Detailed breakdown by category
    printCategory('UNUSED FILES (Not imported anywhere)', 
        libFiles.where((f) => f.status == FileStatus.unused));
    
    printCategory('TEST-ONLY FILES (Only imported by tests)', 
        libFiles.where((f) => f.status == FileStatus.testOnly));
    
    printCategory('EXAMPLE FILES', 
        libFiles.where((f) => f.status == FileStatus.example));
    
    printCategory('DOCUMENTATION FILES', 
        libFiles.where((f) => f.status == FileStatus.documentation));
    
    printCategory('DUPLICATE IMPLEMENTATIONS', 
        libFiles.where((f) => f.isDuplicate));
    
    printCategory('ACTIVE FILES (Used in production)', 
        libFiles.where((f) => f.status == FileStatus.active && !f.isDuplicate));
    
    // Dependency graph for key files
    print('=' * 80);
    print('DEPENDENCY ANALYSIS');
    print('=' * 80);
    print('');
    
    printDependencies('lib/main.dart');
    printDependencies('lib/main_accessibility.dart');
    
    // Files with most dependencies
    print('\nFILES WITH MOST DEPENDENTS (Top 10)');
    print('-' * 80);
    final sortedByDependents = libFiles.where((f) => f.status == FileStatus.active).toList()
      ..sort((a, b) => b.importedBy.length.compareTo(a.importedBy.length));
    
    for (var i = 0; i < 10 && i < sortedByDependents.length; i++) {
      final file = sortedByDependents[i];
      print('${file.path} (${file.importedBy.length} dependents)');
    }
    print('');
    
    // Recommendations
    print('=' * 80);
    print('RECOMMENDATIONS');
    print('=' * 80);
    print('');
    
    if (unusedFiles > 0) {
      print('✓ Remove $unusedFiles unused files to reduce codebase size');
    }
    
    if (exampleFiles > 0) {
      print('✓ Move $exampleFiles example files to examples/ directory');
    }
    
    if (docFiles > 0) {
      print('✓ Move $docFiles documentation files to docs/ directory');
    }
    
    if (duplicateFiles > 0) {
      print('✓ Consolidate $duplicateFiles duplicate implementations');
    }
    
    if (testOnlyFiles > 0) {
      print('✓ Review $testOnlyFiles test-only files - may be unused or test utilities');
    }
    
    print('');
    print('Analysis complete! Review the report above for cleanup opportunities.');
  }
  
  void printCategory(String title, Iterable<FileInfo> files) {
    if (files.isEmpty) return;
    
    print('=' * 80);
    print(title);
    print('=' * 80);
    print('');
    
    for (var file in files) {
      print('📄 ${file.path}');
      
      if (file.isDuplicate && file.duplicateOf != null) {
        print('   ⚠️  Duplicate of: ${file.duplicateOf}');
      }
      
      if (file.importedBy.isNotEmpty) {
        print('   Imported by:');
        for (var importer in file.importedBy.take(5)) {
          print('     - $importer');
        }
        if (file.importedBy.length > 5) {
          print('     ... and ${file.importedBy.length - 5} more');
        }
      }
      
      if (file.imports.isNotEmpty && file.status == FileStatus.active) {
        print('   Imports: ${file.imports.length} files');
      }
      
      print('');
    }
  }
  
  void printDependencies(String filePath) {
    final file = files[filePath];
    if (file == null) {
      print('$filePath: NOT FOUND');
      return;
    }
    
    print('$filePath:');
    print('  Status: ${file.status}');
    print('  Direct imports: ${file.imports.length}');
    print('  Imported by: ${file.importedBy.length} files');
    
    if (file.imports.isNotEmpty) {
      print('  Key dependencies:');
      for (var imp in file.imports.take(10)) {
        final impFile = files[imp];
        if (impFile != null && !impFile.isTest) {
          print('    - $imp (${impFile.status})');
        }
      }
    }
    print('');
  }
}

class FileInfo {
  final String path;
  final bool isTest;
  final List<String> imports = [];
  List<String> importedBy = [];
  FileStatus status = FileStatus.unknown;
  bool isExample = false;
  bool isDocumentation = false;
  bool isDuplicate = false;
  String? duplicateOf;
  
  FileInfo({
    required this.path,
    required this.isTest,
  });
}

enum FileStatus {
  active,
  testOnly,
  unused,
  example,
  documentation,
  test,
  unknown,
}
