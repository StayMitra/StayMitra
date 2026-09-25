import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'building_model.dart';
import 'firebase_migration_service.dart';
import 'pg_manager_service.dart';

class FirebaseMigrationScreen extends StatefulWidget {
  final String ownerId;

  const FirebaseMigrationScreen({
    super.key,
    required this.ownerId,
  });

  @override
  State<FirebaseMigrationScreen> createState() =>
      _FirebaseMigrationScreenState();
}

class _FirebaseMigrationScreenState
    extends State<FirebaseMigrationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loadingPgs = true;
  bool _migrating = false;

  String? _errorMessage;
  String? _successMessage;

  User? _firebaseUser;

  List<BuildingModel> _localPgs = [];

  FirebaseMigrationResult? _migrationResult;

  @override
  void initState() {
    super.initState();
    _loadMigrationData();
  }

  Future<void> _loadMigrationData() async {
    setState(() {
      _loadingPgs = true;
      _errorMessage = null;
    });

    try {
      final user = _auth.currentUser;

      final pgs = await PgManagerService.getAllPgs(
        ownerId: widget.ownerId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _firebaseUser = user;
        _localPgs = pgs;
        _loadingPgs = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingPgs = false;
        _errorMessage =
            'Unable to load local PG data.\n\n$e';
      });
    }
  }

  Future<void> _startMigration() async {
    if (_migrating) {
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      setState(() {
        _errorMessage =
            'Firebase user is not logged in.\n'
            'Please login first and try again.';
        _successMessage = null;
      });
      return;
    }

    final confirmed = await _showMigrationConfirmation();

    if (!confirmed) {
      return;
    }

    setState(() {
      _migrating = true;
      _errorMessage = null;
      _successMessage = null;
      _migrationResult = null;
    });

    try {
      final result =
          await FirebaseMigrationService.instance.migrateAllData(
        localOwnerId: widget.ownerId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _migrating = false;
        _migrationResult = result;
        _successMessage =
            'Migration completed successfully.';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _migrating = false;
        _errorMessage =
            'Migration failed.\n\n$e';
      });
    }
  }

  Future<bool> _showMigrationConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Confirm Migration',
                ),
              ),
            ],
          ),
          content: const Text(
            'The existing SQLite data will be copied to Firebase.\n\n'
            'Your local SQLite data will NOT be deleted or modified.\n\n'
            'Do you want to start the migration?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('START MIGRATION'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Widget _buildHeader() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 28,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'SQLite → Firebase Migration',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.person_outline,
              title: 'Firebase Account',
              value: _firebaseUser?.email ??
                  'Not logged in',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.fingerprint,
              title: 'Firebase UID',
              value: _firebaseUser?.uid ??
                  'Not available',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.badge_outlined,
              title: 'Local Owner ID',
              value: widget.ownerId,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningCard() {
    return Card(
      color: Colors.orange.shade50,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.orange.shade800,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Important',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This migration copies your existing local SQLite '
                    'data to Firebase. SQLite data will NOT be deleted.',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You can safely run the migration again if required. '
                    'The migration service uses the existing record IDs.',
                    style: TextStyle(
                      color: Colors.orange.shade900,
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

  Widget _buildLocalPgsCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.apartment_outlined,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Local PGs / Properties',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!_loadingPgs)
                  CircleAvatar(
                    radius: 15,
                    child: Text(
                      '${_localPgs.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingPgs)
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 20,
                ),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_localPgs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 12,
                ),
                child: Text(
                  'No local PGs found for this owner.',
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: _localPgs.length,
                separatorBuilder: (
                  context,
                  index,
                ) {
                  return const Divider(
                    height: 1,
                  );
                },
                itemBuilder: (
                  context,
                  index,
                ) {
                  final pg = _localPgs[index];

                  // BuildingModel.address is nullable.
                  // Convert it safely to a non-null String.
                  final address =
                      pg.address?.trim() ?? '';

                  final subtitleLines =
                      <String>[];

                  if (address.isNotEmpty) {
                    subtitleLines.add(address);
                  }

                  subtitleLines.add(
                    'ID: ${pg.id}',
                  );

                  return ListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(
                        '${index + 1}',
                      ),
                    ),
                    title: Text(
                      pg.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      subtitleLines.join('\n'),
                    ),
                    isThreeLine:
                        address.isNotEmpty,
                    trailing: const Icon(
                      Icons.cloud_upload_outlined,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMigrationCounts() {
    final result = _migrationResult;

    if (result == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                ),
                SizedBox(width: 10),
                Text(
                  'Migration Result',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildCountRow(
              icon: Icons.apartment,
              title: 'Buildings / Properties',
              count: result.buildings,
            ),
            _buildCountRow(
              icon: Icons.layers_outlined,
              title: 'Floors',
              count: result.floors,
            ),
            _buildCountRow(
              icon: Icons.meeting_room_outlined,
              title: 'Rooms',
              count: result.rooms,
            ),
            _buildCountRow(
              icon: Icons.bed_outlined,
              title: 'Beds',
              count: result.beds,
            ),
            _buildCountRow(
              icon: Icons.people_outline,
              title: 'Tenants',
              count: result.tenants,
            ),
            _buildCountRow(
              icon: Icons
                  .account_balance_wallet_outlined,
              title: 'Transactions',
              count: result.transactions,
            ),
            _buildCountRow(
              icon: Icons.receipt_long_outlined,
              title: 'Bills',
              count: result.bills,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountRow({
    required IconData icon,
    required String title,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline,
              ),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_migrating) {
      return Card(
        margin: const EdgeInsets.only(
          bottom: 16,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Migration in progress...',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please do not close the application.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_successMessage != null) {
      return Card(
        color: Colors.green.shade50,
        margin: const EdgeInsets.only(
          bottom: 16,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _successMessage!,
                  style: TextStyle(
                    color: Colors.green.shade900,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        color: Colors.red.shade50,
        margin: const EdgeInsets.only(
          bottom: 16,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SelectableText(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButtons() {
    final firebaseAvailable =
        _firebaseUser != null;

    final localDataAvailable =
        _localPgs.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    (_migrating ||
                            !firebaseAvailable ||
                            !localDataAvailable)
                        ? null
                        : _startMigration,
                icon: _migrating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons
                            .cloud_upload_outlined,
                      ),
                label: Text(
                  _migrating
                      ? 'MIGRATION IN PROGRESS...'
                      : 'START MIGRATION',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child:
                  OutlinedButton.icon(
                onPressed:
                    _migrating
                        ? null
                        : _loadMigrationData,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'REFRESH LOCAL DATA',
                ),
              ),
            ),
            if (!firebaseAvailable) ...[
              const SizedBox(height: 12),
              Text(
                'Please login with Firebase before '
                'starting migration.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red.shade700,
                ),
              ),
            ],
            if (firebaseAvailable &&
                !localDataAvailable) ...[
              const SizedBox(height: 12),
              Text(
                'No local PG data is available '
                'for migration.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Firebase Migration',
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMigrationData,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),
              _buildWarningCard(),
              _buildLocalPgsCard(),
              _buildStatusCard(),
              _buildMigrationCounts(),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }
}