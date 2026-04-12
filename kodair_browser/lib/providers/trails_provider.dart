import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/trail_node.dart';

class TrailsProvider extends ChangeNotifier {
  List<TrailNode> _rootNodes = [];
  bool _isLoaded = false;
  
  List<TrailNode> get rootNodes => _rootNodes;
  bool get isLoaded => _isLoaded;

  TrailsProvider() {
    _loadFromDisk();
  }

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    // Cache natively to physical OS storage guaranteeing immediate offline data locking
    return File('${directory.path}/kodair_trails_v1.json');
  }

  Future<void> _loadFromDisk() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        _rootNodes = TrailNode.deserializeTree(contents);
      }
    } catch (e) {
      debugPrint("Error loading trails from cache: $e");
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> saveToDisk() async {
    try {
      final file = await _localFile;
      final jsonString = TrailNode.serializeTree(_rootNodes);
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint("Error committing trails to disk cache: $e");
    }
  }

  /// Deduplication Checker to violently prevent exact duplicate URLs being mapped anywhere inside the tree clusters
  bool urlExists(String url) {
    return _checkUrlRecursive(_rootNodes, url);
  }

  bool _checkUrlRecursive(List<TrailNode> nodes, String targetUrl) {
    for (var node in nodes) {
      if (node.url == targetUrl) return true;
      if (node.children.isNotEmpty) {
        if (_checkUrlRecursive(node.children, targetUrl)) return true;
      }
    }
    return false;
  }

  void addNode(TrailNode node, {String? parentId}) {
    // ADHD Protection Logic: instantly halt if they try to save something twice natively
    if (node.url != null && urlExists(node.url!)) {
      throw Exception("Duplicate URL: You already have this active in your Trails.");
    }
    
    if (parentId == null) {
      _rootNodes.insert(0, node);
    } else {
      TrailNode? parent = _findNodeRecursive(_rootNodes, parentId);
      if (parent != null) {
        parent.children.insert(0, node);
      } else {
        _rootNodes.insert(0, node);
      }
    }
    notifyListeners();
    saveToDisk();
  }
  
  void deleteNode(String id) {
    _deleteNodeRecursive(_rootNodes, id);
    notifyListeners();
    saveToDisk();
  }
  
  bool _deleteNodeRecursive(List<TrailNode> nodes, String targetId) {
    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i].id == targetId) {
        nodes.removeAt(i);
        return true;
      }
      if (_deleteNodeRecursive(nodes[i].children, targetId)) {
        return true;
      }
    }
    return false;
  }

  TrailNode? _findNodeRecursive(List<TrailNode> nodes, String id) {
    for (var node in nodes) {
      if (node.id == id) return node;
      final found = _findNodeRecursive(node.children, id);
      if (found != null) return found;
    }
    return null;
  }
  
  // Physically tears a node from its current branch and splices it into a target parent
  void moveNode(String nodeId, String? targetParentId) {
    TrailNode? nodeToMove = _findNodeRecursive(_rootNodes, nodeId);
    if (nodeToMove == null) return;
    
    // Prevent violent circular dependency stack-overflows
    if (_isDescendant(nodeToMove, targetParentId)) return;
    
    // Detach from current anchor
    _deleteNodeRecursive(_rootNodes, nodeId);
    
    nodeToMove.parentId = targetParentId;
    
    // Re-attach into payload
    if (targetParentId == null) {
      _rootNodes.insert(0, nodeToMove);
    } else {
      TrailNode? parent = _findNodeRecursive(_rootNodes, targetParentId);
      if (parent != null) {
        parent.children.insert(0, nodeToMove);
      } else {
        _rootNodes.insert(0, nodeToMove);
      }
    }
    notifyListeners();
    saveToDisk();
  }
  
  bool _isDescendant(TrailNode potentialAncestor, String? descendantId) {
    if (descendantId == null) return false;
    if (potentialAncestor.id == descendantId) return true;
    for (var child in potentialAncestor.children) {
      if (_isDescendant(child, descendantId)) return true;
    }
    return false;
  }
  
  /// Sub-10ms Smart Search memory mapper.
  /// Used natively by the Search Overlay URL bar to pull relevant history
  List<TrailNode> searchTrails(String query) {
    if (query.trim().isEmpty) return [];
    final safeQuery = query.toLowerCase();
    List<TrailNode> results = [];
    _searchRecursive(_rootNodes, safeQuery, results);
    return results;
  }
  
  void _searchRecursive(List<TrailNode> nodes, String query, List<TrailNode> results) {
    for (var node in nodes) {
      if (node.title.toLowerCase().contains(query) || (node.url?.toLowerCase().contains(query) ?? false)) {
        // Provide the fully rendered Trail context rather than just isolated links
        results.add(node);
      }
      _searchRecursive(node.children, query, results);
    }
  }
}
