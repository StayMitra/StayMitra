import 'package:flutter/material.dart';

enum ReportType {
  day,
  dateRange,
  week,
  weekRange,
  month,
  monthRange,
  year,
  yearRange,
}

class DaySheetScreen extends StatefulWidget {
  const DaySheetScreen({super.key});

  @override
  State<DaySheetScreen> createState() => _DaySheetScreenState();
}

class _DaySheetScreenState extends State<DaySheetScreen> {
  // ------------------------------------------------------------
  // REPORT SELECTION
  // ------------------------------------------------------------

  ReportType reportType = ReportType.day;

  DateTime selectedDate = DateTime.now();

  DateTime rangeStart = DateTime.now();
  DateTime rangeEnd = DateTime.now();

  DateTime selectedMonth = DateTime.now();

  int selectedYear = DateTime.now().year;

  int rangeStartYear = DateTime.now().year;
  int rangeEndYear = DateTime.now().year;

  int selectedWeekOffset = 0;

  // ------------------------------------------------------------
  // SAMPLE DATA
  // ------------------------------------------------------------

  double openingBalance = 5000;

  double cashCollection = 14850;
  double upiCollection = 6250;
  double bankCollection = 4200;

  double totalExpense = 3500;

  // ------------------------------------------------------------
  // CALCULATIONS
  // ------------------------------------------------------------

  double get totalCollection =>
      cashCollection + upiCollection + bankCollection;

  double get closingBalance =>
      openingBalance + totalCollection - totalExpense;

  double get closingCash =>
      openingBalance + cashCollection - totalExpense;

  // ------------------------------------------------------------
  // DATE / PERIOD PICKERS
  // ------------------------------------------------------------

  // ------------------------------------------------------------
  // DAY
  // ------------------------------------------------------------

