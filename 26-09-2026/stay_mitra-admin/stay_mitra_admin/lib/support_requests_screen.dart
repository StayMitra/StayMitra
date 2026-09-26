import 'package:flutter/material.dart';

import 'services/admin_support_service.dart';

class AdminSupportRequestsScreen extends StatefulWidget {
  const AdminSupportRequestsScreen({super.key});

  @override
  State<AdminSupportRequestsScreen> createState() =>
      _AdminSupportRequestsScreenState();
}

class _AdminSupportRequestsScreenState
    extends State<AdminSupportRequestsScreen> {
  final AdminSupportService _service =
      AdminSupportService.instance;

  final TextEditingController _searchController =
      TextEditingController();

  List<AdminSupportRequest> _allRequests = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedStatus = 'all';
  String _selectedPriority = 'all';
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final requests = await _service.getSupportRequests();

      if (!mounted) return;

      setState(() {
        _allRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  List<AdminSupportRequest> get _filteredRequests {
    final search = _searchText.trim().toLowerCase();

    return _allRequests.where((request) {
      final statusMatches =
          _selectedStatus == 'all' ||
          request.status.toLowerCase() == _selectedStatus;

      final priorityMatches =
          _selectedPriority == 'all' ||
          request.priority.toLowerCase() == _selectedPriority;

      if (!statusMatches || !priorityMatches) {
        return false;
      }

      if (search.isEmpty) {
        return true;
      }

      return request.subject.toLowerCase().contains(search) ||
          request.message.toLowerCase().contains(search) ||
          request.ownerName.toLowerCase().contains(search) ||
          request.ownerEmail.toLowerCase().contains(search) ||
          request.ownerPhone.toLowerCase().contains(search);
    }).toList();
  }

  int get _openCount {
    return _allRequests
        .where((item) => item.status == 'open')
        .length;
  }

  int get _resolvedCount {
    return _allRequests
        .where((item) => item.status == 'resolved')
        .length;
  }

  int get _criticalCount {
    return _allRequests
        .where((item) => item.priority == 'critical')
        .length;
  }

  int get _highCount {
    return _allRequests
        .where((item) => item.priority == 'high')
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Requests'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadRequests,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _allRequests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && _allRequests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.error_outline,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to load support requests',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadRequests,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    final requests = _filteredRequests;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildSummary(),
        const SizedBox(height: 16),
        _buildSearchBox(),
        const SizedBox(height: 12),
        _buildStatusFilters(),
        const SizedBox(height: 8),
        _buildPriorityFilters(),
        const SizedBox(height: 16),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),
        if (requests.isEmpty)
          _buildEmptyState()
        else
          ...requests.map(_buildRequestCard),
      ],
    );
  }

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Support Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            _summaryCard(
              title: 'Total',
              value: _allRequests.length.toString(),
              icon: Icons.support_agent,
            ),
            _summaryCard(
              title: 'Open',
              value: _openCount.toString(),
              icon: Icons.pending_actions,
            ),
            _summaryCard(
              title: 'Resolved',
              value: _resolvedCount.toString(),
              icon: Icons.check_circle_outline,
            ),
            _summaryCard(
              title: 'Critical / High',
              value: '${_criticalCount + _highCount}',
              icon: Icons.priority_high,
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              child: Icon(icon, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchText = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search owner, subject, email or phone',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchText.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchText = '';
                  });
                },
                icon: const Icon(Icons.clear),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(
            label: 'All',
            selected: _selectedStatus == 'all',
            onSelected: () {
              setState(() {
                _selectedStatus = 'all';
              });
            },
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'Open',
            selected: _selectedStatus == 'open',
            onSelected: () {
              setState(() {
                _selectedStatus = 'open';
              });
            },
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'Resolved',
            selected: _selectedStatus == 'resolved',
            onSelected: () {
              setState(() {
                _selectedStatus = 'resolved';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(
            label: 'All Priority',
            selected: _selectedPriority == 'all',
            onSelected: () {
              setState(() {
                _selectedPriority = 'all';
              });
            },
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'Critical',
            selected: _selectedPriority == 'critical',
            onSelected: () {
              setState(() {
                _selectedPriority = 'critical';
              });
            },
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'High',
            selected: _selectedPriority == 'high',
            onSelected: () {
              setState(() {
                _selectedPriority = 'high';
              });
            },
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'Normal',
            selected: _selectedPriority == 'normal',
            onSelected: () {
              setState(() {
                _selectedPriority = 'normal';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildRequestCard(AdminSupportRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminSupportRequestDetailsScreen(
                request: request,
              ),
            ),
          ).then((_) {
            _loadRequests();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      request.subject.isEmpty
                          ? 'Support Request'
                          : request.subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _priorityBadge(request.priority),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      request.ownerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _statusBadge(request.status),
                ],
              ),
              if (request.ownerEmail.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        request.ownerEmail,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (request.message.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  request.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 15,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatDate(request.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    final normalized = priority.toLowerCase();

    String label;
    IconData icon;

    switch (normalized) {
      case 'critical':
        label = 'Critical';
        icon = Icons.priority_high;
        break;
      case 'high':
        label = 'High';
        icon = Icons.warning_amber_rounded;
        break;
      default:
        label = 'Normal';
        icon = Icons.info_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _priorityColor(normalized),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: _priorityColor(normalized),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _priorityColor(normalized),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();

    final isResolved = normalized == 'resolved';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isResolved
            ? Colors.green.withValues(alpha: 0.10)
            : Colors.orange.withValues(alpha: 0.10),
      ),
      child: Text(
        isResolved ? 'Resolved' : 'Open',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isResolved ? Colors.green : Colors.orange,
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildEmptyState() {
    final hasFilters =
        _searchText.isNotEmpty ||
        _selectedStatus != 'all' ||
        _selectedPriority != 'all';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 70,
      ),
      child: Column(
        children: [
          Icon(
            hasFilters
                ? Icons.search_off
                : Icons.support_agent,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? 'No matching support requests'
                : 'No support requests yet',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try changing the search or filters.'
                : 'Support requests from owners will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Date unavailable';
    }

    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    final hour = local.hour == 0
        ? 12
        : local.hour > 12
            ? local.hour - 12
            : local.hour;

    final minute = local.minute.toString().padLeft(2, '0');

    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year $hour:$minute $period';
  }
}

class AdminSupportRequestDetailsScreen extends StatefulWidget {
  const AdminSupportRequestDetailsScreen({
    super.key,
    required this.request,
  });

  final AdminSupportRequest request;

  @override
  State<AdminSupportRequestDetailsScreen> createState() =>
      _AdminSupportRequestDetailsScreenState();
}

class _AdminSupportRequestDetailsScreenState
    extends State<AdminSupportRequestDetailsScreen> {
  final AdminSupportService _service =
      AdminSupportService.instance;

  late String _status;
  late String _priority;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _status = widget.request.status;
    _priority = widget.request.priority;
  }

  Future<void> _changeStatus(String value) async {
    if (value == _status) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.updateStatus(
        ownerId: widget.request.ownerId,
        requestId: widget.request.id,
        status: value,
      );

      if (!mounted) return;

      setState(() {
        _status = value;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status updated successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
        ),
      );
    }
  }

  Future<void> _changePriority(String value) async {
    if (value == _priority) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.updatePriority(
        ownerId: widget.request.ownerId,
        requestId: widget.request.id,
        priority: value,
      );

      if (!mounted) return;

      setState(() {
        _priority = value;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Priority updated successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update priority: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOwnerCard(request),
            const SizedBox(height: 16),
            _buildRequestCard(request),
            const SizedBox(height: 16),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerCard(AdminSupportRequest request) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Owner',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    request.ownerName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (request.ownerEmail.isNotEmpty) ...[
              const SizedBox(height: 12),
              _infoRow(
                Icons.email_outlined,
                request.ownerEmail,
              ),
            ],
            if (request.ownerPhone.isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoRow(
                Icons.phone_outlined,
                request.ownerPhone,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(AdminSupportRequest request) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Subject',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              request.subject.isEmpty
                  ? 'No subject'
                  : request.subject,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Message',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              request.message.isEmpty
                  ? 'No message'
                  : request.message,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _infoRow(
              Icons.access_time,
              'Created: ${_formatDate(request.createdAt)}',
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.update,
              'Updated: ${_formatDate(request.updatedAt)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _status == 'resolved'
                  ? 'resolved'
                  : 'open',
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'open',
                  child: Text('Open'),
                ),
                DropdownMenuItem(
                  value: 'resolved',
                  child: Text('Resolved'),
                ),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value != null) {
                        _changeStatus(value);
                      }
                    },
            ),
            const SizedBox(height: 20),
            const Text(
              'Priority',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _priority == 'critical' ||
                      _priority == 'high' ||
                      _priority == 'normal'
                  ? _priority
                  : 'normal',
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'critical',
                  child: Text('Critical'),
                ),
                DropdownMenuItem(
                  value: 'high',
                  child: Text('High'),
                ),
                DropdownMenuItem(
                  value: 'normal',
                  child: Text('Normal'),
                ),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value != null) {
                        _changePriority(value);
                      }
                    },
            ),
            if (_isSaving) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Date unavailable';
    }

    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    final hour = local.hour == 0
        ? 12
        : local.hour > 12
            ? local.hour - 12
            : local.hour;

    final minute = local.minute.toString().padLeft(2, '0');

    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year $hour:$minute $period';
  }
}