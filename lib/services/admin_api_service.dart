import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AdminApiService extends ApiService {
  AdminApiService(StorageService storageService) : super(storageService);

  // Admin APIs - Staff Management
  Future<List<Map<String, dynamic>>> getStaffMembers() async {
    try {
      final response = await dio.get('staff');
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map) {
        list = data['staff'] ?? data['data'] ?? [];
      } else {
        list = [];
      }
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      throw Exception('Failed to load staff members');
    }
  }

  Future<bool> createStaff(Map<String, dynamic> staffData) async {
    try {
      dynamic data;
      if (staffData['image_bytes'] != null) {
        final Map<String, dynamic> mappedData = Map.from(staffData);
        mappedData['image'] = MultipartFile.fromBytes(
          mappedData['image_bytes'],
          filename: mappedData['image_name'] ?? 'image.jpg',
        );
        mappedData.remove('image_bytes');
        mappedData.remove('image_name');
        data = FormData.fromMap(mappedData);
      } else if (staffData['image'] != null &&
          staffData['image'].toString().isNotEmpty &&
          !staffData['image'].toString().startsWith('http')) {
        final Map<String, dynamic> mappedData = Map.from(staffData);
        final filePath = mappedData['image'].toString();
        final fileName = filePath.split(RegExp(r'[\\/]')).last;
        mappedData['image'] =
            await MultipartFile.fromFile(filePath, filename: fileName);
        data = FormData.fromMap(mappedData);
      } else {
        data = staffData;
      }

      final response = await dio.post('staff', data: data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Failed to create staff member');
    }
  }

  Future<bool> updateStaff(
    String staffId,
    Map<String, dynamic> staffData,
  ) async {
    try {
      dynamic data;
      if (staffData['image_bytes'] != null) {
        final Map<String, dynamic> mappedData = Map.from(staffData);
        mappedData['image'] = MultipartFile.fromBytes(
          mappedData['image_bytes'],
          filename: mappedData['image_name'] ?? 'image.jpg',
        );
        mappedData['_method'] = 'PATCH';
        mappedData.remove('image_bytes');
        mappedData.remove('image_name');
        data = FormData.fromMap(mappedData);
        final response = await dio.post('staff/$staffId', data: data);
        return response.statusCode == 200;
      } else if (staffData['image'] != null &&
          staffData['image'].toString().isNotEmpty &&
          !staffData['image'].toString().startsWith('http')) {
        final Map<String, dynamic> mappedData = Map.from(staffData);
        final filePath = mappedData['image'].toString();
        final fileName = filePath.split(RegExp(r'[\\/]')).last;
        mappedData['image'] =
            await MultipartFile.fromFile(filePath, filename: fileName);
        mappedData['_method'] = 'PATCH';
        data = FormData.fromMap(mappedData);
        final response = await dio.post('staff/$staffId', data: data);
        return response.statusCode == 200;
      } else {
        data = staffData;
        final response = await dio.patch('staff/$staffId', data: data);
        return response.statusCode == 200;
      }
    } catch (e) {
      throw Exception('Failed to update staff member');
    }
  }

  Future<bool> deleteStaff(String staffId) async {
    try {
      final response = await dio.delete('staff/$staffId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete staff member');
    }
  }

  Future<Map<String, dynamic>?> getStaffDetails(String staffId) async {
    try {
      final response = await dio.get('staff/$staffId');
      return response.data is Map
          ? (response.data['data'] ?? response.data)
          : response.data;
    } catch (e) {
      return null;
    }
  }

  Future<String?> createStaffDetails(Map<String, dynamic> staffData) async {
    try {
      dynamic data;
      if (staffData['image_bytes'] != null) {
        final Map<String, dynamic> mappedData = Map.from(staffData);
        mappedData['image'] = MultipartFile.fromBytes(
          mappedData['image_bytes'],
          filename: mappedData['image_name'] ?? 'image.jpg',
        );
        mappedData.remove('image_bytes');
        mappedData.remove('image_name');
        data = FormData.fromMap(mappedData);
      } else if (staffData['image'] != null &&
          staffData['image'].toString().isNotEmpty &&
          !staffData['image'].toString().startsWith('http')) {
        final Map<String, dynamic> mappedData = Map.from(staffData);
        final filePath = mappedData['image'].toString();
        final fileName = filePath.split(RegExp(r'[\\/]')).last;
        mappedData['image'] =
            await MultipartFile.fromFile(filePath, filename: fileName);
        data = FormData.fromMap(mappedData);
      } else {
        data = staffData;
      }

      final response = await dio.post('staff', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['id']?.toString() ??
            response.data['data']?['id']?.toString();
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          final msg = errorData['message'] ?? errorData['error'] ?? 'Unknown error';
          throw Exception(msg);
        }
      }
      throw Exception('Failed to create staff details: $e');
    }
  }

  Future<bool> updateStaffDetails(
    String staffId,
    Map<String, dynamic> staffData,
  ) async {
    try {
      dynamic data;
      if (staffData['image_bytes'] != null) {
        final Map<String, dynamic> mappedData = Map.from(staffData);
        mappedData['image'] = MultipartFile.fromBytes(
          mappedData['image_bytes'],
          filename: mappedData['image_name'] ?? 'image.jpg',
        );
        mappedData['_method'] = 'PATCH';
        mappedData.remove('image_bytes');
        mappedData.remove('image_name');
        data = FormData.fromMap(mappedData);
        final response = await dio.post('staff/$staffId', data: data);
        return response.statusCode == 200;
      } else if (staffData['image'] != null &&
          staffData['image'].toString().isNotEmpty &&
          !staffData['image'].toString().startsWith('http')) {
        final Map<String, dynamic> mappedData = Map.from(staffData);
        final filePath = mappedData['image'].toString();
        final fileName = filePath.split(RegExp(r'[\\/]')).last;
        mappedData['image'] =
            await MultipartFile.fromFile(filePath, filename: fileName);
        mappedData['_method'] = 'PATCH';
        data = FormData.fromMap(mappedData);
        final response = await dio.post('staff/$staffId', data: data);
        return response.statusCode == 200;
      } else {
        data = staffData;
        final response = await dio.patch('staff/$staffId', data: data);
        return response.statusCode == 200;
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          final msg = errorData['message'] ?? errorData['error'] ?? 'Unknown error';
          throw Exception(msg);
        }
      }
      throw Exception('Failed to update staff details: $e');
    }
  }

  Future<bool> submitStaffPrivileges(
    String staffId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.patch(
        'staff/$staffId/privilege',
        data: {'privileges': data},
      );
      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          final msg = errorData['message'] ?? errorData['error'] ?? 'Unknown error';
          throw Exception(msg);
        }
      }
      throw Exception('Failed to save staff privileges: $e');
    }
  }

  Future<bool> submitStaffCompliances(
    String staffId,
    Map<String, dynamic> data,
  ) async {
    try {
      final formData = FormData.fromMap({
        if (data['compliance_record_id'] != null)
          'compliance_record_id': data['compliance_record_id'],
        'compliance_id': data['compliance_id'],
        'start_date': data['start_date'],
        'end_date': data['end_date'],
      });

      final existingFiles = data['existing_files'];
      if (existingFiles is List) {
        for (var fileName in existingFiles) {
          formData.fields
              .add(MapEntry('existing_files[]', fileName.toString()));
        }
      }

      final files = data['files'];
      if (files is List) {
        for (var file in files) {
          if (file is PlatformFile) {
            formData.files.add(MapEntry(
              'files[]',
              MultipartFile.fromBytes(file.bytes!, filename: file.name),
            ));
          } else {
            final filePath = file.toString();
            if (filePath.trim().isEmpty) continue;
            final fileName = filePath.split(RegExp(r'[\\/]')).last;
            formData.files.add(MapEntry(
              'files[]',
              await MultipartFile.fromFile(filePath, filename: fileName),
            ));
          }
        }
      }

      final response = await dio.post(
        'staff/$staffId/compliances',
        data: formData,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          final msg = errorData['message'] ?? errorData['error'] ?? 'Unknown error';
          throw Exception(msg);
        }
      }
      throw Exception('Failed to save staff compliances: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOrganizationCompliances() async {
    try {
      final response = await dio.get('organization/compliances');
      final data = response.data;
      final list = data is List
          ? data
          : (data is Map ? (data['data'] ?? data['compliances'] ?? []) : []);
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      return [];
    }
  }

  Future<bool> submitStaffSalary(
    String staffId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.patch(
        'staff/$staffId/salary',
        data: data,
      );
      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          final msg = errorData['message'] ?? errorData['error'] ?? 'Unknown error';
          throw Exception(msg);
        }
      }
      throw Exception('Failed to save staff salary: $e');
    }
  }

  Future<Map<String, dynamic>?> getStaffPrivileges(String staffId) async {
    try {
      final response = await dio.get('staff/$staffId/privilege');
      return response.data is Map ? response.data : null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getStaffCompliances(String staffId) async {
    try {
      final response = await dio.get('staff/$staffId/compliances');
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        final list = data['data'] ?? data['compliances'] ?? [];
        return List<Map<String, dynamic>>.from(list);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Admin APIs - Customer Management
  Future<List<Map<String, dynamic>>> getCustomers() async {
    try {
      final response = await dio.get('customers');
      // The backend returns the list directly or wrapped in data
      final data = response.data;
      final list = data is List
          ? data
          : (data is Map ? (data['data'] ?? data['customers'] ?? []) : []);
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      throw Exception('Failed to load customers');
    }
  }

  Future<Map<String, dynamic>?> createCustomer(
      Map<String, dynamic> customerData) async {
    try {
      final response = await dio.post('customers', data: customerData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data is Map
            ? (response.data['data'] ?? response.data)
            : response.data;
      }
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Failed to create customer';
      throw Exception(msg);
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<bool> updateCustomer(
    String customerId,
    Map<String, dynamic> customerData,
  ) async {
    try {
      final response = await dio.patch(
        'customers/$customerId',
        data: customerData,
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to update customer');
    }
  }

  Future<bool> deleteCustomer(String customerId) async {
    try {
      final response = await dio.delete('customers/$customerId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete customer');
    }
  }

  Future<Map<String, dynamic>> getLiveOperations() async {
    try {
      final response = await dio.get('live-operations');
      final data = response.data;
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } catch (e) {
      return {};
    }
  }

  // Admin APIs - Shift Management
  Future<List<Map<String, dynamic>>> getShifts() async {
    try {
      final response = await dio.get('shifts');
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map) {
        list = data['shifts'] ?? data['data'] ?? [];
      } else {
        list = [];
      }
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      throw Exception('Failed to load shifts');
    }
  }

  Future<bool> createShift(Map<String, dynamic> shiftData) async {
    try {
      final response = await dio.post('shifts', data: shiftData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          final message = errorData['message'] ?? errorData['error'] ?? 'Unknown error';
          throw Exception(message);
        }
      }
      throw Exception('Failed to create shift');
    }
  }

  Future<bool> updateShift(
    String shiftId,
    Map<String, dynamic> shiftData,
  ) async {
    try {
      final response = await dio.patch('shifts/$shiftId', data: shiftData);
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to update shift');
    }
  }

  Future<bool> deleteShift(String shiftId) async {
    try {
      final response = await dio.delete('shifts/$shiftId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete shift');
    }
  }

  // Admin APIs - Timesheet Management
  Future<List<Map<String, dynamic>>> getTimesheets() async {
    try {
      final response = await dio.get('timesheets');
      final data = response.data;
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        final list = data['data'] ?? data['timesheets'] ?? [];
        return List<Map<String, dynamic>>.from(list is List ? list : []);
      }
      return [];
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to load timesheets');
    }
  }

  Future<bool> createTimesheet(Map<String, dynamic> timesheetData) async {
    try {
      final response = await dio.post('timesheets', data: timesheetData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Failed to create timesheet');
    }
  }

  Future<bool> updateTimesheet(
    String timesheetId,
    Map<String, dynamic> timesheetData,
  ) async {
    try {
      final response = await dio.patch(
        'timesheets/$timesheetId',
        data: timesheetData,
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to update timesheet');
    }
  }

  Future<bool> approveTimesheet(String timesheetId) async {
    try {
      final response = await dio.post('timesheets/$timesheetId/approve');
      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to approve timesheet');
    }
  }

  // Admin APIs - Timesheet Management (by status)
  Future<List<Map<String, dynamic>>> getTimesheetsByStatus(String status) async {
    try {
      final response = await dio.get('timesheets/by-status', queryParameters: {'status': status});
      final data = response.data;
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        final list = data['data'] ?? data['timesheets'] ?? [];
        return List<Map<String, dynamic>>.from(list is List ? list : []);
      }
      return [];
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to load timesheets by status');
    }
  }

  // Admin APIs - Invoice Management
  Future<List<Map<String, dynamic>>> getInvoices() async {
    try {
      final response = await dio.get('invoices');
      final data = response.data;
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        final list = data['data'] ?? data['invoices'] ?? [];
        return List<Map<String, dynamic>>.from(list is List ? list : []);
      }
      return [];
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to load invoices');
    }
  }

  Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> invoiceData) async {
    try {
      final response = await dio.post('invoices', data: invoiceData);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to create invoice');
    }
  }

  Future<Map<String, dynamic>> updateInvoice(
    String invoiceId,
    Map<String, dynamic> invoiceData,
  ) async {
    try {
      final response = await dio.patch(
        'invoices/$invoiceId',
        data: invoiceData,
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to update invoice');
    }
  }

  Future<bool> completeInvoice(String invoiceId) async {
    try {
      final response = await dio.patch('invoices/$invoiceId/complete');
      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to complete invoice');
    }
  }

  // Invoice Items CRUD
  Future<Map<String, dynamic>> addInvoiceItem(
    String invoiceId,
    Map<String, dynamic> itemData,
  ) async {
    try {
      final response = await dio.post('invoices/$invoiceId/items', data: itemData);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to add invoice item');
    }
  }

  Future<Map<String, dynamic>> updateInvoiceItem(
    String invoiceId,
    String itemId,
    Map<String, dynamic> itemData,
  ) async {
    try {
      final response = await dio.patch('invoices/$invoiceId/items/$itemId', data: itemData);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to update invoice item');
    }
  }

  Future<bool> deleteInvoiceItem(String invoiceId, String itemId) async {
    try {
      await dio.delete('invoices/$invoiceId/items/$itemId');
      return true;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to delete invoice item');
    }
  }

  Future<List<Map<String, dynamic>>> getAllCustomerInvoiceProfiles() async {
    try {
      final response = await dio.get('customer-invoice-profiles');
      final data = response.data;
      
      List<dynamic> list = [];
      
      if (data is List) {
        list = data;
      } else if (data is Map) {
        list = data['data'] ?? data['raw_profiles'] ?? data['profiles'] ?? [];
      }
      
      return List<Map<String, dynamic>>.from(list.map((e) => Map<String, dynamic>.from(e)));
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to load customer invoice profiles');
    }
  }

  Future<bool> deleteInvoice(String invoiceId) async {
    try {
      await dio.delete('invoices/$invoiceId');
      return true;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to delete invoice');
    }
  }

  // Admin APIs - Site Management
  Future<List<Map<String, dynamic>>> getSites() async {
    try {
      final response = await dio.get('sites');
      final data = response.data;

      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        final list = data['sites'] ?? data['data'] ?? data['items'] ?? [];
        return List<Map<String, dynamic>>.from(list is List ? list : []);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load sites: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerSites(String customerId) async {
    try {
      final response = await dio.get('customers/$customerId/sites');
      final data = response.data;

      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        final list = data['sites'] ?? data['data'] ?? data['items'] ?? [];
        return List<Map<String, dynamic>>.from(list is List ? list : []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> attachSiteToCustomer(String customerId, String siteId) async {
    try {
      final response = await dio.post(
        'customers/$customerId/sites',
        data: {'site_id': siteId},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> detachSiteFromCustomer(String customerId, String siteId) async {
    try {
      final response = await dio.delete(
        'customers/$customerId/sites/$siteId',
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createSite(Map<String, dynamic> siteData) async {
    try {
      final response = await dio.post('sites', data: siteData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          String errMsg = errorData['message'] ?? '';
          if (errorData['errors'] != null) {
            errMsg += ' ' + errorData['errors'].toString();
          }
          if (errMsg.trim().isNotEmpty) throw Exception(errMsg.trim());
        }
      }
      throw Exception('Failed to create site: $e');
    }
  }

  Future<String?> createSiteAndGetId(Map<String, dynamic> siteData) async {
    try {
      final response = await dio.post('sites', data: siteData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['id']?.toString() ??
            response.data['data']?['id']?.toString();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to create site: $e');
    }
  }

  Future<bool> updateSite(String siteId, Map<String, dynamic> siteData) async {
    try {
      final response = await dio.patch('sites/$siteId', data: siteData);
      return response.statusCode == 200;
    } catch (e) {
      print('=== UPDATE SITE ERROR ===');
      print(e.toString());
      if (e is DioException) {
        print('DioException type: \${e.type}');
        print('DioException message: \${e.message}');
        if (e.response != null) {
          print('Response Status: \${e.response?.statusCode}');
          print('Response Data: \${e.response?.data}');
          final errorData = e.response?.data;
          if (errorData is Map) {
            String errMsg = errorData['message'] ?? '';
            if (errorData['errors'] != null) {
              errMsg += ' ' + errorData['errors'].toString();
            }
            if (errMsg.trim().isNotEmpty) throw Exception(errMsg.trim());
          }
        } else {
          print('No response body received (Connection Error / Timeout)');
        }
      }
      throw Exception('Failed to update site: $e');
    }
  }

  Future<Map<String, dynamic>?> getSiteDetails(String siteId) async {
    try {
      final response = await dio.get('sites/$siteId');
      return response.data is Map
          ? (response.data['data'] ?? response.data)
          : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteSite(String siteId) async {
    try {
      final response = await dio.delete('sites/$siteId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete site: $e');
    }
  }

  // Site Contacts CRUD
  Future<List<Map<String, dynamic>>> getSiteContacts(String siteId) async {
    try {
      final response = await dio.get('sites/$siteId/contacts');
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        final list = data['data'] ?? data['contacts'] ?? [];
        return List<Map<String, dynamic>>.from(list is List ? list : []);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load site contacts: $e');
    }
  }

  Future<bool> createSiteContact(
      String siteId, Map<String, dynamic> contactData) async {
    try {
      final data = {...contactData, 'site_id': int.tryParse(siteId) ?? siteId};
      final response = await dio.post('sites/$siteId/contacts', data: data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Failed to create contact: $e');
    }
  }

  Future<bool> updateSiteContact(
      String siteId, String contactId, Map<String, dynamic> contactData) async {
    try {
      final response = await dio.patch('sites/$siteId/contacts/$contactId',
          data: contactData);
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to update contact: $e');
    }
  }

  Future<bool> deleteSiteContact(String siteId, String contactId) async {
    try {
      final response = await dio.delete('sites/$siteId/contacts/$contactId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete contact: $e');
    }
  }

  // Site Checkpoints CRUD
  Future<List<Map<String, dynamic>>> getSiteCheckpoints(String siteId) async {
    try {
      final response = await dio.get('sites/$siteId/checkpoints');
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        final list = data['data'] ?? data['checkpoints'] ?? [];
        return List<Map<String, dynamic>>.from(list is List ? list : []);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load checkpoints: $e');
    }
  }

  Future<bool> createSiteCheckpoint(
      String siteId, Map<String, dynamic> checkpointData) async {
    try {
      final data = {
        ...checkpointData,
        'site_id': int.tryParse(siteId) ?? siteId
      };
      final response = await dio.post('sites/$siteId/checkpoints', data: data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          String errMsg = '';
          if (errorData['errors'] != null) {
            final errors = errorData['errors'] as Map;
            errMsg = errors.values.expand((v) => v as List).join('\n');
          } else {
            errMsg = errorData['message'] ?? '';
          }
          if (errMsg.trim().isNotEmpty) throw Exception(errMsg.trim());
        }
      }
      throw Exception('Failed to create checkpoint: $e');
    }
  }

  Future<bool> updateSiteCheckpoint(String siteId, String checkpointId,
      Map<String, dynamic> checkpointData) async {
    try {
      final response = await dio.patch(
          'sites/$siteId/checkpoints/$checkpointId',
          data: checkpointData);
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to update checkpoint: $e');
    }
  }

  Future<bool> deleteSiteCheckpoint(String siteId, String checkpointId) async {
    try {
      final response =
          await dio.delete('sites/$siteId/checkpoints/$checkpointId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete checkpoint: $e');
    }
  }

  // Site Preferences CRUD
  Future<List<Map<String, dynamic>>> getSitePreferences(String siteId) async {
    try {
      final response = await dio.get('sites/$siteId/preferences');
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        final list = data['data'] ?? data['preferences'] ?? [];
        return List<Map<String, dynamic>>.from(list is List ? list : []);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load preferences: $e');
    }
  }

  Future<bool> createSitePreference(
      String siteId, Map<String, dynamic> preferenceData) async {
    try {
      final data = {
        ...preferenceData,
        'site_id': int.tryParse(siteId) ?? siteId
      };
      final response = await dio.post('sites/$siteId/preferences', data: data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Failed to create preference: $e');
    }
  }

  Future<bool> updateSitePreference(String siteId, String preferenceId,
      Map<String, dynamic> preferenceData) async {
    try {
      final response = await dio.patch(
          'sites/$siteId/preferences/$preferenceId',
          data: preferenceData);
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to update preference: $e');
    }
  }

  Future<bool> deleteSitePreference(String siteId, String preferenceId) async {
    try {
      final response =
          await dio.delete('sites/$siteId/preferences/$preferenceId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete preference: $e');
    }
  }

  // Site Documents CRUD
  Future<List<Map<String, dynamic>>> getSiteDocuments(String siteId) async {
    try {
      final response = await dio.get('sites/$siteId/documents');
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        final list = data['data'] ?? data['documents'] ?? [];
        return List<Map<String, dynamic>>.from(list is List ? list : []);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load documents: $e');
    }
  }

  Future<bool> createSiteDocument(
      String siteId, Map<String, dynamic> documentData) async {
    try {
      final formData = FormData.fromMap({
        'site_id': int.tryParse(siteId) ?? siteId,
        'name': documentData['name'] ?? '',
        'offsite_visibility': documentData['offsite_visibility'] == true ? 1 : 0,
      });

      final files = documentData['files'];
      if (files is List) {
        for (var filePath in files) {
          if (filePath.toString().trim().isEmpty) continue;
          final fileName = filePath.toString().split(RegExp(r'[\\/]')).last;
          formData.files.add(MapEntry(
            'files[]',
            await MultipartFile.fromFile(filePath.toString(),
                filename: fileName),
          ));
        }
      }

      final response =
          await dio.post('sites/$siteId/documents', data: formData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          String errMsg = '';
          if (errorData['errors'] != null) {
            final errors = errorData['errors'] as Map;
            errMsg = errors.values.expand((v) => v as List).join('\n');
          } else {
            errMsg = errorData['message'] ?? '';
          }
          if (errMsg.trim().isNotEmpty) throw Exception(errMsg.trim());
        }
      }
      throw Exception('Failed to create document: $e');
    }
  }

  Future<bool> updateSiteDocument(String siteId, String documentId,
      Map<String, dynamic> documentData) async {
    try {
      final response = await dio.patch('sites/$siteId/documents/$documentId',
          data: {
            'name': documentData['name'],
            'offsite_visibility': documentData['offsite_visibility'] == true ? 1 : 0,
          });

      // After updating metadata, check for new files to upload
      final files = documentData['files'];
      if (files is List && files.isNotEmpty) {
        final newFiles = files.where((f) => File(f.toString()).existsSync()).toList();
        if (newFiles.isNotEmpty) {
          final formData = FormData.fromMap({ 'site_id': int.tryParse(siteId) ?? siteId });
          for (var filePath in newFiles) {
            final fileName = filePath.toString().split(RegExp(r'[\\/]')).last;
            formData.files.add(MapEntry(
              'files[]',
              await MultipartFile.fromFile(filePath.toString(), filename: fileName),
            ));
          }
          await dio.post('sites/$siteId/documents/$documentId/upload-files', data: formData);
        }
      }

      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          String errMsg = '';
          if (errorData['errors'] != null) {
            final errors = errorData['errors'] as Map;
            errMsg = errors.values.expand((v) => v as List).join('\n');
          } else {
            errMsg = errorData['message'] ?? '';
          }
          if (errMsg.trim().isNotEmpty) throw Exception(errMsg.trim());
        }
      }
      throw Exception('Failed to update document: $e');
    }
  }

  Future<bool> deleteSiteDocument(String siteId, String documentId) async {
    try {
      final response = await dio.delete('sites/$siteId/documents/$documentId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  // Admin APIs - Reports & Analytics
  Future<List<Map<String, dynamic>>> getReports() async {
    try {
      final response = await dio.get('admin/reports');
      final list = response.data['reports'] ?? response.data['data'] ?? [];
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      throw Exception('Failed to load reports');
    }
  }

  // Admin APIs - Alerts & Notifications
  Future<List<Map<String, dynamic>>> getAlerts() async {
    try {
      final response = await dio.get('admin/alerts');
      final list = response.data['alerts'] ?? response.data['data'] ?? [];
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      throw Exception('Failed to load alerts');
    }
  }

  // Pay Groups APIs
  Future<List<Map<String, dynamic>>> getPayGroups() async {
    try {
      final response = await dio.get('pay-groups');
      final data = response.data;
      
      // Handle various response formats
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        // Try different keys
        final list = data['data'] ?? data['pay_groups'] ?? data['payGroup'] ?? data;
        if (list is List) {
          return List<Map<String, dynamic>>.from(list);
        }
        // If the map itself is a single pay group, return it as a list
        if (list is Map && list['id'] != null) {
          return [Map<String, dynamic>.from(list)];
        }
      }
      return [];
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPayGroup(String id) async {
    try {
      final response = await dio.get('pay-groups/$id');
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data['pay_group'] ?? data);
      }
      return Map<String, dynamic>.from(data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to load pay group');
    }
  }

  Future<Map<String, dynamic>> createPayGroup(
    Map<String, dynamic> payGroup,
  ) async {
    try {
      final response = await dio.post('pay-groups', data: payGroup);
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data['pay_group'] ?? data);
      }
      return Map<String, dynamic>.from(data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to create pay group');
    }
  }

  Future<Map<String, dynamic>> updatePayGroup(
    String id,
    Map<String, dynamic> payGroup,
  ) async {
    try {
      final response = await dio.patch('pay-groups/$id', data: payGroup);
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data['pay_group'] ?? data);
      }
      // Backend returns empty array [] on success, return empty map
      return {};
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to update pay group');
    }
  }

  Future<bool> deletePayGroup(String id) async {
    try {
      await dio.delete('pay-groups/$id');
      return true;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to delete pay group');
    }
  }

  // Pay Rates APIs
  Future<List<Map<String, dynamic>>> getPayRates(String groupId) async {
    try {
      final response = await dio.get('pay-groups/$groupId/rates');
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to load pay rates');
    }
  }

  Future<Map<String, dynamic>> createPayRate(
    String groupId,
    Map<String, dynamic> rateData,
  ) async {
    try {
      final response = await dio.post(
        'pay-groups/$groupId/rates',
        data: rateData,
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to create pay rate');
    }
  }

  Future<Map<String, dynamic>> updatePayRate(
    String rateId,
    Map<String, dynamic> rateData,
  ) async {
    try {
      final response = await dio.patch(
        'pay-rates/$rateId',
        data: rateData,
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to update pay rate');
    }
  }

  Future<bool> deletePayRate(String rateId) async {
    try {
      await dio.delete('pay-rates/$rateId');
      return true;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to delete pay rate');
    }
  }

  // Company Settings APIs
  Future<Map<String, dynamic>> getCompanySettings() async {
    try {
      final response = await dio.get('admin/company-settings');
      return response.data['settings'] ?? response.data;
    } catch (e) {
      throw Exception('Failed to load company settings');
    }
  }

  Future<Map<String, dynamic>> updateCompanySettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      final response = await dio.put('admin/company-settings', data: settings);
      return response.data['settings'] ?? response.data;
    } catch (e) {
      throw Exception('Failed to update company settings');
    }
  }

  // Service Group APIs
  Future<List<Map<String, dynamic>>> getServiceGroups() async {
    try {
      final response = await dio.get('service-groups');
      final data = response.data;
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        final list = data['data'] ?? data['service_groups'] ?? data;
        if (list is List) {
          return List<Map<String, dynamic>>.from(list);
        }
        if (list is Map && list['id'] != null) {
          return [Map<String, dynamic>.from(list)];
        }
      }
      return [];
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to load service groups');
    }
  }

  Future<Map<String, dynamic>> createServiceGroup(
    Map<String, dynamic> group,
  ) async {
    try {
      final response = await dio.post('service-groups', data: group);
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data['service_group'] ?? data);
      }
      return {};
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to create service group');
    }
  }

  Future<Map<String, dynamic>> updateServiceGroup(
    String id,
    Map<String, dynamic> group,
  ) async {
    try {
      final response = await dio.patch('service-groups/$id', data: group);
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data['service_group'] ?? data);
      }
      return {};
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to update service group');
    }
  }

  Future<bool> deleteServiceGroup(String id) async {
    try {
      await dio.delete('service-groups/$id');
      return true;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to delete service group');
    }
  }

  // Service Rates APIs
  Future<List<Map<String, dynamic>>> getServiceRates(String groupId) async {
    try {
      final response = await dio.get('service-groups/$groupId/rates');
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to load service rates');
    }
  }

  Future<Map<String, dynamic>> createServiceRate(
    String groupId,
    Map<String, dynamic> rateData,
  ) async {
    try {
      final response = await dio.post(
        'service-groups/$groupId/rates',
        data: rateData,
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to create service rate');
    }
  }

  Future<Map<String, dynamic>> updateServiceRate(
    String rateId,
    Map<String, dynamic> rateData,
  ) async {
    try {
      final response = await dio.patch(
        'service-rates/$rateId',
        data: rateData,
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to update service rate');
    }
  }

  Future<bool> deleteServiceRate(String rateId) async {
    try {
      await dio.delete('service-rates/$rateId');
      return true;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to delete service rate');
    }
  }

  // Form Templates APIs
  Future<List<Map<String, dynamic>>> getFormTemplates() async {
    try {
      final response = await dio.get('forms');
      final data = response.data;
      
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        final list = data['data'] ?? data['forms'] ?? data['templates'] ?? [];
        return List<Map<String, dynamic>>.from(list is List ? list : []);
      }
      return [];
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to load form templates');
    }
  }

  Future<Map<String, dynamic>> createFormTemplate(
    Map<String, dynamic> template,
  ) async {
    try {
      final response = await dio.post('forms', data: template);
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data['form'] ?? data['data'] ?? data);
      }
      return {};
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to create form template');
    }
  }

  Future<Map<String, dynamic>> updateFormTemplate(
    String id,
    Map<String, dynamic> template,
  ) async {
    try {
      final response = await dio.patch('forms/$id', data: template);
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data['form'] ?? data['data'] ?? data);
      }
      return {};
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to update form template');
    }
  }

  Future<bool> deleteFormTemplate(String id) async {
    try {
      await dio.delete('forms/$id');
      return true;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to delete form template');
    }
  }

  // Digital Occurrence Log APIs
  Future<List<Map<String, dynamic>>> getDigitalOccurrenceLogs() async {
    try {
      final response = await dio.get('admin/occurrence-logs');
      return List<Map<String, dynamic>>.from(
        response.data['logs'] ?? response.data['data'] ?? [],
      );
    } catch (e) {
      throw Exception('Failed to load occurrence logs');
    }
  }

  Future<Map<String, dynamic>> createDigitalOccurrenceLog(
    Map<String, dynamic> log,
  ) async {
    try {
      final response = await dio.post('admin/occurrence-logs', data: log);
      return response.data['log'] ?? response.data;
    } catch (e) {
      throw Exception('Failed to create occurrence log');
    }
  }

  Future<Map<String, dynamic>> updateDigitalOccurrenceLog(
    String id,
    Map<String, dynamic> log,
  ) async {
    try {
      final response = await dio.put('admin/occurrence-logs/$id', data: log);
      return response.data['log'] ?? response.data;
    } catch (e) {
      throw Exception('Failed to update occurrence log');
    }
  }

  Future<void> deleteDigitalOccurrenceLog(String id) async {
    try {
      await dio.delete('admin/occurrence-logs/$id');
    } catch (e) {
      throw Exception('Failed to delete occurrence log');
    }
  }

  // Organization Compliance APIs

  Future<Map<String, dynamic>> createOrganizationCompliance(
    Map<String, dynamic> compliance,
  ) async {
    try {
      final response =
          await dio.post('organization/compliances', data: compliance);
      return response.data['compliance'] ?? response.data;
    } catch (e) {
      throw Exception('Failed to create organization compliance');
    }
  }

  Future<Map<String, dynamic>> updateOrganizationCompliance(
    String id,
    Map<String, dynamic> compliance,
  ) async {
    try {
      final response =
          await dio.patch('organization/compliances/$id', data: compliance);
      return response.data['compliance'] ?? response.data;
    } catch (e) {
      throw Exception('Failed to update organization compliance');
    }
  }

  Future<void> deleteOrganizationCompliance(String id) async {
    try {
      await dio.delete('organization/compliances/$id');
    } catch (e) {
      throw Exception('Failed to delete organization compliance');
    }
  }

  // Additional Admin Methods (for AdminViewModel compatibility)
  Future<List<Map<String, dynamic>>> getCustomerContacts(
      String customerId) async {
    try {
      final response = await dio.get('customers/$customerId/contacts');
      final list =
          response.data is List ? response.data : (response.data['data'] ?? []);
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerInvoiceProfiles(
      String customerId) async {
    try {
      final response = await dio.get('customers/$customerId/invoice-profiles');
      final list =
          response.data is List ? response.data : (response.data['data'] ?? []);
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerInvoices(
      String customerId) async {
    try {
      final response = await dio.get('customers/$customerId/invoices');
      final list =
          response.data is List ? response.data : (response.data['data'] ?? []);
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      return [];
    }
  }

  Future<bool> createCustomerContact(
      String customerId, Map<String, dynamic> contactData) async {
    try {
      final response = await dio.post(
        'customers/$customerId/contacts',
        data: contactData,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCustomerContact(
    String customerId,
    String contactId,
    Map<String, dynamic> contactData,
  ) async {
    try {
      final response = await dio.patch(
        'customers/$customerId/contacts/$contactId',
        data: contactData,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCustomerContact(
      String customerId, String contactId) async {
    try {
      final response =
          await dio.delete('customers/$customerId/contacts/$contactId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createCustomerInvoiceProfile(
      String customerId, Map<String, dynamic> profileData) async {
    try {
      final response = await dio.post(
        'customers/$customerId/invoice-profiles',
        data: profileData,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCustomerInvoiceProfile(
    String customerId,
    String profileId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await dio.patch(
        'customers/$customerId/invoice-profiles/$profileId',
        data: profileData,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCustomerInvoiceProfile(
      String customerId, String profileId) async {
    try {
      final response = await dio.delete(
        'customers/$customerId/invoice-profiles/$profileId',
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createCustomerInvoice(
      String customerId, Map<String, dynamic> invoiceData) async {
    try {
      final response = await dio.post(
        'customers/$customerId/invoices',
        data: invoiceData,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCustomerInvoice(
    String customerId,
    String invoiceId,
    Map<String, dynamic> invoiceData,
  ) async {
    try {
      final response = await dio.patch(
        'customers/$customerId/invoices/$invoiceId',
        data: invoiceData,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCustomerInvoice(
      String customerId, String invoiceId) async {
    try {
      final response =
          await dio.delete('customers/$customerId/invoices/$invoiceId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getActivities() async {
    try {
      final response = await dio.get('admin/activities');
      return List<Map<String, dynamic>>.from(
        response.data['activities'] ?? response.data['data'] ?? [],
      );
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSystemLogs() async {
    try {
      final response = await dio.get('admin/system-logs');
      return List<Map<String, dynamic>>.from(
        response.data['logs'] ?? response.data['data'] ?? [],
      );
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getSystemStatistics() async {
    try {
      final response = await dio.get('admin/system-statistics');
      return response.data['statistics'] ?? response.data;
    } catch (e) {
      return {};
    }
  }

  Future<bool> markAlertAsRead(String alertId) async {
    try {
      final response = await dio.post('admin/alerts/$alertId/read');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAlert(String alertId) async {
    try {
      final response = await dio.delete('admin/alerts/$alertId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllAlertsAsRead() async {
    try {
      final response = await dio.post('admin/alerts/read-all');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getShiftNotes() async {
    try {
      final response = await dio.get('admin/shifts/notes');
      return List<Map<String, dynamic>>.from(
        response.data['notes'] ?? response.data['data'] ?? [],
      );
    } catch (e) {
      return [];
    }
  }

  Future<bool> createShiftNote(Map<String, dynamic> noteData) async {
    try {
      final response = await dio.post('admin/shifts/notes', data: noteData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateShiftNote(
    String noteId,
    Map<String, dynamic> noteData,
  ) async {
    try {
      final response = await dio.put(
        '/admin/shifts/notes/$noteId',
        data: noteData,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteShiftNote(String noteId) async {
    try {
      final response = await dio.delete('admin/shifts/notes/$noteId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSecurityOfficers() async {
    try {
      final response = await dio.get('staff');
      final data = response.data;
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map) {
        list = data['staff'] ?? data['data'] ?? [];
      } else {
        list = [];
      }
      // Filter for supervisors only (as per user requirement)
      return List<Map<String, dynamic>>.from(list.where((staff) {
        final role = (staff['role'] ?? '').toString().toLowerCase();
        return role == 'supervisor' || role == 'worker' || role == 'security-officer' || role == 'security officer';
      }));
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getClockInQuestionnaires() async {
    try {
      final response = await dio.get('admin/clock-in-questionnaires');
      return List<Map<String, dynamic>>.from(
        response.data['questionnaires'] ?? response.data['data'] ?? [],
      );
    } catch (e) {
      return [];
    }
  }

  Future<bool> rejectTimesheet(String timesheetId, String reason) async {
    try {
      final response = await dio.post(
        'timesheets/$timesheetId/reject',
        data: {'reason': reason},
      );
      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception('Failed to reject timesheet');
    }
  }

  Future<List<Map<String, dynamic>>> getTeamMessages() async {
    try {
      final response = await dio.get('admin/team-messages');
      return List<Map<String, dynamic>>.from(response.data['messages'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<bool> sendTeamMessage(String title, String body) async {
    try {
      final response = await dio.post('admin/team-messages', data: {'title': title, 'body': body});
      return response.statusCode == 201 || response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('sendTeamMessage error: ${e.response?.statusCode} ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('sendTeamMessage unknown error: $e');
      return false;
    }
  }

  Future<bool> deleteTeamMessage(String id) async {
    try {
      final response = await dio.delete('admin/team-messages/$id');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getMessageThreads(String messageId) async {
    try {
      final response = await dio.get('admin/team-messages/$messageId/replies');
      return List<Map<String, dynamic>>.from(response.data['threads'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<bool> sendThreadReply(String messageId, int threadUserId, String body) async {
    try {
      final response = await dio.post(
        'admin/team-messages/$messageId/replies',
        data: {'thread_user_id': threadUserId, 'body': body},
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('sendThreadReply error: ${e.response?.statusCode} ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('sendThreadReply unknown error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAlarmHistory() async {
    try {
      final response = await dio.get('admin/alarms');
      final data = response.data;
      if (data is List) return List<Map<String, dynamic>>.from(data);
      return List<Map<String, dynamic>>.from(data['alarms'] ?? data['data'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<bool> raiseAlarm([Map<String, dynamic>? data]) async {
    try {
      final response = await dio.post('admin/alarms', data: data ?? {});
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
