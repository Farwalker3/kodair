import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trail_node.dart';
import '../providers/browser_provider.dart';
import '../providers/trails_provider.dart';
import '../theme/kodair_theme.dart';

class TrailsManager extends StatefulWidget {
  const TrailsManager({super.key});

  @override
  State<TrailsManager> createState() => _TrailsManagerState();
}

class _TrailsManagerState extends State<TrailsManager> {
  // Recursively evaluates the deep-tree structure and translates it into UI Expansions
  Widget _buildNode(TrailNode node, int depth) {
    bool hasChildren = node.children.isNotEmpty;
    bool isFolder = node.isFolder;

    final dragData = node.id;
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        final draggedId = details.data;
        if (draggedId == node.id) return false;
        // only accept drop if target is a folder!
        return isFolder;
      },
      onAcceptWithDetails: (details) {
        context.read<TrailsProvider>().moveNode(details.data, node.id);
      },
      builder: (context, candidateData, rejectedData) {
        Widget tileBlock = ExpansionTile(
          initiallyExpanded: false,
          controlAffinity: ListTileControlAffinity.leading, // Put accordion dropdown caret on the left
          leading: Icon(
            isFolder ? Icons.folder : Icons.language, 
            color: isFolder ? Colors.amber : KodairTheme.primaryBlue, 
            size: 20
          ),
          title: Text(node.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: (!isFolder && node.url != null) 
            ? Text(node.url!, style: const TextStyle(color: Colors.white38, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis) 
            : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFolder)
                IconButton(
                  icon: const Icon(Icons.add, size: 18, color: KodairTheme.primaryBlue),
                  tooltip: 'Add Link Inside Folder',
                  onPressed: () => _addManualLink(parentId: node.id),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                tooltip: 'Delete',
                onPressed: () {
                  context.read<TrailsProvider>().deleteNode(node.id);
                },
              ),
            ],
          ),
          children: [
            if (hasChildren)
              ...node.children.map((child) => Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: _buildNode(child, depth + 1),
              ))
            else if (isFolder)
              Padding(
                padding: const EdgeInsets.only(left: 32.0, bottom: 8.0, top: 4.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _addManualLink(parentId: node.id),
                    icon: const Icon(Icons.add_link, size: 14, color: Colors.white54),
                    label: const Text('Add Link Here...', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ),
                ),
              ),
          ],
          onExpansionChanged: (expanded) {
            if (!isFolder && node.url != null && expanded) {
              final browser = context.read<BrowserProvider>();
              browser.addTab(node.url!, node.title);
              browser.toggleTrails(); 
            }
          },
        );
        
        return LongPressDraggable<String>(
          data: dragData,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: KodairTheme.appBarBg.withAlpha(240), borderRadius: BorderRadius.circular(8)),
              child: Text(node.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: tileBlock)),
          child: Container(
            color: candidateData.isNotEmpty ? KodairTheme.primaryBlue.withAlpha(80) : Colors.transparent,
            child: Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: tileBlock),
          ),
        );
      },
    );
  }

  void _addManualLink({String? parentId}) {
    showDialog(
      context: context,
      builder: (ctx) {
        String inputUrl = '';
        String inputTitle = '';
        return AlertDialog(
          backgroundColor: const Color(0xff121212),
          title: const Text('Add New Link to Trail', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Enter URL (e.g. google.com)', 
                  hintStyle: TextStyle(color: Colors.white38),
                ),
                onChanged: (val) => inputUrl = val,
              ),
              const SizedBox(height: 12),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Title (Optional)', 
                  hintStyle: TextStyle(color: Colors.white38),
                ),
                onChanged: (val) => inputTitle = val,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.tab),
                label: const Text('Add Current Open Tab Instead'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _addCurrentPage(parentId: parentId);
                },
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: KodairTheme.primaryBlue),
              onPressed: () {
                if (inputUrl.trim().isNotEmpty) {
                  // Fix URL protocol natively
                  String url = inputUrl.trim();
                  if (!url.startsWith('http')) url = 'https://$url';
                  
                  context.read<TrailsProvider>().addNode(TrailNode(
                    title: inputTitle.trim().isEmpty ? url : inputTitle.trim(),
                    url: url,
                    parentId: parentId
                  ), parentId: parentId);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save Link', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _addCurrentPage({String? parentId}) {
    final browser = context.read<BrowserProvider>();
    final trails = context.read<TrailsProvider>();
    
    if (browser.activeTabIndex < 0 || browser.activeTabIndex >= browser.tabs.length) return;
    
    final currentTab = browser.tabs[browser.activeTabIndex];
    if (currentTab.currentAppUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save empty pages to Trails!'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      trails.addNode(TrailNode(
        title: currentTab.currentAppName.isEmpty ? 'Kodair Trail' : currentTab.currentAppName,
        url: currentTab.currentAppUrl,
        parentId: parentId,
      ), parentId: parentId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully chained into your Trails!'), backgroundColor: KodairTheme.primaryBlue),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  void _createNewFolder() {
    showDialog(
      context: context,
      builder: (ctx) {
        String folderName = '';
        return AlertDialog(
          backgroundColor: KodairTheme.appBarBg,
          title: const Text('Construct New Trail', style: TextStyle(color: Colors.white)),
          content: TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Trail node naming sequence...', 
              hintStyle: TextStyle(color: Colors.white38),
            ),
            onChanged: (val) => folderName = val,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: KodairTheme.primaryBlue),
              onPressed: () {
                if (folderName.trim().isNotEmpty) {
                  context.read<TrailsProvider>().addNode(TrailNode(title: folderName.trim()));
                }
                Navigator.pop(ctx);
              },
              child: const Text('Construct', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final trails = context.watch<TrailsProvider>();
    final browser = context.watch<BrowserProvider>();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withAlpha(240), // Hard-coded completely dark background so Trails typography natively jumps out of screen
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: KodairTheme.searchInputBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.route, color: KodairTheme.primaryBlue, size: 20),
                    SizedBox(width: 8),
                    Text('Global Trails', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.create_new_folder, color: Colors.white70),
                      onPressed: _createNewFolder,
                      tooltip: 'New Trail Folder',
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: KodairTheme.primaryBlue),
                      onPressed: () => _addManualLink(),
                      tooltip: 'Add Link',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: browser.toggleTrails,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: !trails.isLoaded
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(KodairTheme.primaryBlue)))
                : trails.rootNodes.isEmpty
                    ? const Center(child: Text('Your offline Trails cache is completely empty.', style: TextStyle(color: Colors.white54, fontSize: 12)))
                    : DragTarget<String>(
                        onWillAcceptWithDetails: (details) => true,
                        onAcceptWithDetails: (details) {
                           context.read<TrailsProvider>().moveNode(details.data, null); // Anchor drag to root tree
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            color: candidateData.isNotEmpty ? KodairTheme.primaryBlue.withAlpha(20) : Colors.transparent,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: trails.rootNodes.length,
                              itemBuilder: (context, index) {
                                return _buildNode(trails.rootNodes[index], 0);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
