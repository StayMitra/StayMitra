import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'services/admin_announcements_service.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState
    extends State<AdminAnnouncementsScreen> {
  final _service = AdminAnnouncementsService.instance;

  List<AdminAnnouncement> _announcements = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _service.getAnnouncements();

      if (!mounted) return;

      setState(() {
        _announcements = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _create() async {
    await _showAnnouncementForm();
  }

  Future<void> _edit(AdminAnnouncement announcement) async {
    await _showAnnouncementForm(
      announcement: announcement,
    );
  }

  Future<void> _showAnnouncementForm({
    AdminAnnouncement? announcement,
  }) async {
    final titleController = TextEditingController(
      text: announcement?.title ?? '',
    );

    final messageController = TextEditingController(
      text: announcement?.message ?? '',
    );

    String target = announcement?.target ?? 'all';
    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuildContext, setDialogState) {
            Future<void> save() async {
              final title = titleController.text.trim();
              final message = messageController.text.trim();

              if (title.isEmpty || message.isEmpty) {
                ScaffoldMessenger.of(dialogBuildContext)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter both title and message.',
                      ),
                    ),
                  );
                return;
              }

              setDialogState(() {
                saving = true;
              });

              try {
                final createdBy =
                    FirebaseAuth.instance.currentUser?.uid ?? 'admin';

                if (announcement == null) {
                  await _service.createAnnouncement(
                    title: title,
                    message: message,
                    target: target,
                    createdBy: createdBy,
                  );
                } else {
                  await _service.updateAnnouncement(
                    announcementId: announcement.id,
                    title: title,
                    message: message,
                    target: target,
                  );
                }

                if (!dialogContext.mounted) return;

                Navigator.of(dialogContext).pop(true);
              } catch (e) {
                setDialogState(() {
                  saving = false;
                });

                if (!dialogBuildContext.mounted) return;

                ScaffoldMessenger.of(dialogBuildContext)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        'Unable to save announcement: $e',
                      ),
                    ),
                  );
              }
            }

            return AlertDialog(
              title: Text(
                announcement == null
                    ? 'New Announcement'
                    : 'Edit Announcement',
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 430,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        enabled: !saving,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Enter announcement title',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.title_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: messageController,
                        enabled: !saving,
                        minLines: 4,
                        maxLines: 7,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          hintText: 'Enter announcement message',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(
                              bottom: 70,
                            ),
                            child: Icon(
                              Icons.message_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: target,
                        decoration: const InputDecoration(
                          labelText: 'Target Audience',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.groups_outlined,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem<String>(
                            value: 'all',
                            child: Text('All Owners'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'active',
                            child: Text('Active Subscribers'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'trial',
                            child: Text('Trial Users'),
                          ),
                        ],
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value == null) return;

                                setDialogState(() {
                                  target = value;
                                });
                              },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(false);
                        },
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : save,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_outlined,
                        ),
                  label: Text(
                    announcement == null
                        ? 'Publish'
                        : 'Save',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    messageController.dispose();

    if (result == true) {
      await _load();

      if (!mounted) return;

      _showMessage(
        announcement == null
            ? 'Announcement published.'
            : 'Announcement updated.',
      );
    }
  }

  Future<void> _delete(
    AdminAnnouncement announcement,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Announcement?',
          ),
          content: Text(
            'Delete "${announcement.title}"? '
            'This will remove it from owner notifications.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service.deleteAnnouncement(
        announcement.id,
      );

      await _load();

      if (!mounted) return;

      _showMessage(
        'Announcement deleted.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to delete announcement: $e',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  String _targetLabel(String target) {
    switch (target) {
      case 'active':
        return 'Active Subscribers';

      case 'trial':
        return 'Trial Users';

      default:
        return 'All Owners';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Just now';
    }

    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/${local.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Announcements',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _create,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'New Announcement',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
if (_loading) {
  return ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: const [
      SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    ],
  );
}

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          const Icon(
            Icons.error_outline,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to load announcements.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: _load,
              child: const Text(
                'Retry',
              ),
            ),
          ),
        ],
      );
    }

    if (_announcements.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(
            Icons.campaign_outlined,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No announcements yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create an announcement to share an important '
            'update with Stay Mitra owners.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        100,
      ),
      itemCount: _announcements.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final announcement = _announcements[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(14),
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                      ),
                      child: Icon(
                        Icons.campaign_outlined,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatDate(
                              announcement.createdAt,
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _edit(announcement);
                        } else if (value == 'delete') {
                          _delete(announcement);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                              ),
                              SizedBox(width: 10),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              SizedBox(width: 10),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  announcement.message,
                  style: const TextStyle(
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(
                        Icons.groups_outlined,
                        size: 18,
                      ),
                      label: Text(
                        _targetLabel(
                          announcement.target,
                        ),
                      ),
                    ),
                    Chip(
                      avatar: Icon(
                        announcement.status == 'published'
                            ? Icons.check_circle_outline
                            : Icons.pause_circle_outline,
                        size: 18,
                      ),
                      label: Text(
                        announcement.status == 'published'
                            ? 'Published'
                            : announcement.status,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}