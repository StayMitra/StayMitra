import 'package:flutter/material.dart';

import 'add_tenant_screen.dart';
import 'database_helper.dart';
import 'tenant_model.dart';

class TenantManagementScreen extends StatefulWidget {
  const TenantManagementScreen({super.key});

  @override
  State<TenantManagementScreen> createState() =>
      _TenantManagementScreenState();
}

class _TenantManagementScreenState
    extends State<TenantManagementScreen> {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final TextEditingController _searchController =
      TextEditingController();

  // ============================================================
  // DATA
  // ============================================================

  List<TenantModel> _tenants = [];

  bool _isLoading = true;

  String _selectedFilter = 'All';

  // ============================================================
  // FILTERS
  // ============================================================

  final List<String> _filters = [
    'All',
    'Active',
    'Vacated',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _onSearchChanged,
    );

    _loadTenants();
  }

  // ============================================================
  // SEARCH CHANGE
  // ============================================================

  void _onSearchChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.removeListener(
      _onSearchChanged,
    );

    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD TENANTS
  // ============================================================

  Future<void> _loadTenants() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final tenants =
          await DatabaseHelper.instance.getTenants();

      if (!mounted) {
        return;
      }

      setState(() {
        _tenants = tenants;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showError(
        'Unable to load tenants.',
      );
    }
  }

  // ============================================================
  // FILTERED TENANTS
  // ============================================================

  List<TenantModel> get _filteredTenants {
    final search =
        _searchController.text.trim().toLowerCase();

    return _tenants.where((tenant) {
      // --------------------------------------------------------
      // STATUS FILTER
      // --------------------------------------------------------

      if (_selectedFilter == 'Active' &&
          !tenant.isActive) {
        return false;
      }

      if (_selectedFilter == 'Vacated' &&
          !tenant.isVacated) {
        return false;
      }

      // --------------------------------------------------------
      // SEARCH
      // --------------------------------------------------------

      if (search.isEmpty) {
        return true;
      }

      final name =
          tenant.fullName.toLowerCase();

      final phone =
          tenant.phone.toLowerCase();

      final alternatePhone =
          (tenant.alternatePhone ?? '')
              .toLowerCase();

      final email =
          (tenant.email ?? '')
              .toLowerCase();

      final idProofNumber =
          (tenant.idProofNumber ?? '')
              .toLowerCase();

      return name.contains(search) ||
          phone.contains(search) ||
          alternatePhone.contains(search) ||
          email.contains(search) ||
          idProofNumber.contains(search);
    }).toList();
  }

  // ============================================================
  // COUNTS
  // ============================================================

  int get _totalCount {
    return _tenants.length;
  }

  int get _activeCount {
    return _tenants
        .where(
          (tenant) => tenant.isActive,
        )
        .length;
  }

  int get _vacatedCount {
    return _tenants
        .where(
          (tenant) => tenant.isVacated,
        )
        .length;
  }

  // ============================================================
  // MONEY FORMAT
  // ============================================================

  String _formatMoney(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(
            r'\B(?=(\d{3})+(?!\d))',
          ),
          (match) => ',',
        );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  // ============================================================
  // ADD TENANT
  // ============================================================

  Future<void> _openAddTenant() async {
    final result =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AddTenantScreen(),
      ),
    );

    if (result == true && mounted) {
      await _loadTenants();
    }
  }

  // ============================================================
  // TENANT DETAILS
  // ============================================================

  Future<void> _showTenantDetails(
    TenantModel tenant,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              8,
              18,
              30,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------
                // HEADER
                // ------------------------------------------------

                Row(
                  children: [
                    _buildAvatar(
                      tenant.fullName,
                      size: 56,
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            tenant.fullName,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Color(0xFF111827),
                            ),
                          ),

                          const SizedBox(height: 6),

                          _buildStatusChip(
                            tenant.status,
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // CONTACT
                // ------------------------------------------------

                _buildDetailsSection(
                  title:
                      'Contact Information',
                  icon:
                      Icons.contact_phone_rounded,
                  color:
                      const Color(0xFF2563EB),
                  children: [
                    _buildDetailRow(
                      Icons.phone_outlined,
                      'Phone',
                      tenant.phone,
                    ),

                    if (tenant
                            .alternatePhone
                            ?.trim()
                            .isNotEmpty ==
                        true)
                      _buildDetailRow(
                        Icons
                            .phone_in_talk_outlined,
                        'Alternate Phone',
                        tenant
                            .alternatePhone!,
                      ),

                    if (tenant.email
                            ?.trim()
                            .isNotEmpty ==
                        true)
                      _buildDetailRow(
                        Icons.email_outlined,
                        'Email',
                        tenant.email!,
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // ------------------------------------------------
                // ALLOCATION
                // ------------------------------------------------

                _buildDetailsSection(
                  title:
                      'Room Allocation',
                  icon:
                      Icons.bed_rounded,
                  color:
                      const Color(0xFF16A34A),
                  children: [
                    _buildDetailRow(
                      Icons.bed_outlined,
                      'Bed ID',
                      tenant.bedId,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ------------------------------------------------
                // TENANCY
                // ------------------------------------------------

                _buildDetailsSection(
                  title: 'Tenancy',
                  icon:
                      Icons.calendar_month_rounded,
                  color:
                      const Color(0xFF7C3AED),
                  children: [
                    _buildDetailRow(
                      Icons.login_rounded,
                      'Joining Date',
                      _formatDate(
                        tenant.joiningDate,
                      ),
                    ),

                    _buildDetailRow(
                      Icons.currency_rupee_rounded,
                      'Monthly Rent',
                      '₹ ${_formatMoney(tenant.monthlyRent)}',
                    ),

                    _buildDetailRow(
                      Icons
                          .account_balance_wallet_outlined,
                      'Security Deposit',
                      '₹ ${_formatMoney(tenant.securityDeposit)}',
                    ),

                    _buildDetailRow(
                      Icons.info_outline_rounded,
                      'Status',
                      tenant.isActive
                          ? 'Active'
                          : 'Vacated',
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ------------------------------------------------
                // ID PROOF
                // ------------------------------------------------

                if (tenant.idProofType != null ||
                    tenant.idProofNumber != null)
                  _buildDetailsSection(
                    title: 'ID Proof',
                    icon:
                        Icons.badge_rounded,
                    color:
                        const Color(0xFFF97316),
                    children: [
                      if (tenant.idProofType
                              ?.trim()
                              .isNotEmpty ==
                          true)
                        _buildDetailRow(
                          Icons.badge_outlined,
                          'Type',
                          tenant.idProofType!,
                        ),

                      if (tenant.idProofNumber
                              ?.trim()
                              .isNotEmpty ==
                          true)
                        _buildDetailRow(
                          Icons.numbers_rounded,
                          'Number',
                          tenant
                              .idProofNumber!,
                        ),
                    ],
                  ),

                const SizedBox(height: 22),

                // ------------------------------------------------
                // VACATE
                // ------------------------------------------------

                if (tenant.isActive)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child:
                        OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );

                        _confirmVacate(
                          tenant,
                        );
                      },
                      icon: const Icon(
                        Icons.logout_rounded,
                      ),
                      label: const Text(
                        'Vacate Tenant',
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color(
                          0xFFDC2626,
                        ),
                        side:
                            const BorderSide(
                          color:
                              Color(0xFFFECACA),
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CONFIRM VACATE
  // ============================================================

  Future<void> _confirmVacate(
    TenantModel tenant,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Vacate Tenant?',
          ),
          content: Text(
            'Are you sure you want to vacate '
            '${tenant.fullName}?\n\n'
            'The current bed will automatically '
            'become available.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFDC2626,
                ),
              ),
              child: const Text(
                'Vacate',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _vacateTenant(
      tenant,
    );
  }

  // ============================================================
  // VACATE TENANT
  // ============================================================

  Future<void> _vacateTenant(
    TenantModel tenant,
  ) async {
    try {
      await DatabaseHelper.instance
          .vacateTenant(
        tenant.id,
      );

      if (!mounted) {
        return;
      }

      await _loadTenants();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${tenant.fullName} vacated successfully. '
            'Bed is now available.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to vacate tenant.',
      );
    }
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  Future<void> _confirmDelete(
    TenantModel tenant,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Tenant?',
          ),
          content: Text(
            'This will permanently delete '
            '${tenant.fullName} from the tenant records.\n\n'
            'Do you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFDC2626,
                ),
              ),
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _deleteTenant(
      tenant,
    );
  }

  // ============================================================
  // DELETE TENANT
  // ============================================================

  Future<void> _deleteTenant(
    TenantModel tenant,
  ) async {
    try {
      await DatabaseHelper.instance
          .deleteTenant(
        tenant.id,
      );

      if (!mounted) {
        return;
      }

      await _loadTenants();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${tenant.fullName} deleted successfully.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to delete tenant.',
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F9FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF111827),
        title: const Text(
          'Tenant Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadTenants,
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _openAddTenant,
        backgroundColor:
            const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(
          Icons.person_add_alt_1_rounded,
        ),
        label: const Text(
          'Add Tenant',
        ),
      ),

      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadTenants,
              child: _buildBody(),
            ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    final tenants =
        _filteredTenants;

    return SingleChildScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        100,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 1000,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildOverviewCards(),

              const SizedBox(height: 18),

              _buildSearchBox(),

              const SizedBox(height: 14),

              _buildFilters(),

              const SizedBox(height: 18),

              if (tenants.isEmpty)
                _buildEmptyState()
              else
                _buildTenantList(
                  tenants,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OVERVIEW CARDS
  // ============================================================

  Widget _buildOverviewCards() {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final isSmall =
            constraints.maxWidth < 600;

        return GridView.count(
          crossAxisCount:
              isSmall ? 2 : 3,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio:
              isSmall ? 1.35 : 1.9,
          children: [
            _buildStatCard(
              title: 'Total Tenants',
              value:
                  _totalCount.toString(),
              subtitle: 'All tenants',
              icon:
                  Icons.people_alt_rounded,
              color:
                  const Color(0xFF2563EB),
            ),
            _buildStatCard(
              title: 'Active',
              value:
                  _activeCount.toString(),
              subtitle:
                  'Currently staying',
              icon:
                  Icons.person_rounded,
              color:
                  const Color(0xFF16A34A),
            ),
            _buildStatCard(
              title: 'Vacated',
              value:
                  _vacatedCount.toString(),
              subtitle:
                  'Past tenants',
              icon:
                  Icons.person_off_rounded,
              color:
                  const Color(0xFFF97316),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style:
                    const TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF111827),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style:
                const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
              color:
                  Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style:
                const TextStyle(
              fontSize: 10,
              color:
                  Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH BOX
  // ============================================================

  Widget _buildSearchBox() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),
      child: TextField(
        controller:
            _searchController,
        decoration:
            InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            color:
                Color(0xFF6B7280),
          ),
          suffixIcon:
              _searchController
                      .text
                      .isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController
                            .clear();
                      },
                      icon:
                          const Icon(
                        Icons.close_rounded,
                      ),
                    )
                  : null,
          hintText:
              'Search by name, phone, email or ID proof',
          hintStyle:
              const TextStyle(
            fontSize: 13,
            color:
                Color(0xFF9CA3AF),
          ),
          filled: true,
          fillColor:
              const Color(0xFFF8FAFC),
          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              13,
            ),
            borderSide:
                BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal,
      child: Row(
        children:
            _filters.map((filter) {
          final selected =
              _selectedFilter ==
                  filter;

          return Padding(
            padding:
                const EdgeInsets.only(
              right: 8,
            ),
            child: ChoiceChip(
              selected: selected,
              label: Text(
                filter,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : const Color(
                          0xFF374151,
                        ),
                ),
              ),
              selectedColor:
                  const Color(
                0xFF2563EB,
              ),
              backgroundColor:
                  Colors.white,
              side: BorderSide(
                color: selected
                    ? const Color(
                        0xFF2563EB,
                      )
                    : const Color(
                        0xFFE5E7EB,
                      ),
              ),
              showCheckmark: false,
              onSelected: (_) {
                setState(() {
                  _selectedFilter =
                      filter;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // TENANT LIST
  // ============================================================

  Widget _buildTenantList(
    List<TenantModel> tenants,
  ) {
    return Column(
      children:
          tenants.map((tenant) {
        return Padding(
          padding:
              const EdgeInsets.only(
            bottom: 12,
          ),
          child:
              _buildTenantCard(
            tenant,
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // TENANT CARD
  // ============================================================

  Widget _buildTenantCard(
    TenantModel tenant,
  ) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(18),
      onTap: () {
        _showTenantDetails(
          tenant,
        );
      },
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color:
                const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.02,
              ),
              blurRadius: 8,
              offset:
                  const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildAvatar(
              tenant.fullName,
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tenant.fullName,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(
                              0xFF111827,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      _buildStatusChip(
                        tenant.status,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .phone_outlined,
                        size: 15,
                        color:
                            Color(
                          0xFF6B7280,
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        tenant.phone,
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color:
                              Color(
                            0xFF6B7280,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Wrap(
                    spacing: 7,
                    runSpacing: 5,
                    children: [
                      _buildInfoTag(
                        Icons
                            .bed_outlined,
                        'Bed',
                        tenant.bedId,
                      ),
                      _buildInfoTag(
                        Icons
                            .currency_rupee_rounded,
                        'Rent',
                        '₹ ${_formatMoney(tenant.monthlyRent)}',
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    'Joined ${_formatDate(tenant.joiningDate)}',
                    style:
                        const TextStyle(
                      fontSize: 11,
                      color:
                          Color(
                        0xFF9CA3AF,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    _showTenantDetails(
                      tenant,
                    );
                    break;

                  case 'vacate':
                    _confirmVacate(
                      tenant,
                    );
                    break;

                  case 'delete':
                    _confirmDelete(
                      tenant,
                    );
                    break;
                }
              },
              itemBuilder:
                  (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .visibility_outlined,
                        size: 20,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'View Details',
                      ),
                    ],
                  ),
                ),

                if (tenant.isActive)
                  const PopupMenuItem(
                    value: 'vacate',
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .logout_rounded,
                          size: 20,
                          color:
                              Color(
                            0xFFDC2626,
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Vacate Tenant',
                          style:
                              TextStyle(
                            color:
                                Color(
                              0xFFDC2626,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .delete_outline_rounded,
                        size: 20,
                        color:
                            Color(
                          0xFFDC2626,
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Delete',
                        style:
                            TextStyle(
                          color:
                              Color(
                            0xFFDC2626,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              icon: const Icon(
                Icons.more_vert_rounded,
                color:
                    Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar(
    String name, {
    double size = 48,
  }) {
    final initial =
        name.trim().isEmpty
            ? '?'
            : name.trim()[0]
                .toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment:
          Alignment.center,
      decoration: BoxDecoration(
        color:
            const Color(0xFFEFF6FF),
        borderRadius:
            BorderRadius.circular(
          size * 0.28,
        ),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize:
              size * 0.38,
          fontWeight:
              FontWeight.bold,
          color:
              const Color(0xFF2563EB),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _buildStatusChip(
    String status,
  ) {
    final active =
        status == 'active';

    final color = active
        ? const Color(0xFF16A34A)
        : const Color(0xFFF97316);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color:
            color.withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Text(
        active
            ? 'Active'
            : 'Vacated',
        style: TextStyle(
          fontSize: 10,
          fontWeight:
              FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // INFO TAG
  // ============================================================

  Widget _buildInfoTag(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF8FAFC),
        borderRadius:
            BorderRadius.circular(8),
        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color:
                const Color(0xFF6B7280),
          ),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style:
                const TextStyle(
              fontSize: 10,
              color:
                  Color(0xFF9CA3AF),
            ),
          ),
          Text(
            value,
            style:
                const TextStyle(
              fontSize: 10,
              fontWeight:
                  FontWeight.w600,
              color:
                  Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAILS SECTION
  // ============================================================

  Widget _buildDetailsSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration:
                    BoxDecoration(
                  color:
                      color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 19,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF111827),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color:
                const Color(0xFF6B7280),
          ),

          const SizedBox(
            width: 10,
          ),

          SizedBox(
            width: 105,
            child: Text(
              label,
              style:
                  const TextStyle(
                fontSize: 12,
                color:
                    Color(0xFF6B7280),
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
                color:
                    Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final hasSearch =
        _searchController.text
            .trim()
            .isNotEmpty;

    String title;

    if (hasSearch) {
      title = 'No tenants found';
    } else if (_selectedFilter ==
        'Active') {
      title = 'No active tenants';
    } else if (_selectedFilter ==
        'Vacated') {
      title = 'No vacated tenants';
    } else {
      title = 'No tenants yet';
    }

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            alignment:
                Alignment.center,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFEFF6FF),
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
            child: const Icon(
              Icons
                  .people_outline_rounded,
              size: 34,
              color:
                  Color(0xFF2563EB),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          Text(
            title,
            style:
                const TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
              color:
                  Color(0xFF111827),
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            hasSearch
                ? 'Try a different name, phone number or email.'
                : 'Add your first tenant to start managing occupancy.',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 12,
              color:
                  Color(0xFF6B7280),
              height: 1.4,
            ),
          ),

          if (!hasSearch &&
              _selectedFilter ==
                  'All') ...[
            const SizedBox(
              height: 18,
            ),
            FilledButton.icon(
              onPressed:
                  _openAddTenant,
              icon: const Icon(
                Icons
                    .person_add_alt_1_rounded,
              ),
              label: const Text(
                'Add Tenant',
              ),
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF2563EB,
                ),
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            const Color(0xFFDC2626),
      ),
    );
  }
}