import 'package:flutter/material.dart';

import 'services/admin_owners_service.dart';

class OwnerTenantsScreen extends StatefulWidget {
  const OwnerTenantsScreen({
    super.key,
    required this.ownerId,
    required this.ownerName,
  });

  final String ownerId;
  final String ownerName;

  @override
  State<OwnerTenantsScreen> createState() =>
      _OwnerTenantsScreenState();
}

class _OwnerTenantsScreenState
    extends State<OwnerTenantsScreen> {
  List<Map<String, dynamic>> _tenants = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tenants =
          await AdminOwnersService.instance
              .getOwnerTenants(widget.ownerId);

      if (!mounted) return;

      setState(() {
        _tenants = tenants;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.ownerName} - Tenants'),
        actions: [
          IconButton(
            onPressed:
                _isLoading ? null : _loadTenants,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTenants,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(80),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _ErrorCard(
                message: _error!,
                onRetry: _loadTenants,
              )
            else if (_tenants.isEmpty)
              const Padding(
                padding: EdgeInsets.all(60),
                child: Center(
                  child: Text(
                    'No tenants found for this owner.',
                  ),
                ),
              )
            else
              ..._tenants.map(
                (tenant) => _TenantCard(
                  tenant: tenant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TenantCard extends StatelessWidget {
  const _TenantCard({
    required this.tenant,
  });

  final Map<String, dynamic> tenant;

  @override
  Widget build(BuildContext context) {
    final name =
        (tenant['full_name'] ??
                tenant['fullName'] ??
                tenant['name'] ??
                'Unnamed Tenant')
            .toString();

    final phone =
        (tenant['phone'] ?? '').toString();

    final room =
        (tenant['room_number'] ??
                tenant['roomNumber'] ??
                tenant['room_id'] ??
                '-')
            .toString();

    final status =
        (tenant['status'] ?? 'unknown')
            .toString();

    final property =
        (tenant['property_name'] ?? 'PG')
            .toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.all(14),
        leading: CircleAvatar(
          child: Text(
            name.isEmpty
                ? 'T'
                : name.substring(0, 1).toUpperCase(),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              if (phone.isNotEmpty)
                Text(phone),
              const SizedBox(height: 3),
              Text('PG: $property'),
              const SizedBox(height: 3),
              Text('Room: $room'),
            ],
          ),
        ),
        trailing: _StatusBadge(
          status: status,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized =
        status.toLowerCase().trim();

    Color color;

    if (normalized == 'active') {
      color = Colors.green;
    } else if (normalized == 'vacated' ||
        normalized == 'inactive') {
      color = Colors.grey;
    } else {
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
            color.withValues(alpha: 0.10),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status.isEmpty ? 'Unknown' : status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 45,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}