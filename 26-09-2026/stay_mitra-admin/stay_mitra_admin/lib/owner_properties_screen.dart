import 'package:flutter/material.dart';

import 'services/admin_owners_service.dart';

class OwnerPropertiesScreen extends StatefulWidget {
  const OwnerPropertiesScreen({
    super.key,
    required this.ownerId,
    required this.ownerName,
  });

  final String ownerId;
  final String ownerName;

  @override
  State<OwnerPropertiesScreen> createState() =>
      _OwnerPropertiesScreenState();
}

class _OwnerPropertiesScreenState
    extends State<OwnerPropertiesScreen> {
  List<Map<String, dynamic>> _properties = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final properties =
          await AdminOwnersService.instance
              .getOwnerProperties(widget.ownerId);

      if (!mounted) return;

      setState(() {
        _properties = properties;
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
        title: Text('${widget.ownerName} - PGs'),
        actions: [
          IconButton(
            onPressed:
                _isLoading ? null : _loadProperties,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProperties,
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
                onRetry: _loadProperties,
              )
            else if (_properties.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(60),
                  child: Text(
                    'No PGs found for this owner.',
                  ),
                ),
              )
            else
              ..._properties.map(
                (property) => _PropertyCard(
                  property: property,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.property,
  });

  final Map<String, dynamic> property;

  @override
  Widget build(BuildContext context) {
    final name =
        (property['name'] ??
                property['pg_name'] ??
                property['property_name'] ??
                'Unnamed PG')
            .toString();

    final address =
        (property['address'] ?? '').toString();

    final id =
        (property['id'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          child: const Icon(
            Icons.apartment,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              if (address.isNotEmpty)
                Text(address),
              const SizedBox(height: 4),
              Text(
                'Property ID: $id',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
          ),
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