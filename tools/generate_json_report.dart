import 'dart:io';
import 'dart:convert';

void main() async {
  final analyzer = ProjectAnalyzer();
  await analyzer.analyze();
  final jsonReport = analyzer.generateJsonReport();
  
  final file = File('tools/analysis_report.json');
  await file.writeAsString(jsonReport);
  
  print('JSON report generated: tools/analysis_report.json');
}

class ProjectAnalyzer {
  final Map<String, FileInfo> files = {};
  final Map<String, Set<String>> importGraph = {};
  final Set<String> testFiles = {};
  
  Future<void> analyze() async {
    await scanDirectory(Directory('lib'));
    await scanDirectory(Directory('test'));
    
    for (var file in files.values) {
      await analyzeFile(file);
    }
    
    categorizeFiles();
    identifyDuplicates();
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
    
    if (fileInfo.path.contains('example')) {
      fileInfo.isExample = true;
    }
    
    if (fileInfo.path.endsWith('.md') || fileInfo.path.contains('README')) {
      fileInfo.isDocumentation = true;
    }
    
    for (var line in lines) {
      line = line.trim();
      
      if (line.startsWith('import ')) {
        final match = RegExp(r'''import\s+['"]([^'"]+)['"]''').firstMatch(line);
        if (match != null) {
          var importPath = match.group(1)!;
          
          if (importPath.startsWith('package:BasketballManager/')) {
            importPath = 'lib/${importPath.substring('package:BasketballManager/'.length)}';
          } else if (importPath.startsWith('package:basketball_manager/')) {
            importPath = 'lib/${importPath.substring('package:basketball_manager/'.length)}';
          } else if (importPath.startsWith('../') || importPath.startsWith('./')) {
            importPath = resolveRelativePath(fileInfo.path, importPath);
          } else if (!importPath.startsWith('package:') && !importPath.startsWith('dart:')) {
            importPath = resolveRelativePath(fileInfo.path, importPath);
          }
          
          if (importPath.startsWith('lib/') || importPath.startsWith('test/')) {
            fileInfo.imports.add(importPath);
            
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
    parts.removeLast();
    
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
  
  String generateJsonReport() {
    final libFiles = files.values.where((f) => f.path.startsWith('lib/')).toList();
    
    final report = {
      'summary': {
        'totalFiles': libFiles.length,
        'active': libFiles.where((f) => f.status == FileStatus.active).length,
        'unused': libFiles.where((f) => f.status == FileStatus.unused).length,
        'testOnly': libFiles.where((f) => f.status == FileStatus.testOnly).length,
        'example': libFiles.where((f) => f.status == FileStatus.example).length,
        'documentation': libFiles.where((f) => f.status == FileStatus.documentation).length,
        'duplicate': libFiles.where((f) => f.isDuplicate).length,
      },
      'categories': {
        'unused': libFiles
            .where((f) => f.status == FileStatus.unused)
            .map((f) => {
                  'path': f.path,
                  'imports': f.imports.length,
                })
            .toList(),
        'testOnly': libFiles
            .where((f) => f.status == FileStatus.testOnly)
            .map((f) => {
                  'path': f.path,
                  'importedBy': f.importedBy,
                  'isDuplicate': f.isDuplicate,
                  'duplicateOf': f.duplicateOf,
                })
            .toList(),
        'example': libFiles
            .where((f) => f.status == FileStatus.example)
            .map((f) => {
                  'path': f.path,
                })
            .toList(),
        'documentation': libFiles
            .where((f) => f.status == FileStatus.documentation)
            .map((f) => {
                  'path': f.path,
                })
            .toList(),
        'duplicate': libFiles
            .where((f) => f.isDuplicate)
            .map((f) => {
                  'path': f.path,
                  'duplicateOf': f.duplicateOf,
                  'importedBy': f.importedBy,
                })
            .toList(),
      },
      'topDependencies': (libFiles
          .where((f) => f.status == FileStatus.active)
          .toList()
            ..sort((a, b) => b.importedBy.length.compareTo(a.importedBy.length)))
          .take(20)
          .map((f) => {
                'path': f.path,
                'dependents': f.importedBy.length,
              })
          .toList(),
      'recommendations': [
        if (libFiles.where((f) => f.status == FileStatus.unused).isNotEmpty)
          'Remove ${libFiles.where((f) => f.status == FileStatus.unused).length} unused files',
        if (libFiles.where((f) => f.status == FileStatus.example).isNotEmpty)
          'Move ${libFiles.where((f) => f.status == FileStatus.example).length} example files to examples/ directory',
        if (libFiles.where((f) => f.status == FileStatus.documentation).isNotEmpty)
          'Move ${libFiles.where((f) => f.status == FileStatus.documentation).length} documentation files to docs/ directory',
        if (libFiles.where((f) => f.isDuplicate).isNotEmpty)
          'Consolidate ${libFiles.where((f) => f.isDuplicate).length} duplicate implementations',
        if (libFiles.where((f) => f.status == FileStatus.testOnly).isNotEmpty)
          'Review ${libFiles.where((f) => f.status == FileStatus.testOnly).length} test-only files',
      ],
    };
    
    return JsonEncoder.withIndent('  ').convert(report);
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
