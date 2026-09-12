import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'tenant_model.dart';
import 'bill_model.dart';
import 'database_helper.dart';
import 'package:share_plus/share_plus.dart';

class CreateBillScreen extends StatefulWidget {
  /// Selected PG / Building ID.
  ///
  /// If provided:
  /// Only active tenants belonging to this PG are shown.
  ///
  /// If null:
  /// Active tenants from all PGs will be shown.
  final String? buildingId;

  /// Optional PG / Building name.
  ///
  /// This is used only for the generated bill.
  final String? buildingName;

  const CreateBillScreen({
    super.key,
    this.buildingId,
    this.buildingName,
  });

  @override
  State<CreateBillScreen> createState() =>
      _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController rentController =
      TextEditingController();

  final TextEditingController electricityController =
      TextEditingController();

  final TextEditingController foodController =
      TextEditingController();

  final TextEditingController maintenanceController =
      TextEditingController();

  final TextEditingController otherController =
      TextEditingController();

  final TextEditingController discountController =
      TextEditingController();

  final TextEditingController notesController =
      TextEditingController();

  // ============================================================
  // TENANTS
  // ============================================================

  List<TenantModel> _tenants = [];

  String? selectedTenantId;

  String? _selectedTenantDropdownValue;

  bool _isLoadingTenants = false;

  bool _isGeneratingPdf = false;

  // ============================================================
  // BILLING
  // ============================================================

  String selectedMonth = 'September 2026';

  DateTime? dueDate;

  // ============================================================
  // SELECTED TENANT
  // ============================================================

  TenantModel? get _selectedTenant {
    if (selectedTenantId == null) {
      return null;
    }

    for (final tenant in _tenants) {
      if (tenant.id == selectedTenantId) {
        return tenant;
      }
    }

    return null;
  }

  String get selectedTenantName {
    final tenant = _selectedTenant;

    if (tenant == null) {
      return 'Select Tenant';
    }

    return tenant.fullName;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadTenants();

    rentController.addListener(_refreshTotal);
    electricityController.addListener(_refreshTotal);
    foodController.addListener(_refreshTotal);
    maintenanceController.addListener(_refreshTotal);
    otherController.addListener(_refreshTotal);
    discountController.addListener(_refreshTotal);
  }

  // ============================================================
  // LOAD TENANTS
  // ============================================================

