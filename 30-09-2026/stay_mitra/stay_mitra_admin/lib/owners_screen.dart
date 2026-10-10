import 'package:flutter/material.dart';

import 'services/admin_owners_service.dart';
import 'owner_properties_screen.dart';
import 'owner_tenants_screen.dart';

class AdminOwnersScreen extends StatefulWidget {
  const AdminOwnersScreen({super.key});

  @override
  State<AdminOwnersScreen> createState() =>
      _AdminOwnersScreenState();
}

class _AdminOwnersScreenState
    extends State<AdminOwnersScreen> {
  List<AdminOwnerSummary> _owners = [];

  bool _isLoading = true;
  String? _error;

  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadOwners();
  }

  Future<void> _loadOwners() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final owners =
          await AdminOwnersService.instance.getOwners();

      if (!mounted) return;

      setState(() {
        _owners = owners;
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

  List<AdminOwnerSummary> get _filteredOwners {
    final query = _searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return _owners;
    }

    return _owners.where((owner) {
      return owner.name
              .toLowerCase()
              .contains(query) ||
          owner.email
              .toLowerCase()
              .contains(query) ||
          owner.phone
              .toLowerCase()
              .contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredOwners = _filteredOwners;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Owners',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoading ? null : _loadOwners,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOwners,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText:
                    'Search owner, email or phone',
                prefixIcon: const Icon(
                  Icons.search,
                ),
                suffixIcon:
                    _searchText.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              setState(() {
                                _searchText = '';
                              });
                            },
                            icon: const Icon(
                              Icons.clear,
                            ),
                          ),
                border:
                    const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 80,
                ),
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _ErrorCard(
                message: _error!,
                onRetry: _loadOwners,
              )
            else if (_owners.isEmpty)
              const _EmptyOwnersCard()
            else if (filteredOwners.isEmpty)
              const _NoSearchResultsCard()
            else
              ...filteredOwners.map(
                (owner) => Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: _OwnerCard(
                    owner: owner,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminOwnerDetailsScreen(
                            ownerId: owner.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// OWNER CARD
// ================================================================

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({
    required this.owner,
    required this.onTap,
  });

  final AdminOwnerSummary owner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Text(
                      _initials(owner.name),
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          owner.name,
                          style:
                              const TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          owner.email,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          owner.phone,
                          style:
                              Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      icon:
                          Icons.apartment_outlined,
                      label: 'PGs',
                      value:
                          owner.pgCount,
                    ),
                  ),

                  Expanded(
                    child: _MiniStat(
                      icon:
                          Icons.people_outline,
                      label: 'Tenants',
                      value:
                          owner.tenantCount,
                    ),
                  ),

                  Expanded(
                    child: _SubscriptionBadge(
                      status:
                          owner.subscriptionStatus,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where(
          (part) => part.isNotEmpty,
        )
        .toList();

    if (parts.isEmpty) {
      return 'O';
    }

    if (parts.length == 1) {
      return parts.first
          .substring(
            0,
            parts.first.length > 1
                ? 2
                : 1,
          )
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }
}

// ================================================================
// MINI STAT
// ================================================================

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 21,
          color:
              Theme.of(context)
                  .colorScheme
                  .primary,
        ),

        const SizedBox(height: 4),

        Text(
          value.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        Text(
          label,
          style:
              Theme.of(context)
                  .textTheme
                  .bodySmall,
        ),
      ],
    );
  }
}

// ================================================================
// SUBSCRIPTION BADGE
// ================================================================

class _SubscriptionBadge
    extends StatelessWidget {
  const _SubscriptionBadge({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized =
        status.toLowerCase().trim();

    Color color;

    switch (normalized) {
      case 'active':
        color = Colors.green;
        break;

      case 'trial':
        color = Colors.blue;
        break;

      case 'expired':
        color = Colors.red;
        break;

      case 'payment_pending':
        color = Colors.orange;
        break;

      default:
        color = Colors.grey;
    }

    final label = normalized.isEmpty
        ? 'Unknown'
        : normalized
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) => word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1)}',
            )
            .join(' ');

    return Column(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(
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
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'Plan',
          style:
              Theme.of(context)
                  .textTheme
                  .bodySmall,
        ),
      ],
    );
  }
}

// ================================================================
// OWNER DETAILS
// ================================================================

class AdminOwnerDetailsScreen
    extends StatefulWidget {
  const AdminOwnerDetailsScreen({
    super.key,
    required this.ownerId,
  });

  final String ownerId;

  @override
  State<AdminOwnerDetailsScreen> createState() =>
      _AdminOwnerDetailsScreenState();
}

