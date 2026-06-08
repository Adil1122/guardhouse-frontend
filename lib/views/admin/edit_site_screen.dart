import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';

class EditSiteScreen extends StatefulWidget {
  final Map<String, dynamic> site;

  const EditSiteScreen({super.key, required this.site});

  @override
  State<EditSiteScreen> createState() => _EditSiteScreenState();
}

class _EditSiteScreenState extends State<EditSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _contactController;
  late TextEditingController _descriptionController;

  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.site['name'] ?? '');
    _addressController = TextEditingController(
      text: widget.site['address'] ?? '',
    );
    _contactController = TextEditingController(
      text: widget.site['contact'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.site['description'] ?? '',
    );
    _selectedStatus = widget.site['status'] ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateSite() async {
    if (_formKey.currentState!.validate()) {
      final adminViewModel = context.read<AdminViewModel>();

      final siteData = {
        'id': widget.site['id'],
        'name': _nameController.text,
        'address': _addressController.text,
        'contact': _contactController.text.isEmpty
            ? null
            : _contactController.text,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'status': _selectedStatus,
      };

      final success = await adminViewModel.updateSite(siteData);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Site updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                adminViewModel.errorMessage ?? 'Failed to update site',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminViewModel = context.watch<AdminViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Site')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Site Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Site Name',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter site name';
                  }
                  return null;
                },
                enabled: !adminViewModel.isLoading,
              ),
              const SizedBox(height: 16),

              // Address Field
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
                enabled: !adminViewModel.isLoading,
              ),
              const SizedBox(height: 16),

              // Contact Field
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Number (Optional)',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                enabled: !adminViewModel.isLoading,
              ),
              const SizedBox(height: 16),

              // Status Selection
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.info_outline),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: adminViewModel.isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedStatus = value);
                        }
                      },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                enabled: !adminViewModel.isLoading,
              ),
              const SizedBox(height: 32),

              // Update Button
              ElevatedButton(
                onPressed: adminViewModel.isLoading ? null : _handleUpdateSite,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: adminViewModel.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Update Site', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