  Future<void> _selectSingleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select Day',
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        reportType = ReportType.day;
      });
    }
  }

  // ------------------------------------------------------------
  // DATE RANGE
  // ------------------------------------------------------------

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: rangeStart,
        end: rangeEnd,
      ),
      helpText: 'Select Date Range',
    );

    if (picked != null) {
      setState(() {
        rangeStart = picked.start;
        rangeEnd = picked.end;
        reportType = ReportType.dateRange;
      });
    }
  }

  // ------------------------------------------------------------
  // WEEK
  // ------------------------------------------------------------

  Future<void> _selectWeek() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select a date in the week',
    );

    if (picked != null) {
      final start = _startOfWeek(picked);
      final end = start.add(
        const Duration(days: 6),
      );

      setState(() {
        selectedDate = picked;
        rangeStart = start;
        rangeEnd = end;

        selectedWeekOffset =
            start
                    .difference(
                      _startOfWeek(DateTime.now()),
                    )
                    .inDays ~/
                7;

        reportType = ReportType.week;
      });
    }
  }

  // ------------------------------------------------------------
  // WEEK RANGE
  // ------------------------------------------------------------

  Future<void> _selectWeekRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: _startOfWeek(rangeStart),
        end: _startOfWeek(rangeEnd),
      ),
      helpText: 'Select Week Range',
    );

    if (picked != null) {
      final start = _startOfWeek(picked.start);

      final end = _startOfWeek(picked.end).add(
        const Duration(days: 6),
      );

      setState(() {
        rangeStart = start;
        rangeEnd = end;
        reportType = ReportType.weekRange;
      });
    }
  }

  // ------------------------------------------------------------
  // MONTH
  // ------------------------------------------------------------

  Future<void> _selectMonth() async {
    DateTime tempMonth = selectedMonth;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Month'),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${tempMonth.year}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButton<int>(
                    value: tempMonth.month,
                    isExpanded: true,

                    items: List.generate(
                      12,
                      (index) {
                        return DropdownMenuItem<int>(
                          value: index + 1,
                          child: Text(
                            _monthName(index + 1),
                          ),
                        );
                      },
                    ),

                    onChanged: (month) {
                      if (month != null) {
                        setDialogState(() {
                          tempMonth = DateTime(
                            tempMonth.year,
                            month,
                          );
                        });
                      }
                    },
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      tempMonth,
                    );
                  },
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedMonth = picked;
        reportType = ReportType.month;
      });
    }
  }

  // ------------------------------------------------------------
  // MONTH RANGE
  // ------------------------------------------------------------

  Future<void> _selectMonthRange() async {
    int startMonth = rangeStart.month;
    int startYear = rangeStart.year;

    int endMonth = rangeEnd.month;
    int endYear = rangeEnd.year;

    final result =
        await showDialog<Map<String, int>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Month Range'),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'From',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<int>(
                            value: startMonth,
                            isExpanded: true,
                            items: List.generate(
                              12,
                              (index) {
                                return DropdownMenuItem<int>(
                                  value: index + 1,
                                  child: Text(
                                    _monthName(index + 1),
                                  ),
                                );
                              },
                            ),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  startMonth = value;
                                });
                              }
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: DropdownButton<int>(
                            value: startYear,
                            isExpanded: true,
                            items: List.generate(
                              21,
                              (index) {
                                final year =
                                    DateTime.now().year -
                                        10 +
                                        index;

                                return DropdownMenuItem<int>(
                                  value: year,
                                  child: Text('$year'),
                                );
                              },
                            ),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  startYear = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'To',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<int>(
                            value: endMonth,
                            isExpanded: true,
                            items: List.generate(
                              12,
                              (index) {
                                return DropdownMenuItem<int>(
                                  value: index + 1,
                                  child: Text(
                                    _monthName(index + 1),
                                  ),
                                );
                              },
                            ),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  endMonth = value;
                                });
                              }
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: DropdownButton<int>(
                            value: endYear,
                            isExpanded: true,
                            items: List.generate(
                              21,
                              (index) {
                                final year =
                                    DateTime.now().year -
                                        10 +
                                        index;

                                return DropdownMenuItem<int>(
                                  value: year,
                                  child: Text('$year'),
                                );
                              },
                            ),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  endYear = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () {
                    final start = DateTime(
                      startYear,
                      startMonth,
                    );

                    final end = DateTime(
                      endYear,
                      endMonth,
                    );

                    if (end.isBefore(start)) {
                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'End month must be after start month',
                          ),
                        ),
                      );

                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      {
                        'startMonth': startMonth,
                        'startYear': startYear,
                        'endMonth': endMonth,
                        'endYear': endYear,
                      },
                    );
                  },
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        rangeStart = DateTime(
          result['startYear']!,
          result['startMonth']!,
        );

        rangeEnd = DateTime(
          result['endYear']!,
          result['endMonth']!,
        );

        reportType = ReportType.monthRange;
      });
    }
  }

  // ------------------------------------------------------------
  // YEAR
  // ------------------------------------------------------------

  Future<void> _selectYear() async {
    int tempYear = selectedYear;

    final picked = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Year'),

              content: DropdownButton<int>(
                value: tempYear,
                isExpanded: true,

                items: List.generate(
                  21,
                  (index) {
                    final year =
                        DateTime.now().year - 10 + index;

                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text('$year'),
                    );
                  },
                ),

                onChanged: (year) {
                  if (year != null) {
                    setDialogState(() {
                      tempYear = year;
                    });
                  }
                },
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      tempYear,
                    );
                  },
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedYear = picked;
        reportType = ReportType.year;
      });
    }
  }

  // ------------------------------------------------------------
  // YEAR RANGE
  // ------------------------------------------------------------

  Future<void> _selectYearRange() async {
    int startYear = rangeStartYear;
    int endYear = rangeEndYear;

    final result =
        await showDialog<Map<String, int>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Year Range'),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: startYear,
                    decoration: const InputDecoration(
                      labelText: 'From Year',
                      border: OutlineInputBorder(),
                    ),

                    items: List.generate(
                      21,
                      (index) {
                        final year =
                            DateTime.now().year -
                                10 +
                                index;

                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text('$year'),
                        );
                      },
                    ),

                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          startYear = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    value: endYear,
                    decoration: const InputDecoration(
                      labelText: 'To Year',
                      border: OutlineInputBorder(),
                    ),

                    items: List.generate(
                      21,
                      (index) {
                        final year =
                            DateTime.now().year -
                                10 +
                                index;

                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text('$year'),
                        );
                      },
                    ),

                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          endYear = value;
                        });
                      }
                    },
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () {
                    if (endYear < startYear) {
                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'End year must be greater than or equal to start year',
                          ),
                        ),
                      );

                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      {
                        'startYear': startYear,
                        'endYear': endYear,
                      },
                    );
                  },
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        rangeStartYear = result['startYear']!;
        rangeEndYear = result['endYear']!;
        reportType = ReportType.yearRange;
      });
    }
  }


  // ------------------------------------------------------------
  // REPORT TYPE SELECTOR
  // ------------------------------------------------------------