  Future<void> _loadTenants() async {
    if (!mounted) return;

    setState(() {
      _isLoadingTenants = true;
    });

    try {
      List<TenantModel> tenants;

      final selectedBuildingId =
          widget.buildingId?.trim();

      // ========================================================
      // SELECTED PG ONLY
      // ========================================================

      if (selectedBuildingId != null &&
          selectedBuildingId.isNotEmpty) {
        tenants = await DatabaseHelper.instance
            .getActiveTenantsByBuilding(
          selectedBuildingId,
        );
      }

      // ========================================================
      // BACKWARD COMPATIBILITY
      // ========================================================

      else {
        tenants = await DatabaseHelper.instance
            .getActiveTenants();
      }

      // ========================================================
      // REMOVE DUPLICATE TENANT IDs
      // ========================================================

      final Map<String, TenantModel> uniqueTenants = {};

      for (final tenant in tenants) {
        uniqueTenants[tenant.id] = tenant;
      }

      final uniqueTenantList =
          uniqueTenants.values.toList();

      uniqueTenantList.sort(
        (a, b) => a.fullName
            .toLowerCase()
            .compareTo(
              b.fullName.toLowerCase(),
            ),
      );

      if (!mounted) return;

      setState(() {
        _tenants = uniqueTenantList;
        _isLoadingTenants = false;

        if (selectedTenantId != null &&
            !_tenants.any(
              (tenant) =>
                  tenant.id == selectedTenantId,
            )) {
          selectedTenantId = null;
          _selectedTenantDropdownValue = null;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingTenants = false;
        _tenants = [];
        selectedTenantId = null;
        _selectedTenantDropdownValue = null;
      });

      _showMessage(
        'Unable to load tenants.',
        isError: true,
      );
    }
  }

  // ============================================================
  // TENANT ID DISPLAY
  // ============================================================

  String _shortTenantId(String tenantId) {
    final value = tenantId.trim();

    if (value.length <= 6) {
      return value;
    }

    return value.substring(value.length - 6);
  }

  // ============================================================
  // UNIQUE DROPDOWN VALUE
  // ============================================================

  String _dropdownValueForTenant(
    TenantModel tenant,
    int index,
  ) {
    return 'tenant_dropdown_${index}_${tenant.id}';
  }

  // ============================================================
  // AMOUNT
  // ============================================================

  double _amount(String value) {
    return double.tryParse(
          value.trim(),
        ) ??
        0;
  }

  double get _subtotal {
    return _amount(rentController.text) +
        _amount(electricityController.text) +
        _amount(foodController.text) +
        _amount(maintenanceController.text) +
        _amount(otherController.text);
  }

  double get _discount {
    return _amount(
      discountController.text,
    );
  }

  double get _total {
    final total = _subtotal - _discount;

    return total < 0 ? 0 : total;
  }

  void _refreshTotal() {
    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDueDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(
        now.year + 2,
        12,
        31,
      ),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      dueDate = picked;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select due date';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // ============================================================
  // GENERATE BILL
  // ============================================================

Future<void> _generateBill() async {
  debugPrint('========== CREATE BILL BUTTON CLICKED ==========');

  try {
    if (!_formKey.currentState!.validate()) {
      debugPrint('FORM VALIDATION FAILED');
      _showMessage(
        'Please fill all required fields.',
        isError: true,
      );
      return;
    }

    debugPrint('FORM VALIDATION PASSED');

    final tenant = _selectedTenant;

    debugPrint('Selected Tenant: $tenant');
    debugPrint('Selected Tenant ID: ${tenant?.id}');
    debugPrint('Selected Tenant Name: ${tenant?.fullName}');
    debugPrint('Building ID from widget: ${widget.buildingId}');
    debugPrint('Due Date: $dueDate');
    debugPrint('Subtotal: $_subtotal');
    debugPrint('Discount: $_discount');
    debugPrint('Total: $_total');

    if (tenant == null) {
      _showMessage(
        'Please select a tenant.',
        isError: true,
      );
      return;
    }

    if (_total <= 0) {
      _showMessage(
        'Bill total must be greater than ₹0.',
        isError: true,
      );
      return;
    }

    /*
     * IMPORTANT:
     * Due date is NOT mandatory now.
     *
     * If user does not select a due date,
     * today's date will be used.
     */
    final effectiveDueDate = dueDate ?? DateTime.now();

    debugPrint(
      'Effective Due Date: ${effectiveDueDate.toIso8601String()}',
    );

    if (!mounted) return;

    setState(() {
      _isGeneratingPdf = true;
    });

    // ============================================================
    // CREATE BILL ID
    // ============================================================

    final billId =
        'BILL_${DateTime.now().microsecondsSinceEpoch}';

    debugPrint('Generated Bill ID: $billId');

    // ============================================================
    // RESOLVE BUILDING ID
    // ============================================================

    String? resolvedBuildingId =
        widget.buildingId?.trim();

    debugPrint(
      'Initial Building ID: $resolvedBuildingId',
    );

    final db =
        await DatabaseHelper.instance.database;

    /*
     * If Create Bill was not opened from a building,
     * find building through tenant -> bed -> room -> floor.
     */

    if (resolvedBuildingId == null ||
        resolvedBuildingId.isEmpty) {
      debugPrint(
        'Building ID missing. Trying to find building from tenant...',
      );

      final buildingResult = await db.rawQuery(
        '''
        SELECT f.building_id
        FROM tenants t
        INNER JOIN beds b
          ON t.bed_id = b.id
        INNER JOIN rooms r
          ON b.room_id = r.id
        INNER JOIN floors f
          ON r.floor_id = f.id
        WHERE t.id = ?
        LIMIT 1
        ''',
        [tenant.id],
      );

      debugPrint(
        'Building query result: $buildingResult',
      );

      if (buildingResult.isNotEmpty) {
        resolvedBuildingId =
            buildingResult.first['building_id']
                ?.toString();
      }
    }

    /*
     * If still missing, use an empty-safe fallback.
     * This prevents the old "Unable to create bill"
     * error caused only by missing buildingId.
     */

    if (resolvedBuildingId == null ||
        resolvedBuildingId.isEmpty) {
      debugPrint(
        'WARNING: Building ID could not be resolved.',
      );

      resolvedBuildingId = '';
    }

    debugPrint(
      'FINAL Building ID: $resolvedBuildingId',
    );

    // ============================================================
    // CREATE BILL MODEL
    // ============================================================

    final bill = BillModel(
      id: billId,
      tenantId: tenant.id,
      tenantName: tenant.fullName,
      buildingId: resolvedBuildingId,
      billType: selectedMonth,
      amount: _total,
      dueDate: effectiveDueDate.toIso8601String(),
      note: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      status: 'pending',
      createdAt: DateTime.now().toIso8601String(),
    );

    debugPrint(
      '========== BILL MODEL CREATED =========='
    );

    debugPrint('Bill ID: ${bill.id}');
    debugPrint('Tenant ID: ${bill.tenantId}');
    debugPrint('Tenant Name: ${bill.tenantName}');
    debugPrint('Building ID: ${bill.buildingId}');
    debugPrint('Bill Type: ${bill.billType}');
    debugPrint('Amount: ${bill.amount}');
    debugPrint('Due Date: ${bill.dueDate}');
    debugPrint('Status: ${bill.status}');

    // ============================================================
    // INSERT BILL
    // ============================================================

    debugPrint(
      '========== INSERTING BILL INTO DATABASE =========='
    );

    final inserted =
        await DatabaseHelper.instance.insertBill(bill);

    debugPrint(
      'DATABASE INSERT RESULT: $inserted',
    );

    if (inserted <= 0) {
      throw Exception(
        'Database insert returned $inserted',
      );
    }

    debugPrint(
      '========== BILL SAVED SUCCESSFULLY =========='
    );

    // ============================================================
    // CREATE PDF
    // ============================================================

    debugPrint(
      '========== CREATING PDF =========='
    );

    final bytes = await _createBillPdf();

    debugPrint(
      'PDF CREATED. BYTE COUNT: ${bytes.length}',
    );

    // ============================================================
    // SAVE PDF
    // ============================================================

    final directory =
        await getApplicationDocumentsDirectory();

    final file = File(
      '${directory.path}/${_billFileName()}',
    );

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    debugPrint(
      'PDF SAVED: ${file.path}',
    );

    if (!mounted) return;

    setState(() {
      _isGeneratingPdf = false;
    });

    // ============================================================
    // SUCCESS
    // ============================================================

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Bill Created Successfully',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _dialogRow(
                'PG',
                widget.buildingName ??
                    'PG / Building',
              ),
              _dialogRow(
                'Tenant',
                tenant.fullName,
              ),
              _dialogRow(
                'Bill ID',
                billId,
              ),
              _dialogRow(
                'Month',
                selectedMonth,
              ),
              _dialogRow(
                'Due Date',
                _formatDate(effectiveDueDate),
              ),
              const SizedBox(height: 10),
              Text(
                'Total: ₹${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _saveBillPdf();
              },
              icon: const Icon(
                Icons.picture_as_pdf,
              ),
              label: const Text(
                'Save / Share PDF',
              ),
            ),
          ],
        );
      },
    );
  } catch (e, stackTrace) {
    debugPrint(
      '========== BILL GENERATION ERROR =========='
    );

    debugPrint(
      'ERROR: $e',
    );

    debugPrint(
      'STACK TRACE: $stackTrace',
    );

    if (mounted) {
      setState(() {
        _isGeneratingPdf = false;
      });

      _showMessage(
        'Unable to create bill: $e',
        isError: true,
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }
}

  // ============================================================
  // DIALOG ROW
  // ============================================================

  Widget _dialogRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
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
  // CREATE PDF
  // ============================================================

  Future<Uint8List> _createBillPdf() async {
    final tenant = _selectedTenant;

    if (tenant == null) {
      throw Exception(
        'Tenant not selected',
      );
    }

    final pdf = pw.Document();

    final generatedDate =
        DateTime.now();

    final pgName =
        widget.buildingName ??
            'PG / Building';

    final pgId =
        widget.buildingId;

    pdf.addPage(
      pw.Page(
        pageFormat:
            PdfPageFormat.a4,
        margin:
            const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment:
                pw.CrossAxisAlignment
                    .start,
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              pw.Container(
                width: double.infinity,
                padding:
                    const pw.EdgeInsets.all(
                  20,
                ),
                decoration:
                    pw.BoxDecoration(
                  color: PdfColors.blue700,
                  borderRadius:
                      pw.BorderRadius.circular(
                    12,
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment
                          .start,
                  children: [
                    pw.Text(
                      pgName,
                      style:
                          pw.TextStyle(
                        fontSize: 22,
                        fontWeight:
                            pw.FontWeight.bold,
                        color:
                            PdfColors.white,
                      ),
                    ),

                    if (pgId != null &&
                        pgId.trim().isNotEmpty)
                      pw.Padding(
                        padding:
                            const pw.EdgeInsets
                                .only(
                          top: 5,
                        ),
                        child: pw.Text(
                          'PG ID: ${pgId.trim()}',
                          style:
                              const pw.TextStyle(
                            fontSize: 10,
                            color:
                                PdfColors.white,
                          ),
                        ),
                      ),

                    pw.SizedBox(
                      height: 8,
                    ),

                    pw.Text(
                      'MONTHLY RENT BILL',
                      style:
                          pw.TextStyle(
                        fontSize: 12,
                        fontWeight:
                            pw.FontWeight.bold,
                        color:
                            PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(
                height: 24,
              ),

              // ==================================================
              // TENANT INFORMATION
              // ==================================================

              pw.Text(
                'Tenant Information',
                style:
                    pw.TextStyle(
                  fontSize: 15,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(
                height: 10,
              ),

              pw.Container(
                width: double.infinity,
                padding:
                    const pw.EdgeInsets.all(
                  14,
                ),
                decoration:
                    pw.BoxDecoration(
                  border: pw.Border.all(
                    color:
                        PdfColors.grey300,
                  ),
                  borderRadius:
                      pw.BorderRadius.circular(
                    8,
                  ),
                ),
                child: pw.Column(
                  children: [
                    _pdfInfoRow(
                      'Tenant Name',
                      tenant.fullName,
                    ),

                    _pdfInfoRow(
                      'Tenant ID',
                      tenant.id,
                    ),

                    _pdfInfoRow(
                      'Billing Month',
                      selectedMonth,
                    ),

                    _pdfInfoRow(
                      'Due Date',
                      _formatDate(
                        dueDate,
                      ),
                    ),

                    _pdfInfoRow(
                      'Generated On',
                      _formatDate(
                        generatedDate,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(
                height: 24,
              ),

              // ==================================================
              // CHARGES
              // ==================================================

              pw.Text(
                'Bill Details',
                style:
                    pw.TextStyle(
                  fontSize: 15,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(
                height: 10,
              ),

              pw.Table(
                border:
                    pw.TableBorder.all(
                  color:
                      PdfColors.grey300,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(
                    3,
                  ),
                  1: const pw.FlexColumnWidth(
                    1.5,
                  ),
                },
                children: [
                  _pdfTableRow(
                    'Description',
                    'Amount',
                    isHeader: true,
                  ),

                  if (_amount(
                        rentController.text,
                      ) >
                      0)
                    _pdfTableRow(
                      'Rent',
                      _rupee(
                        _amount(
                          rentController.text,
                        ),
                      ),
                    ),

                  if (_amount(
                        electricityController
                            .text,
                      ) >
                      0)
                    _pdfTableRow(
                      'Electricity',
                      _rupee(
                        _amount(
                          electricityController
                              .text,
                        ),
                      ),
                    ),

                  if (_amount(
                        foodController.text,
                      ) >
                      0)
                    _pdfTableRow(
                      'Food / Mess',
                      _rupee(
                        _amount(
                          foodController.text,
                        ),
                      ),
                    ),

                  if (_amount(
                        maintenanceController
                            .text,
                      ) >
                      0)
                    _pdfTableRow(
                      'Maintenance',
                      _rupee(
                        _amount(
                          maintenanceController
                              .text,
                        ),
                      ),
                    ),

                  if (_amount(
                        otherController.text,
                      ) >
                      0)
                    _pdfTableRow(
                      'Other Charges',
                      _rupee(
                        _amount(
                          otherController.text,
                        ),
                      ),
                    ),

                  if (_discount > 0)
                    _pdfTableRow(
                      'Discount',
                      '- ${_rupee(_discount)}',
                    ),

                  _pdfTableRow(
                    'TOTAL',
                    _rupee(_total),
                    isTotal: true,
                  ),
                ],
              ),

              pw.SizedBox(
                height: 24,
              ),

              // ==================================================
              // NOTES
              // ==================================================

              if (notesController.text
                  .trim()
                  .isNotEmpty) ...[
                pw.Text(
                  'Notes',
                  style:
                      pw.TextStyle(
                    fontSize: 15,
                    fontWeight:
                        pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(
                  height: 8,
                ),

                pw.Container(
                  width: double.infinity,
                  padding:
                      const pw.EdgeInsets.all(
                    12,
                  ),
                  decoration:
                      pw.BoxDecoration(
                    border: pw.Border.all(
                      color:
                          PdfColors.grey300,
                    ),
                    borderRadius:
                        pw.BorderRadius
                            .circular(
                      8,
                    ),
                  ),
                  child: pw.Text(
                    notesController.text
                        .trim(),
                    style:
                        const pw.TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ),
              ],

              pw.Spacer(),

              // ==================================================
              // FOOTER
              // ==================================================

              pw.Divider(
                color:
                    PdfColors.grey300,
              ),

              pw.SizedBox(
                height: 8,
              ),

              pw.Center(
                child: pw.Text(
                  'Thank you for your payment.',
                  style:
                      const pw.TextStyle(
                    fontSize: 10,
                    color:
                        PdfColors.grey600,
                  ),
                ),
              ),

              pw.SizedBox(
                height: 4,
              ),

              pw.Center(
                child: pw.Text(
                  'Generated by Stay Mitra',
                  style:
                      const pw.TextStyle(
                    fontSize: 9,
                    color:
                        PdfColors.grey500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ============================================================
  // PDF INFO ROW
  // ============================================================

  pw.Widget _pdfInfoRow(
    String label,
    String value,
  ) {
    return pw.Padding(
      padding:
          const pw.EdgeInsets.only(
        bottom: 7,
      ),
      child: pw.Row(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style:
                  const pw.TextStyle(
                fontSize: 10,
                color:
                    PdfColors.grey600,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style:
                  pw.TextStyle(
                fontSize: 10,
                fontWeight:
                    pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PDF TABLE ROW
  // ============================================================

  pw.TableRow _pdfTableRow(
    String label,
    String amount, {
    bool isHeader = false,
    bool isTotal = false,
  }) {
    return pw.TableRow(
      decoration: isHeader || isTotal
          ? const pw.BoxDecoration(
              color: PdfColors.grey200,
            )
          : null,
      children: [
        pw.Padding(
          padding:
              const pw.EdgeInsets.all(
            10,
          ),
          child: pw.Text(
            label,
            style:
                pw.TextStyle(
              fontSize: 10,
              fontWeight:
                  isHeader || isTotal
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding:
              const pw.EdgeInsets.all(
            10,
          ),
          child: pw.Align(
            alignment:
                pw.Alignment.centerRight,
            child: pw.Text(
              amount,
              style:
                  pw.TextStyle(
                fontSize: 10,
                fontWeight:
                    isHeader || isTotal
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RUPEE
  // ============================================================

  String _rupee(double value) {
    return 'Rs. ${value.toStringAsFixed(2)}';
  }

  // ============================================================
  // PREVIEW BILL
  // ============================================================

  Future<void> _previewBill() async {
    try {
      setState(() {
        _isGeneratingPdf = true;
      });

      final bytes =
          await _createBillPdf();

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Bill Preview',
                ),
              ),
              body: PdfPreview(
                build: (format) async {
                  return bytes;
                },
                allowPrinting: true,
                allowSharing: true,
                canChangePageFormat: false,
                canChangeOrientation: false,
                pdfFileName:
                    _billFileName(),
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Unable to create PDF.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  // ============================================================
  // SAVE / DOWNLOAD PDF
  // ============================================================

  Future<void> _saveBillPdf() async {
    try {
      setState(() {
        _isGeneratingPdf = true;
      });

      final bytes = await _createBillPdf();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${_billFileName()}');

      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;

      _showMessage(
        'PDF saved. Choose Files / Downloads from the share screen to save a copy.',
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Stay Mitra Bill',
          subject: _billFileName(),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Unable to save PDF: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  // ============================================================
  // SHARE PDF
  // ============================================================

  Future<void> _shareBillPdf() async {
    try {
      setState(() {
        _isGeneratingPdf = true;
      });

      final bytes =
          await _createBillPdf();

      final directory =
          await getTemporaryDirectory();

      final file = File(
        '${directory.path}/${_billFileName()}',
      );

      await file.writeAsBytes(
        bytes,
        flush: true,
      );

await SharePlus.instance.share(
  ShareParams(
    files: [
      XFile(file.path),
    ],
    text: 'Bill PDF',
    subject: 'Bill PDF',
  ),
);
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Unable to share bill.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  // ============================================================
  // FILE NAME
  // ============================================================

  String _billFileName() {
    final tenant =
        _selectedTenant;

    final tenantName =
        tenant?.fullName
                .replaceAll(
                  RegExp(r'[^a-zA-Z0-9]+'),
                  '_',
                ) ??
            'Tenant';

    final month =
        selectedMonth.replaceAll(
      ' ',
      '_',
    );

    return 'Stay_Mitra_Bill_${tenantName}_$month.pdf';
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
          backgroundColor: isError
              ? const Color(0xFFDC2626)
              : null,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F8FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF111827),

        title: const Text(
          'Create Bill',
          style: TextStyle(
            fontSize: 21,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          if (widget.buildingId != null &&
              widget.buildingId!
                  .trim()
                  .isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(
                right: 12,
              ),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(0xFFEFF6FF),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: Text(
                    widget.buildingName ??
                        'Selected PG',
                    style:
                        const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              30,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // ==================================================
                // BILL INFORMATION
                // ==================================================

                const Text(
                  'Bill Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF111827),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                _card(
                  child: Column(
                    children: [
                      _tenantDropdown(),

                      const SizedBox(
                        height: 16,
                      ),

                      _dropdownField(
                        label:
                            'Billing Month',
                        icon:
                            Icons.calendar_month_rounded,
                        value:
                            selectedMonth,
                        items: const [
                          'September 2026',
                          'October 2026',
                          'November 2026',
                          'December 2026',
                          'January 2027',
                          'February 2027',
                          'March 2027',
                          'April 2027',
                          'May 2027',
                          'June 2027',
                          'July 2027',
                          'August 2027',
                        ],
                        onChanged:
                            (value) {
                          if (value ==
                              null) {
                            return;
                          }

                          setState(() {
                            selectedMonth =
                                value;
                          });
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      InkWell(
                        onTap:
                            _selectDueDate,
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                        child:
                            InputDecorator(
                          decoration:
                              _inputDecoration(
                            label:
                                'Due Date',
                            icon:
                                Icons.event_rounded,
                          ),
                          child: Text(
                            _formatDate(
                              dueDate,
                            ),
                            style:
                                TextStyle(
                              fontSize: 14,
                              color: dueDate ==
                                      null
                                  ? const Color(
                                      0xFF94A3B8,
                                    )
                                  : const Color(
                                      0xFF111827,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                // ==================================================
                // CHARGES
                // ==================================================

                const Text(
                  'Charges',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF111827),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                _card(
                  child: Column(
                    children: [
                      _amountField(
                        controller:
                            rentController,
                        label: 'Rent',
                        icon:
                            Icons.home_work_outlined,
                        requiredField:
                            true,
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      _amountField(
                        controller:
                            electricityController,
                        label:
                            'Electricity',
                        icon:
                            Icons.bolt_rounded,
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      _amountField(
                        controller:
                            foodController,
                        label:
                            'Food / Mess',
                        icon:
                            Icons.restaurant_rounded,
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      _amountField(
                        controller:
                            maintenanceController,
                        label:
                            'Maintenance',
                        icon:
                            Icons.build_rounded,
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      _amountField(
                        controller:
                            otherController,
                        label:
                            'Other Charges',
                        icon:
                            Icons.add_card_rounded,
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      _amountField(
                        controller:
                            discountController,
                        label:
                            'Discount',
                        icon:
                            Icons.discount_rounded,
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                // ==================================================
                // TOTAL
                // ==================================================

                _totalCard(),

                const SizedBox(
                  height: 24,
                ),

                // ==================================================
                // NOTES
                // ==================================================

                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF111827),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                _card(
                  child: TextField(
                    controller:
                        notesController,
                    maxLines: 4,
                    decoration:
                        _inputDecoration(
                      label:
                          'Additional Notes',
                      icon:
                          Icons.notes_rounded,
                    ).copyWith(
                      alignLabelWithHint:
                          true,
                      hintText:
                          'Add any notes for this bill...',
                    ),
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                // ==================================================
                // GENERATE BUTTON
                // ==================================================

                SizedBox(
                  width:
                      double.infinity,
                  height: 54,
                  child:
                      FilledButton.icon(
                    onPressed:
                        _isLoadingTenants
                            ? null
                            : _generateBill,
                    icon: const Icon(
                      Icons.receipt_long_rounded,
                    ),
                    label: const Text(
                      'Generate Bill',
                      style:
                          TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                const Center(
                  child: Text(
                    'You can preview, download or share the bill after creating it.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TENANT DROPDOWN
  // ============================================================

  Widget _tenantDropdown() {
    if (_isLoadingTenants) {
      return InputDecorator(
        decoration: _inputDecoration(
          label: 'Tenant',
          icon:
              Icons.person_outline_rounded,
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(
              width: 12,
            ),
            Text(
              'Loading tenants...',
              style: TextStyle(
                fontSize: 14,
                color:
                    Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    if (_tenants.isEmpty) {
      return InputDecorator(
        decoration: _inputDecoration(
          label: 'Tenant',
          icon:
              Icons.person_outline_rounded,
        ),
        child: Text(
          widget.buildingId != null &&
                  widget.buildingId!
                      .trim()
                      .isNotEmpty
              ? 'No active tenants found in this PG'
              : 'No active tenants found',
          style: const TextStyle(
            fontSize: 14,
            color:
                Color(0xFF94A3B8),
          ),
        ),
      );
    }

    // ==========================================================
    // CREATE UNIQUE DROPDOWN ITEMS
    // ==========================================================

    final dropdownItems =
        _tenants
            .asMap()
            .entries
            .map((entry) {
      final index = entry.key;
      final tenant = entry.value;

      final dropdownValue =
          _dropdownValueForTenant(
        tenant,
        index,
      );

      final shortId =
          _shortTenantId(
        tenant.id,
      );

      return DropdownMenuItem<String>(
        value: dropdownValue,

        child: Row(
          children: [
            Expanded(
              child: Text(
                tenant.fullName,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFFEFF6FF),
                borderRadius:
                    BorderRadius.circular(
                  8,
                ),
              ),
              child: Text(
                shortId,
                style:
                    const TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();

    final availableValues =
        dropdownItems
            .map(
              (item) => item.value,
            )
            .whereType<String>()
            .toSet();

    final safeDropdownValue =
        availableValues.contains(
      _selectedTenantDropdownValue,
    )
            ? _selectedTenantDropdownValue
            : null;

    return DropdownButtonFormField<String>(
      initialValue:
          safeDropdownValue,

      decoration:
          _inputDecoration(
        label: 'Tenant',
        icon:
            Icons.person_outline_rounded,
      ),

      isExpanded: true,

      items: dropdownItems,

      onChanged: (dropdownValue) {
        if (dropdownValue ==
            null) {
          return;
        }

        final selectedIndex =
            dropdownItems.indexWhere(
          (item) =>
              item.value ==
              dropdownValue,
        );

        if (selectedIndex < 0 ||
            selectedIndex >=
                _tenants.length) {
          return;
        }

        final tenant =
            _tenants[selectedIndex];

        setState(() {
          selectedTenantId =
              tenant.id;

          _selectedTenantDropdownValue =
              dropdownValue;

          // ====================================================
          // AUTO FILL MONTHLY RENT
          // ====================================================

          rentController.text =
              tenant.monthlyRent
                  .toStringAsFixed(
            2,
          );
        });
      },

      validator: (value) {
        if (value == null ||
            value.isEmpty) {
          return 'Please select a tenant';
        }

        return null;
      },
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _card({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),
      child: child,
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?>
        onChanged,
  }) {
    final uniqueItems =
        <String>[];

    for (final item in items) {
      if (!uniqueItems
          .contains(item)) {
        uniqueItems.add(item);
      }
    }

    final safeValue =
        uniqueItems.contains(value)
            ? value
            : null;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,

      decoration:
          _inputDecoration(
        label: label,
        icon: icon,
      ),

      isExpanded: true,

      items:
          uniqueItems.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style:
                const TextStyle(
              fontSize: 14,
            ),
          ),
        );
      }).toList(),

      onChanged: onChanged,
    );
  }

  // ============================================================
  // AMOUNT FIELD
  // ============================================================

  Widget _amountField({
    required TextEditingController
        controller,
    required String label,
    required IconData icon,
    bool requiredField = false,
  }) {
    return TextFormField(
      controller: controller,

      keyboardType:
          const TextInputType
              .numberWithOptions(
        decimal: true,
      ),

      validator: requiredField
          ? (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Please enter $label';
              }

              final amount =
                  double.tryParse(
                value.trim(),
              );

              if (amount == null ||
                  amount < 0) {
                return 'Enter a valid amount';
              }

              return null;
            }
          : (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return null;
              }

              final amount =
                  double.tryParse(
                value.trim(),
              );

              if (amount == null ||
                  amount < 0) {
                return 'Enter a valid amount';
              }

              return null;
            },

      decoration:
          _inputDecoration(
        label: label,
        icon: icon,
        prefixText: '₹ ',
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      prefixText: prefixText,
      prefixIcon: Icon(icon),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            const BorderSide(
          color:
              Color(0xFFE5E7EB),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            const BorderSide(
          color:
              Color(0xFF2563EB),
          width: 1.5,
        ),
      ),

      filled: true,

      fillColor:
          const Color(0xFFFAFBFD),
    );
  }

  // ============================================================
  // TOTAL CARD
  // ============================================================

  Widget _totalCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Bill Summary',
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w600,
              color:
                  Colors.white70,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            '₹${_total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 30,
              fontWeight:
                  FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  'Subtotal',
                  '₹${_subtotal.toStringAsFixed(2)}',
                ),
              ),

              Container(
                width: 1,
                height: 35,
                color:
                    Colors.white24,
              ),

              Expanded(
                child: _summaryItem(
                  'Discount',
                  '₹${_discount.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY ITEM
  // ============================================================

  Widget _summaryItem(
    String title,
    String value,
  ) {
    return Column(
      children: [
        Text(
          title,
          style:
              const TextStyle(
            fontSize: 11,
            color:
                Colors.white70,
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          value,
          style:
              const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
            color:
                Colors.white,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    rentController.dispose();
    electricityController.dispose();
    foodController.dispose();
    maintenanceController.dispose();
    otherController.dispose();
    discountController.dispose();
    notesController.dispose();

    super.dispose();
  }
}