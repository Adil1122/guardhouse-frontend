import 'package:flutter/foundation.dart';
import '../models/invoice_model.dart';
import '../models/timesheet_model.dart';
import '../services/admin_api_service.dart';

class InvoiceViewModel extends ChangeNotifier {
  final AdminApiService _apiService;
  
  List<Invoice> _invoices = [];
  bool _isLoading = false;
  String? _error;

  InvoiceViewModel(this._apiService) {
    loadInvoices();
  }

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get draftCount =>
      _invoices.where((i) => i.status == InvoiceStatus.draft).length;
  int get sentCount =>
      _invoices.where((i) => i.status == InvoiceStatus.sent).length;
  int get paidCount =>
      _invoices.where((i) => i.status == InvoiceStatus.paid).length;
  int get overdueCount =>
      _invoices.where((i) => i.status == InvoiceStatus.overdue).length;

  Future<void> loadInvoices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getInvoices();
      _invoices = [];
      for (final json in data) {
        try {
          _invoices.add(Invoice.fromJson(json));
        } catch (e) {
          debugPrint('Error parsing invoice: $e');
          debugPrint('Invoice JSON: $json');
        }
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _invoices = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createInvoice(Map<String, dynamic> invoiceData) async {
    try {
      await _apiService.createInvoice(invoiceData);
      await loadInvoices();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> updateInvoice(String id, Map<String, dynamic> invoiceData) async {
    try {
      await _apiService.updateInvoice(id, invoiceData);
      await loadInvoices();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> completeInvoice(String id) async {
    try {
      await _apiService.completeInvoice(id);
      await loadInvoices();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> deleteInvoice(String id) async {
    try {
      await _apiService.deleteInvoice(id);
      _invoices.removeWhere((invoice) => invoice.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveInvoice(String id) async {
    try {
      await _apiService.completeInvoice(id);
      await loadInvoices();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> sendInvoice(String id) async {
    try {
      await _apiService.updateInvoice(id, {'status': 'sent'});
      await loadInvoices();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  double calculateTimesheetTotal(List<Timesheet> timesheets) {
    double total = 0;
    for (var timesheet in timesheets) {
      if (timesheet.clockInTime != null && timesheet.clockOutTime != null) {
        final duration = timesheet.clockOutTime!.difference(
          timesheet.clockInTime!,
        );
        final hours = (duration.inMinutes - timesheet.breakMinutes) / 60;
        total += hours * 25.0;
      }
    }
    return total;
  }

  double calculateManualItemsTotal(List<ManualBillableItem> items) {
    return items.fold(0, (sum, item) => sum + item.totalAmount);
  }
}
