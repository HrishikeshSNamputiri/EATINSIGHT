import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/lists/lists_controller.dart';
import '../../../data/lists/lists_store.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _importCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _importCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ListsController controller = context.watch<ListsController>();
    final List<UserList> lists = controller.all;
    final String? activeId = controller.activeId;

    return Scaffold(
      appBar: AppBar(title: const Text('Lists')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'New list name'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    final listsController = context.read<ListsController>();
                    final messenger = ScaffoldMessenger.of(context);
                    await listsController.createList(_nameCtrl.text);
                    _nameCtrl.clear();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('List created')),
                    );
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (lists.isEmpty)
              const Text('No lists yet. Create one to get started.')
            else ...<Widget>[
              const Text('Your lists:'),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: lists.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (BuildContext context, int index) {
                    final UserList list = lists[index];
                    final bool isActive = list.id == activeId;
                    return ListTile(
                      leading: Icon(isActive
                          ? Icons.check_circle
                          : Icons.circle_outlined),
                      title: Text(list.name),
                      subtitle: Text('${list.barcodes.length} items'),
                      onTap: () =>
                          context.read<ListsController>().setActive(list.id),
                      trailing: PopupMenuButton<String>(
                        onSelected: (String value) async {
                          final listsController =
                              context.read<ListsController>();
                          final messenger = ScaffoldMessenger.of(context);
                          if (value == 'set') {
                            await listsController.setActive(list.id);
                          } else if (value == 'rename') {
                            final String? newName =
                                await _promptRename(context, list.name);
                            if (newName != null) {
                              await listsController.renameList(
                                list.id,
                                newName,
                              );
                            }
                          } else if (value == 'delete') {
                            await listsController.deleteList(list.id);
                          } else if (value == 'export') {
                            final String? path =
                                await listsController.exportListById(list.id);
                            if (!mounted) return;
                            if (path != null) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Exported to: $path')),
                              );
                            }
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'set',
                            child: Text('Set active'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'rename',
                            child: Text('Rename'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'export',
                            child: Text('Export as JSON'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _importCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Import file path (JSON)',
                        helperText: 'Paste a file path to import a list',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final listsController = context.read<ListsController>();
                      final messenger = ScaffoldMessenger.of(context);
                      final bool ok = await listsController
                          .importFromPath(_importCtrl.text.trim());
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content:
                              Text(ok ? 'Imported list' : 'Could not import'),
                        ),
                      );
                    },
                    child: const Text('Import'),
                  ),
                ],
              ),
            ],
            if (lists.isNotEmpty && controller.active != null) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                'Active list items (${controller.active!.barcodes.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.active!.barcodes.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String code = controller.active!.barcodes[index];
                    return ListTile(
                      leading: const Icon(Icons.qr_code_2),
                      title: Text(code),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            context.read<ListsController>().removeBarcode(code),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<String?> _promptRename(BuildContext context, String current) async {
    final TextEditingController ctrl = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Rename list'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