Widget _periodOption(
  BuildContext context,
  ReportType type,
  String title,
  String subtitle,
  IconData icon,
) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 4,
      vertical: 1,
    ),
    leading: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF2563EB),
      ),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF6B7280),
      ),
    ),
    trailing: reportType == type
        ? const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF2563EB),
          )
        : const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF9CA3AF),
          ),
    onTap: () {
      Navigator.pop(context, type);
    },
  );
}
Future<void> _showReportTypeSelector() async {
  final selected = await showModalBottomSheet<ReportType>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (context) {
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Report Period',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 18),

                _periodOption(
                  context,
                  ReportType.day,
                  'Day',
                  'View a single day',
                  Icons.today_rounded,
                ),

                _periodOption(
                  context,
                  ReportType.dateRange,
                  'Date Range',
                  'Select any start and end date',
                  Icons.date_range_rounded,
                ),

                _periodOption(
                  context,
                  ReportType.week,
                  'Week',
                  'View one week',
                  Icons.view_week_rounded,
                ),

                _periodOption(
                  context,
                  ReportType.weekRange,
                  'Week Range',
                  'View multiple weeks',
                  Icons.date_range_rounded,
                ),

                _periodOption(
                  context,
                  ReportType.month,
                  'Month',
                  'View one month',
                  Icons.calendar_month_rounded,
                ),

                _periodOption(
                  context,
                  ReportType.monthRange,
                  'Month Range',
                  'View multiple months',
                  Icons.date_range_rounded,
                ),

                _periodOption(
                  context,
                  ReportType.year,
                  'Year',
                  'View one year',
                  Icons.calendar_today_rounded,
                ),

                _periodOption(
                  context,
                  ReportType.yearRange,
                  'Year Range',
                  'View multiple years',
                  Icons.date_range_rounded,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  if (selected == null) return;

  setState(() {
    reportType = selected;
  });

  // ------------------------------------------------------------
  // SELECT REQUIRED DATE / RANGE
  // ------------------------------------------------------------

  if (selected == ReportType.day) {
    await _selectSingleDate();
  }

  if (selected == ReportType.dateRange) {
    await _selectDateRange();
  }

  if (selected == ReportType.week) {
    await _selectWeek();
  }

  if (selected == ReportType.weekRange) {
    await _selectWeekRange();
  }

  if (selected == ReportType.month) {
    await _selectMonth();
  }

  if (selected == ReportType.monthRange) {
    await _selectMonthRange();
  }

  if (selected == ReportType.year) {
    await _selectYear();
  }

  if (selected == ReportType.yearRange) {
    await _selectYearRange();
  }
}

  // ------------------------------------------------------------
  // DISPLAY LABEL
  // ------------------------------------------------------------

  String get reportTitle {
    switch (reportType) {
      case ReportType.day:
        return 'Day Sheet';

      case ReportType.dateRange:
        return 'Date Range';

      case ReportType.week:
        return 'Weekly Sheet';

      case ReportType.weekRange:
        return 'Weekly Range';

      case ReportType.month:
        return 'Monthly Sheet';

      case ReportType.monthRange:
        return 'Monthly Range';

      case ReportType.year:
        return 'Yearly Sheet';

      case ReportType.yearRange:
        return 'Yearly Range';
    }
  }

  String get reportDateText {
    switch (reportType) {
      case ReportType.day:
        return _formatDate(selectedDate);

      case ReportType.dateRange:
        return '${_formatShortDate(rangeStart)} - '
            '${_formatShortDate(rangeEnd)}';

      case ReportType.week:
        final start = _startOfWeek(
          DateTime.now().add(
            Duration(days: selectedWeekOffset * 7),
          ),
        );

        final end = start.add(const Duration(days: 6));

        return '${_formatShortDate(start)} - '
            '${_formatShortDate(end)}';

case ReportType.weekRange:
  return '${_formatShortDate(rangeStart)} - '
      '${_formatShortDate(rangeEnd)}';

      case ReportType.month:
        return '${_monthName(selectedMonth.month)} '
            '${selectedMonth.year}';

case ReportType.monthRange:
  return '${_monthName(rangeStart.month)} '
      '${rangeStart.year} - '
      '${_monthName(rangeEnd.month)} '
      '${rangeEnd.year}';

      case ReportType.year:
        return '$selectedYear';

      case ReportType.yearRange:
        return '$rangeStartYear - $rangeEndYear';
    }
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),

        title: Text(
          reportTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _showReportTypeSelector,
            icon: const Icon(
              Icons.calendar_month_rounded,
            ),
            tooltip: 'Report Period',
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert_rounded,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dateCard(),

              const SizedBox(height: 20),

              const Text(
                'Day Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              _summaryGrid(),

              const SizedBox(height: 22),

              const Text(
                'Collections',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              _collectionCard(),

              const SizedBox(height: 22),

              const Text(
                'Expenses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              _expenseCard(),

              const SizedBox(height: 22),

              const Text(
                'Cash Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 12),

              _cashSummaryCard(),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.save_rounded,
                      ),
                      label: const Text(
                        'Save Day Sheet',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.share_rounded,
                      ),
                      label: const Text(
                        'Share',
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(52),
                        backgroundColor:
                            const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
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

  // ============================================================
  // DATE / PERIOD CARD
  // ============================================================

  Widget _dateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFF2563EB),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Period',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      reportDateText,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),

              TextButton(
                onPressed: _showReportTypeSelector,
                child: const Text(
                  'Change',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  size: 18,
                  color: Color(0xFF64748B),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    _periodDescription(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _periodDescription() {
    switch (reportType) {
      case ReportType.day:
        return 'Showing transactions for one day';

      case ReportType.dateRange:
        return 'Showing transactions between selected dates';

      case ReportType.week:
        return 'Showing transactions for one week';

      case ReportType.weekRange:
        return 'Showing transactions for multiple weeks';

      case ReportType.month:
        return 'Showing transactions for selected month';

      case ReportType.monthRange:
        return 'Showing transactions for multiple months';

      case ReportType.year:
        return 'Showing transactions for selected year';

      case ReportType.yearRange:
        return 'Showing transactions for multiple years';
    }
  }

  // ============================================================
  // SUMMARY GRID
  // ============================================================

  Widget _summaryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _summaryCard(
          'Total Collection',
          '₹ ${_money(totalCollection)}',
          Icons.trending_up_rounded,
          const Color(0xFF16A34A),
        ),

        _summaryCard(
          'Total Expense',
          '₹ ${_money(totalExpense)}',
          Icons.trending_down_rounded,
          const Color(0xFFDC2626),
        ),

        _summaryCard(
          'Opening Balance',
          '₹ ${_money(openingBalance)}',
          Icons.account_balance_wallet_rounded,
          const Color(0xFF2563EB),
        ),

        _summaryCard(
          'Closing Balance',
          '₹ ${_money(closingBalance)}',
          Icons.account_balance_rounded,
          const Color(0xFF7C3AED),
        ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 25,
          ),

          const Spacer(),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 3),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COLLECTION CARD
  // ============================================================

  Widget _collectionCard() {
    return _whiteCard(
      child: Column(
        children: [
          _moneyRow(
            'Cash Collection',
            cashCollection,
            Icons.payments_rounded,
            const Color(0xFF16A34A),
          ),

          const Divider(height: 24),

          _moneyRow(
            'UPI Collection',
            upiCollection,
            Icons.qr_code_rounded,
            const Color(0xFF7C3AED),
          ),

          const Divider(height: 24),

          _moneyRow(
            'Bank Collection',
            bankCollection,
            Icons.account_balance_rounded,
            const Color(0xFF2563EB),
          ),

          const Divider(height: 24),

          _moneyRow(
            'Total Collection',
            totalCollection,
            Icons.summarize_rounded,
            const Color(0xFF111827),
            bold: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXPENSE CARD
  // ============================================================

  Widget _expenseCard() {
    return _whiteCard(
      child: Column(
        children: [
          _moneyRow(
            'Total Expenses',
            totalExpense,
            Icons.receipt_long_rounded,
            const Color(0xFFDC2626),
            bold: true,
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Color(0xFFDC2626),
                ),

                SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Expenses recorded for this period will appear here.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CASH SUMMARY
  // ============================================================

  Widget _cashSummaryCard() {
    return _whiteCard(
      child: Column(
        children: [
          _moneyRow(
            'Opening Cash',
            openingBalance,
            Icons.login_rounded,
            const Color(0xFF2563EB),
          ),

          const Divider(height: 24),

          _moneyRow(
            'Cash Received',
            cashCollection,
            Icons.add_circle_outline_rounded,
            const Color(0xFF16A34A),
          ),

          const Divider(height: 24),

          _moneyRow(
            'Cash Expenses',
            totalExpense,
            Icons.remove_circle_outline_rounded,
            const Color(0xFFDC2626),
          ),

          const Divider(height: 24),

          _moneyRow(
            'Expected Closing Cash',
            closingCash,
            Icons.lock_clock_rounded,
            const Color(0xFF7C3AED),
            bold: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMMON WHITE CARD
  // ============================================================

  Widget _whiteCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: child,
    );
  }

  // ============================================================
  // MONEY ROW
  // ============================================================

  Widget _moneyRow(
    String title,
    double amount,
    IconData icon,
    Color color, {
    bool bold = false,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius:
                BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  bold ? FontWeight.w600 : FontWeight.normal,
              color: const Color(0xFF374151),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              '₹ ${_money(amount)}',
              style: TextStyle(
                fontSize: bold ? 16 : 14,
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day} ${_monthName(date.month)}';
  }

  String _monthName(int month) {
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

    return months[month - 1];
  }

  DateTime _startOfWeek(DateTime date) {
    final difference =
        date.weekday - DateTime.monday;

    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(
      Duration(days: difference),
    );
  }

  String _money(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }
}