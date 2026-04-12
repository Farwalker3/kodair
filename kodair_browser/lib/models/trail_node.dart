import 'dart:convert';
import 'package:uuid/uuid.dart';

class TrailNode {
  final String id;
  String title;
  String? url;
  String? favicon;
  String? parentId;
  final DateTime createdAt;
  List<TrailNode> children;

  TrailNode({
    String? id,
    required this.title,
    this.url,
    this.favicon,
    this.parentId,
    DateTime? createdAt,
    List<TrailNode>? children,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        children = children ?? [];

  /// Helper to check if this node acts purely as a Folder
  bool get isFolder => url == null || url!.isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'favicon': favicon,
      'parentId': parentId,
      'createdAt': createdAt.toIso8601String(),
      'children': children.map((c) => c.toJson()).toList(),
    };
  }

  factory TrailNode.fromJson(Map<String, dynamic> json) {
    return TrailNode(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String?,
      favicon: json['favicon'] as String?,
      parentId: json['parentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      children: (json['children'] as List<dynamic>?)
              ?.map((c) => TrailNode.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Extremely robust recursive serialization wrapper
  static String serializeTree(List<TrailNode> nodes) {
    return jsonEncode(nodes.map((n) => n.toJson()).toList());
  }

  static List<TrailNode> deserializeTree(String jsonString) {
    final List<dynamic> mapList = jsonDecode(jsonString);
    return mapList.map((m) => TrailNode.fromJson(m)).toList();
  }
}
