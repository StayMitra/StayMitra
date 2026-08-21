import 'package:flutter/material.dart';

import 'building_model.dart';
import 'building_setup_screen.dart';
import 'pg_manager_service.dart';

class PgSwitchScreen extends StatefulWidget {
  final String ownerId;

  const PgSwitchScreen({
    super.key,
    required this.ownerId,
  });

  @override
  State<PgSwitchScreen> createState() => _PgSwitchScreenState();
}

class _PgSwitchScreenState extends State<PgSwitchScreen> {
  bool _loading = true;
  bool _selecting = false;
  bool _addingPg = false;

  List<BuildingModel> _pgs = [];

  @override
  void initState() {
    super.initState();
    _loadPgs();
  }

  // ------------------------------------------------------------
  // LOAD PGs
  // ------------------------------------------------------------

  Future<void> _loadPgs() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final pgs = await PgManagerService.getAllPgs();

      if (!mounted) return;

      setState(() {
        _pgs = pgs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _pgs = [];
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load your PGs. ${e.toString()}',
          ),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // ADD PG
  // ------------------------------------------------------------

  Future<void> _addPg() async {
    if (_addingPg || _selecting) return;

    setState(() {
      _addingPg = true;
    });

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BuildingSetupScreen(
            ownerId: widget.ownerId,
          ),
        ),
      );

      if (!mounted) return;

      setState(() {
        _addingPg = false;
      });

      // PG was successfully added.
      // Reload PG list.
      if (result == true) {
        await _loadPgs();
      } else {
        // Even if the screen did not return true,
        // refresh once so newly created PGs are visible.
        await _loadPgs();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _addingPg = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open Add PG screen. ${e.toString()}',
          ),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // SELECT PG
  // ------------------------------------------------------------

  Future<void> _selectPg(BuildingModel pg) async {
    if (_selecting || _addingPg) return;

    setState(() {
      _selecting = true;
    });

    try {
      // Save selected PG as the active PG.
      await PgManagerService.selectPg(pg);

      if (!mounted) return;

      // Return to dashboard and tell it that PG was changed.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _selecting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to switch PG. ${e.toString()}',
          ),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // CHECK ACTIVE PG
  // ------------------------------------------------------------

  bool _isActivePg(BuildingModel pg) {
    final activePg = PgManagerService.activePg;

    if (activePg == null) {
      return false;
    }

    return activePg.id == pg.id;
  }

  // ------------------------------------------------------------
  // SCREEN
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),

        leading: IconButton(
          tooltip: 'Back',
          onPressed: (_selecting || _addingPg)
              ? null
              : () => Navigator.pop(context, false),
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        title: const Text(
          'Switch PG',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        // --------------------------------------------------------
        // ADD PG BUTTON
        // --------------------------------------------------------

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton.icon(
              onPressed: (_selecting || _addingPg)
                  ? null
                  : _addPg,
              icon: const Icon(
                Icons.add_rounded,
                size: 20,
              ),
              label: const Text(
                'Add PG',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadPgs,

              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  30,
                ),

                children: [
                  // ------------------------------------------
                  // YOUR PGs HEADER
                  // ------------------------------------------

                  _header(),

                  const SizedBox(height: 16),

                  // ------------------------------------------
                  // ADD PG CARD
                  // ------------------------------------------

                  _addPgCard(),

                  const SizedBox(height: 16),

                  // ------------------------------------------
                  // PG LIST
                  // ------------------------------------------

                  if (_pgs.isEmpty)
                    _emptyState()
                  else
                    ..._pgs.map(_pgCard),
                ],
              ),
            ),

      // Prevent accidental interaction while switching/adding
      bottomSheet: (_selecting || _addingPg)
          ? Container(
              height: 56,
              width: double.infinity,
              color: Colors.white,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _addingPg
                        ? 'Opening Add PG...'
                        : 'Switching PG...',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),

      child: const Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFFEFF6FF),

            child: Icon(
              Icons.swap_horiz_rounded,
              color: Color(0xFF2563EB),
              size: 28,
            ),
          ),

          SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your PGs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Select the PG you want to manage.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Tap a PG below to switch.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ADD PG CARD
  // ------------------------------------------------------------

  Widget _addPgCard() {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: (_selecting || _addingPg)
            ? null
            : _addPg,

        borderRadius: BorderRadius.circular(18),

        child: Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFBFDBFE),
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),

                child: const Icon(
                  Icons.add_business_rounded,
                  color: Color(0xFF2563EB),
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New PG',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'Add another PG to your account.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Color(0xFF2563EB),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PG CARD
  // ------------------------------------------------------------

  Widget _pgCard(BuildingModel pg) {
    final isActive = _isActivePg(pg);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: isActive
              ? const Color(0xFF2563EB)
              : const Color(0xFFE5E7EB),
          width: isActive ? 1.5 : 1,
        ),

        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(
                    alpha: 0.08,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: _selecting || _addingPg
              ? null
              : () => _selectPg(pg),

          borderRadius: BorderRadius.circular(18),

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Row(
              children: [
                // ------------------------------------------
                // BUILDING ICON
                // ------------------------------------------

                Container(
                  width: 52,
                  height: 52,

                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: const Icon(
                    Icons.apartment_rounded,
                    color: Color(0xFF2563EB),
                    size: 28,
                  ),
                ),

                const SizedBox(width: 14),

                // ------------------------------------------
                // PG DETAILS
                // ------------------------------------------

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pg.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),

                          if (isActive) ...[
                            const SizedBox(width: 8),

                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),

                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),

                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      if (pg.address != null &&
                          pg.address!.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),

                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: Color(0xFF94A3B8),
                            ),

                            const SizedBox(width: 4),

                            Expanded(
                              child: Text(
                                pg.address!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,

                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (isActive) ...[
                        const SizedBox(height: 6),

                        const Text(
                          'Currently managing this PG',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ------------------------------------------
                // ARROW
                // ------------------------------------------

                Icon(
                  isActive
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: isActive
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),

      child: Column(
        children: [
          const Icon(
            Icons.apartment_outlined,
            size: 50,
            color: Color(0xFF94A3B8),
          ),

          const SizedBox(height: 12),

          const Text(
            'No PGs added yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Add your first PG to start managing it.',
            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: (_selecting || _addingPg)
                ? null
                : _addPg,

            icon: const Icon(
              Icons.add_rounded,
            ),

            label: const Text(
              'Add PG',
            ),

            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,

              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 12,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}