class _AdminOwnerDetailsScreenState
    extends State<AdminOwnerDetailsScreen> {
  AdminOwnerDetails? _owner;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOwner();
  }

  Future<void> _loadOwner() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final owner =
          await AdminOwnersService.instance
              .getOwnerDetails(
        widget.ownerId,
      );

      if (!mounted) return;

      if (owner == null) {
        setState(() {
          _error = 'Owner not found.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _owner = owner;
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
        title: const Text(
          'Owner Details',
        ),
        actions: [
          IconButton(
            onPressed:
                _isLoading ? null : _loadOwner,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOwner,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 100,
                ),
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _ErrorCard(
                message: _error!,
                onRetry: _loadOwner,
              )
            else if (_owner != null)
              _buildDetails(
                context,
                _owner!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    AdminOwnerDetails owner,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  child: Text(
                    _getInitials(owner.name),
                    style:
                        const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  owner.name,
                  textAlign:
                      TextAlign.center,
                  style:
                      Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                ),

                const SizedBox(height: 6),

                Text(
                  owner.email,
                  textAlign:
                      TextAlign.center,
                ),

                const SizedBox(height: 4),

                Text(
                  owner.phone,
                  textAlign:
                      TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            // ======================================================
            // PGs - CLICKABLE
            // ======================================================
            Expanded(
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          OwnerPropertiesScreen(
                        ownerId: owner.id,
                        ownerName: owner.name,
                      ),
                    ),
                  );
                },
                child: _DetailStatCard(
                  icon:
                      Icons.apartment_outlined,
                  label: 'PGs',
                  value:
                      owner.pgCount,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ======================================================
            // TENANTS - CLICKABLE
            // ======================================================
            Expanded(
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          OwnerTenantsScreen(
                        ownerId: owner.id,
                        ownerName: owner.name,
                      ),
                    ),
                  );
                },
                child: _DetailStatCard(
                  icon:
                      Icons.people_outline,
                  label: 'Tenants',
                  value:
                      owner.tenantCount,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.card_membership_outlined,
                ),
                title: const Text(
                  'Subscription',
                ),
                trailing:
                    _SubscriptionBadge(
                  status:
                      owner.subscriptionStatus,
                ),
              ),

              const Divider(
                height: 1,
              ),

              ListTile(
                leading: const Icon(
                  Icons.email_outlined,
                ),
                title: const Text(
                  'Email',
                ),
                subtitle:
                    Text(owner.email),
              ),

              const Divider(
                height: 1,
              ),

              ListTile(
                leading: const Icon(
                  Icons.phone_outlined,
                ),
                title: const Text(
                  'Phone',
                ),
                subtitle:
                    Text(owner.phone),
              ),

              if (owner.createdAt != null) ...[
                const Divider(
                  height: 1,
                ),
                ListTile(
                  leading: const Icon(
                    Icons.calendar_today_outlined,
                  ),
                  title: const Text(
                    'Created',
                  ),
                  subtitle: Text(
                    _formatDate(
                      owner.createdAt!,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding:
                const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Owner ID',
                  style:
                      Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                ),

                const SizedBox(height: 8),

                SelectableText(
                  owner.id,
                  style:
                      const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where(
          (part) => part.isNotEmpty,
        )
        .toList();

    if (parts.isEmpty) {
      return 'O';
    }

    if (parts.length == 1) {
      return parts.first
          .substring(
            0,
            parts.first.length > 1
                ? 2
                : 1,
          )
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');
    final month =
        date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }
}

// ================================================================
// DETAIL STAT CARD
// ================================================================

class _DetailStatCard
    extends StatelessWidget {
  const _DetailStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(
              icon,
              size: 30,
              color:
                  Theme.of(context)
                      .colorScheme
                      .primary,
            ),

            const SizedBox(height: 8),

            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(label),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// EMPTY STATE
// ================================================================

class _EmptyOwnersCard
    extends StatelessWidget {
  const _EmptyOwnersCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding:
            EdgeInsets.all(30),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 50,
            ),
            SizedBox(height: 12),
            Text(
              'No owners found.',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResultsCard
    extends StatelessWidget {
  const _NoSearchResultsCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding:
            EdgeInsets.all(30),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 50,
            ),
            SizedBox(height: 12),
            Text(
              'No matching owners found.',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// ERROR CARD
// ================================================================

class _ErrorCard
    extends StatelessWidget {
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
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 45,
            ),

            const SizedBox(height: 12),

            const Text(
              'Unable to load owners.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(height: 16),

            FilledButton(
              onPressed: onRetry,
              child:
                  const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}