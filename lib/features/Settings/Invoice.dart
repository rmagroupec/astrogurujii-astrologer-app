// ============================================================
// lib/features/Settings/Invoice.dart
// ============================================================
// Add to pubspec.yaml dependencies:
//   open_file: ^3.3.2
//   path_provider: ^2.1.5   (already a transitive dep — just make it direct)
// Then run: flutter pub get
// ============================================================

import 'dart:io';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class InvoiceItem {
  final int month;
  final int year;
  final String monthName;
  final String invoiceNumber;
  final String period;
  final double subtotal;
  final double platformCommission;
  final double tdsAmount;
  final double netAmount;
  final int totalServices;
  final String status; // "Generated" | "No Activity"

  const InvoiceItem({
    required this.month,
    required this.year,
    required this.monthName,
    required this.invoiceNumber,
    required this.period,
    required this.subtotal,
    required this.platformCommission,
    required this.tdsAmount,
    required this.netAmount,
    required this.totalServices,
    required this.status,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> j) => InvoiceItem(
        month: j['month'] ?? 0,
        year: j['year'] ?? 0,
        monthName: j['month_name'] ?? '',
        invoiceNumber: j['invoice_number'] ?? '',
        period: j['period'] ?? '',
        subtotal: _toDouble(j['subtotal']),
        platformCommission: _toDouble(j['platform_commission']),
        tdsAmount: _toDouble(j['tds_amount']),
        netAmount: _toDouble(j['net_amount']),
        totalServices: j['total_services'] ?? 0,
        status: j['status'] ?? 'No Activity',
      );

  static double _toDouble(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
}

// ── Service ──────────────────────────────────────────────────────────────────

class InvoiceService {
  static const String _baseUrl = 'https://admin.astrogurujii.com/';
  final _storage = const FlutterSecureStorage();

  Future<String?> _token() => _storage.read(key: 'auth_token');

  Future<Map<String, String>> _headers() async {
    final token = await _token();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetches the invoice list for [year].
  Future<List<InvoiceItem>> fetchInvoiceList({int? year}) async {
    final headers = await _headers();
    final body = jsonEncode({'year': year ?? DateTime.now().year});

    final response = await http
        .post(
          Uri.parse('${_baseUrl}astrologer_api/invoice_list'),
          headers: headers,
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['result'] == true) {
        final List raw = json['data'] ?? [];
        return raw.map((e) => InvoiceItem.fromJson(e)).toList();
      }
      throw Exception(json['message'] ?? 'Failed to load invoices');
    }
    throw Exception('Server error ${response.statusCode}');
  }

  /// Downloads the PDF for [month]/[year] and returns the saved [File].
  Future<File> downloadInvoicePdf({
    required int month,
    required int year,
    required String monthName,
  }) async {
    final headers = await _headers();
    final body = jsonEncode({'month': month, 'year': year});

    final response = await http
        .post(
          Uri.parse('${_baseUrl}astrologer_api/invoice_download'),
          headers: headers,
          body: body,
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200 &&
        (response.headers['content-type'] ?? '').contains('pdf')) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/Invoice_${monthName}_$year.pdf'.replaceAll(' ', '_'));
      await file.writeAsBytes(response.bodyBytes);
      return file;
    }
    // Try to parse an error body
    try {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Download failed');
    } catch (_) {
      throw Exception('Download failed (${response.statusCode})');
    }
  }
}

// ── Screen ───────────────────────────────────────────────────────────────────

class Invoice extends StatefulWidget {
  const Invoice({super.key});

  @override
  State<Invoice> createState() => _InvoiceState();
}

class _InvoiceState extends State<Invoice> {
  final _service = InvoiceService();

  int _selectedYear = DateTime.now().year;
  List<InvoiceItem> _invoices = [];
  bool _loading = true;
  String? _error;

  // Which month card is expanded (null = none)
  int? _expandedMonth;

  // Per-item download state
  final Map<int, bool> _downloading = {};

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
      final list = await _service.fetchInvoiceList(year: _selectedYear);
      if (mounted) {
        setState(() {
          _invoices = list;
          // Auto-expand the first item (most recent month)
          _expandedMonth = list.isNotEmpty ? list.first.month : null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _downloadPdf(InvoiceItem item) async {
    setState(() => _downloading[item.month] = true);
    try {
      final file = await _service.downloadInvoicePdf(
        month: item.month,
        year: item.year,
        monthName: item.monthName,
      );
      if (mounted) {
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done && mounted) {
          _showSnack('Saved to ${file.path}', isError: false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _downloading.remove(item.month));
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Invoice'),
        backgroundColor: const Color(0xFFFCD417).withOpacity(0.25),
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Year picker
          _YearSelector(
            year: _selectedYear,
            onChanged: (y) {
              setState(() => _selectedYear = y);
              _load();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF5A623)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(FigmaSize.w(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: FigmaSize.h(12)),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              SizedBox(height: FigmaSize.h(16)),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey),
            SizedBox(height: FigmaSize.h(12)),
            Text(
              'No invoices for $_selectedYear',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFFF5A623),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          vertical: FigmaSize.h(20),
          horizontal: FigmaSize.w(20),
        ),
        itemCount: _invoices.length,
        separatorBuilder: (_, __) => SizedBox(height: FigmaSize.h(4)),
        itemBuilder: (_, i) => _InvoiceCard(
          item: _invoices[i],
          isExpanded: _expandedMonth == _invoices[i].month,
          isDownloading: _downloading[_invoices[i].month] ?? false,
          onToggle: () => setState(() {
            _expandedMonth =
                _expandedMonth == _invoices[i].month ? null : _invoices[i].month;
          }),
          onDownload: () => _downloadPdf(_invoices[i]),
        ),
      ),
    );
  }
}

// ── Invoice Card ─────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final InvoiceItem item;
  final bool isExpanded;
  final bool isDownloading;
  final VoidCallback onToggle;
  final VoidCallback onDownload;

  const _InvoiceCard({
    required this.item,
    required this.isExpanded,
    required this.isDownloading,
    required this.onToggle,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final hasActivity = item.status == 'Generated';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isExpanded
              ? const Color(0xFFF5A623).withOpacity(0.6)
              : const Color(0xFFE7E7E7),
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: const Color(0xFFF5A623).withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
      ),
      child: Column(
        children: [
          // ── Header row ───────────────────────────────────────────────────
          InkWell(
            onTap: hasActivity ? onToggle : null,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: FigmaSize.w(16),
                vertical: FigmaSize.h(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.monthName} ${item.year}',
                          style: TextStyle(
                            fontSize: FigmaSize.w(15),
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: FigmaSize.h(3)),
                        Text(
                          hasActivity
                              ? '${item.totalServices} sessions'
                              : 'No activity',
                          style: TextStyle(
                            fontSize: FigmaSize.w(11),
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Net amount badge
                  if (hasActivity) ...[
                    Text(
                      '₹ ${item.netAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: FigmaSize.w(14),
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: FigmaSize.w(8)),
                  ],
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: hasActivity ? Colors.black87 : Colors.grey.shade300,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded content ─────────────────────────────────────────────
          if (isExpanded && hasActivity) ...[
            Divider(
                height: 1,
                color: const Color(0xFFF5A623).withOpacity(0.3),
                indent: FigmaSize.w(16),
                endIndent: FigmaSize.w(16)),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: FigmaSize.w(16),
                vertical: FigmaSize.h(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status stepper
                  _InvoiceStatusBar(status: item.status),
                  SizedBox(height: FigmaSize.h(16)),

                  // Invoice number
                  _DetailRow(
                    label: 'Invoice No.',
                    value: item.invoiceNumber,
                    valueStyle: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontFamily: 'monospace'),
                  ),
                  SizedBox(height: FigmaSize.h(6)),
                  _DetailRow(label: 'Period', value: item.period),
                  SizedBox(height: FigmaSize.h(12)),

                  // Amounts breakdown
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE7E7E7)),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: FigmaSize.w(12),
                      vertical: FigmaSize.h(10),
                    ),
                    child: Column(
                      children: [
                        _AmountRow(
                          label: 'Gross Earnings',
                          value: '₹ ${item.subtotal.toStringAsFixed(2)}',
                          valueColor: Colors.black87,
                        ),
                        SizedBox(height: FigmaSize.h(6)),
                        _AmountRow(
                          label: 'Platform Commission',
                          value: '- ₹ ${item.platformCommission.toStringAsFixed(2)}',
                          valueColor: Colors.red,
                        ),
                        SizedBox(height: FigmaSize.h(6)),
                        _AmountRow(
                          label: 'TDS (10%)',
                          value: '- ₹ ${item.tdsAmount.toStringAsFixed(2)}',
                          valueColor: Colors.red,
                        ),
                        Divider(
                            height: FigmaSize.h(14),
                            color: const Color(0xFFE0E0E0)),
                        _AmountRow(
                          label: 'Net Payable',
                          value: '₹ ${item.netAmount.toStringAsFixed(2)}',
                          valueColor: Colors.green,
                          bold: true,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: FigmaSize.h(12)),

                  // Download button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isDownloading ? null : onDownload,
                      icon: isDownloading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.green,
                              ),
                            )
                          : const Icon(Icons.download, color: Colors.green),
                      label: Text(
                        isDownloading ? 'Downloading...' : 'Download Invoice',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.symmetric(
                            vertical: FigmaSize.h(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Status Stepper ────────────────────────────────────────────────────────────

class _InvoiceStatusBar extends StatelessWidget {
  final String status;
  const _InvoiceStatusBar({required this.status});

  @override
  Widget build(BuildContext context) {
    // "Generated" maps to step 2 (In Processing → Generated)
    // You can extend steps as needed
    final step = status == 'Generated' ? 2 : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _dot(active: step >= 1),
            _line(active: step >= 2),
            _dot(active: step >= 2),
            _line(active: step >= 3),
            _dot(active: step >= 3),
          ],
        ),
        SizedBox(height: FigmaSize.h(6)),
        Row(
          children: [
            Expanded(
              child: Text('Processing',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: FigmaSize.w(11),
                      fontWeight: FontWeight.w500,
                      color: step >= 1 ? Colors.green : Colors.grey)),
            ),
            Expanded(
              child: Text('Generated',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: FigmaSize.w(11),
                      fontWeight: FontWeight.w500,
                      color: step >= 2 ? Colors.green : Colors.grey)),
            ),
            Expanded(
              child: Text('Paid',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: FigmaSize.w(11),
                      fontWeight: FontWeight.w500,
                      color: step >= 3 ? Colors.green : Colors.grey)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dot({required bool active}) => Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? Colors.green : Colors.white,
          border: Border.all(
            color: active ? Colors.green : Colors.grey.shade300,
            width: 2,
          ),
        ),
      );

  Widget _line({required bool active}) => Expanded(
        child: Container(
          height: 3,
          color: active ? Colors.green : Colors.grey.shade300,
        ),
      );
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const _DetailRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: TextStyle(
                  fontSize: FigmaSize.w(11), color: Colors.grey)),
        ),
        Expanded(
          child: Text(value,
              style: valueStyle ??
                  TextStyle(
                      fontSize: FigmaSize.w(11),
                      color: Colors.black87,
                      fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;
  const _AmountRow(
      {required this.label,
      required this.value,
      required this.valueColor,
      this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: FigmaSize.w(12),
                color: Colors.grey.shade700,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: FigmaSize.w(bold ? 13 : 12),
                color: valueColor,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }
}

// ── Year Selector (AppBar action) ─────────────────────────────────────────────

class _YearSelector extends StatelessWidget {
  final int year;
  final ValueChanged<int> onChanged;
  const _YearSelector({required this.year, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final current = DateTime.now().year;
    return PopupMenuButton<int>(
      initialValue: year,
      onSelected: onChanged,
      itemBuilder: (_) => List.generate(
        3,
        (i) => PopupMenuItem(
          value: current - i,
          child: Text('${current - i}',
              style: TextStyle(
                  fontWeight: year == current - i
                      ? FontWeight.bold
                      : FontWeight.normal)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$year',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}