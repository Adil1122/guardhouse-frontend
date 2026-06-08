import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/site_models.dart';
import 'custom_text_field.dart';
import 'site_details_form.dart';

class SiteContactForm extends StatefulWidget {
  final SiteContact? initialContact;
  final Function(SiteContact) onSave;
  final VoidCallback onCancel;

  const SiteContactForm({
    Key? key,
    this.initialContact,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<SiteContactForm> createState() => _SiteContactFormState();
}

class _SiteContactFormState extends State<SiteContactForm> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _positionController;
  late TextEditingController _emailController;
  late TextEditingController _contactNumberController;
  late TextEditingController _notesController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final contact = widget.initialContact;
    _firstNameController =
        TextEditingController(text: contact?.firstName ?? '');
    _lastNameController = TextEditingController(text: contact?.lastName ?? '');
    _positionController = TextEditingController(text: contact?.position ?? '');
    _emailController = TextEditingController(text: contact?.email ?? '');
    _contactNumberController =
        TextEditingController(text: contact?.contactNumber ?? '');
    _notesController = TextEditingController(text: contact?.notes ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _positionController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _validateAndSave() {
    if (_formKey.currentState!.validate()) {
      final contact = SiteContact(
        id: widget.initialContact?.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        position: _positionController.text.trim(),
        email: _emailController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      widget.onSave(contact);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initialContact == null ? 'Add Contact' : 'Edit Contact',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('First Name*',
                          style: Theme.of(context).textTheme.labelMedium),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(hintText: 'First name'),
                        maxLength: 50,
                        validator: SiteFormValidator.validateFirstName,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last Name*',
                          style: Theme.of(context).textTheme.labelMedium),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(hintText: 'Last name'),
                        maxLength: 50,
                        validator: SiteFormValidator.validateLastName,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            TextFormField(
              controller: _positionController,
              decoration: const InputDecoration(hintText: 'Position'),
              maxLength: 50,
              validator: SiteFormValidator.validatePosition,
            ),
            SizedBox(height: 12.h),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(hintText: 'Email (optional)'),
              keyboardType: TextInputType.emailAddress,
              validator: SiteFormValidator.validateEmail,
            ),
            SizedBox(height: 12.h),
            TextFormField(
              controller: _contactNumberController,
              decoration: const InputDecoration(hintText: 'Contact Number'),
              keyboardType: TextInputType.phone,
              validator: SiteFormValidator.validatePhoneNumber,
            ),
            SizedBox(height: 12.h),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(hintText: 'Notes (optional)'),
              maxLines: 3,
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
                SizedBox(width: 8.w),
                ElevatedButton(
                  onPressed: _validateAndSave,
                  child: const Text('Save Contact'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SiteCheckpointForm extends StatefulWidget {
  final SiteCheckpoint? initialCheckpoint;
  final Function(SiteCheckpoint) onSave;
  final VoidCallback onCancel;

  const SiteCheckpointForm({
    Key? key,
    this.initialCheckpoint,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<SiteCheckpointForm> createState() => _SiteCheckpointFormState();
}

class _SiteCheckpointFormState extends State<SiteCheckpointForm> {
  late TextEditingController _nameController;
  late TextEditingController _placeIdController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  late TextEditingController _radiusController;
  late TextEditingController _qrCodeController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final checkpoint = widget.initialCheckpoint;
    _nameController = TextEditingController(text: checkpoint?.name ?? '');
    _placeIdController =
        TextEditingController(text: checkpoint?.geofence.placeId ?? '');
    _latController =
        TextEditingController(text: checkpoint?.geofence.lat?.toString() ?? '');
    _lonController =
        TextEditingController(text: checkpoint?.geofence.lon?.toString() ?? '');
    _radiusController = TextEditingController(
        text: checkpoint?.geofence.checkInDistance?.toString() ?? '50');
    _qrCodeController =
        TextEditingController(text: checkpoint?.qrCodeToken ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _placeIdController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _radiusController.dispose();
    _qrCodeController.dispose();
    super.dispose();
  }

  void _validateAndSave() {
    if (_formKey.currentState!.validate()) {
      final checkpoint = SiteCheckpoint(
        id: widget.initialCheckpoint?.id,
        name: _nameController.text.trim(),
        geofence: Geofence(
          placeId: _placeIdController.text.trim().isEmpty
              ? null
              : _placeIdController.text.trim(),
          lat: double.tryParse(_latController.text),
          lon: double.tryParse(_lonController.text),
          checkInDistance: int.tryParse(_radiusController.text) ?? 50,
        ),
        qrCodeToken: _qrCodeController.text.trim().isEmpty
            ? null
            : _qrCodeController.text.trim(),
      );
      widget.onSave(checkpoint);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initialCheckpoint == null
                  ? 'Add Checkpoint'
                  : 'Edit Checkpoint',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Checkpoint name'),
              maxLength: 50,
              validator: SiteFormValidator.validateCheckpointName,
            ),
            SizedBox(height: 12.h),
            TextFormField(
              controller: _placeIdController,
              decoration: const InputDecoration(hintText: 'Place ID (optional)'),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Latitude*',
                          style: Theme.of(context).textTheme.labelMedium),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _latController,
                        decoration: const InputDecoration(hintText: 'Latitude'),
                        keyboardType: TextInputType.number,
                        validator: SiteFormValidator.validateLatitude,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Longitude*',
                          style: Theme.of(context).textTheme.labelMedium),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _lonController,
                        decoration: const InputDecoration(hintText: 'Longitude'),
                        keyboardType: TextInputType.number,
                        validator: SiteFormValidator.validateLongitude,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            TextFormField(
              controller: _radiusController,
              decoration: const InputDecoration(hintText: 'Check-in radius (meters)'),
              keyboardType: TextInputType.number,
              validator: SiteFormValidator.validateDistance,
            ),
            SizedBox(height: 12.h),
            TextFormField(
              controller: _qrCodeController,
              decoration: const InputDecoration(hintText: 'QR Code Token (optional)'),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
                SizedBox(width: 8.w),
                ElevatedButton(
                  onPressed: _validateAndSave,
                  child: const Text('Save Checkpoint'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SiteDocumentForm extends StatefulWidget {
  final SiteDocument? initialDocument;
  final Function(SiteDocument) onSave;
  final VoidCallback onCancel;

  const SiteDocumentForm({
    Key? key,
    this.initialDocument,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<SiteDocumentForm> createState() => _SiteDocumentFormState();
}

class _SiteDocumentFormState extends State<SiteDocumentForm> {
  late TextEditingController _nameController;
  late List<String> _selectedFiles;
  late bool _offsiteVisibility;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final document = widget.initialDocument;
    _nameController = TextEditingController(text: document?.name ?? '');
    _selectedFiles = List.from(document?.files ?? []);
    _offsiteVisibility = document?.offsiteVisibility ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _validateAndSave() {
    if (_formKey.currentState!.validate()) {
      final document = SiteDocument(
        id: widget.initialDocument?.id,
        name: _nameController.text.trim(),
        files: _selectedFiles,
        offsiteVisibility: _offsiteVisibility,
      );
      widget.onSave(document);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initialDocument == null ? 'Add Document' : 'Edit Document',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Document name'),
              maxLength: 50,
              validator: SiteFormValidator.validateDocumentName,
            ),
            SizedBox(height: 12.h),
            CheckboxListTile(
              value: _offsiteVisibility,
              onChanged: (value) =>
                  setState(() => _offsiteVisibility = value ?? false),
              title: const Text('Viewable Offsite'),
              subtitle:
                  const Text('Allow viewing this document outside of site'),
            ),
            SizedBox(height: 16.h),
            Text('Attached Files',
                style: Theme.of(context).textTheme.labelMedium),
            SizedBox(height: 8.h),
            if (_selectedFiles.isEmpty)
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'No files attached (note: file upload requires additional implementation)',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: _selectedFiles.length,
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.file_present),
                  title: Text(_selectedFiles[index].split('/').last),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () =>
                        setState(() => _selectedFiles.removeAt(index)),
                  ),
                ),
              ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
                SizedBox(width: 8.w),
                ElevatedButton(
                  onPressed: _validateAndSave,
                  child: const Text('Save Document'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
