import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/site_models.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/site_management_viewmodel.dart';
import '../../widgets/site_details_form.dart';
import '../../widgets/site_form_components.dart';

class SiteDetailScreen extends StatefulWidget {
  final String siteId;

  const SiteDetailScreen({
    super.key,
    required this.siteId,
  });

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Site? _site;
  bool _isLoadingRelated = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSiteData();
  }

  Future<void> _loadSiteData() async {
    // Load site data and related data
    final viewModel = context.read<SiteManagementViewModel>();
    await viewModel.loadSites();
    _site = viewModel.sites.firstWhere(
      (s) => s.id.toString() == widget.siteId,
      orElse: () => viewModel.sites.first,
    );

    if (mounted) {
      setState(() => _isLoadingRelated = true);
      await Future.wait([
        viewModel.loadSiteContacts(widget.siteId),
        viewModel.loadSiteCheckpoints(widget.siteId),
        viewModel.loadSitePreferences(widget.siteId),
        viewModel.loadSiteDocuments(widget.siteId),
      ]);
      if (mounted) {
        setState(() => _isLoadingRelated = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_site?.name ?? 'Site Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Contacts'),
            Tab(text: 'Checkpoints'),
            Tab(text: 'Documents'),
          ],
        ),
      ),
      body: _isLoadingRelated
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildContactsTab(),
                _buildCheckpointsTab(),
                _buildDocumentsTab(),
              ],
            ),
    );
  }

  Widget _buildDetailsTab() {
    return Consumer<SiteManagementViewModel>(
      builder: (context, viewModel, _) {
        if (_site == null) {
          return const Center(child: Text('Site not found'));
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Type:', _site!.type),
                      SizedBox(height: 12.h),
                      _buildDetailRow('Name:', _site!.name),
                      SizedBox(height: 12.h),
                      if (_site!.address.isNotEmpty)
                        Column(
                          children: [
                            _buildDetailRow(
                              'Address:',
                              '${_site!.address['name']}, ${_site!.address['city']}, ${_site!.address['state']} ${_site!.address['zip']}, ${_site!.address['country']}',
                            ),
                            SizedBox(height: 12.h),
                          ],
                        ),
                      if (_site!.geofence.isNotEmpty)
                        Column(
                          children: [
                            _buildDetailRow(
                              'Location:',
                              '${_site!.geofence['lat']}, ${_site!.geofence['lon']}',
                            ),
                            SizedBox(height: 12.h),
                            _buildDetailRow(
                              'Check-in Distance:',
                              '${_site!.geofence['check_in_distance']} meters',
                            ),
                            SizedBox(height: 12.h),
                          ],
                        ),
                      if (_site!.instructions != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Instructions:',
                                style: Theme.of(context).textTheme.labelMedium),
                            SizedBox(height: 4.h),
                            Text(_site!.instructions ?? ''),
                            SizedBox(height: 12.h),
                          ],
                        ),
                      _buildDetailRow(
                        'Created:',
                        _site!.createdAt?.toString().split('.')[0] ?? 'N/A',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: _showEditDialog,
                icon: const Icon(Icons.edit),
                label: const Text('Edit Site'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactsTab() {
    return Consumer<SiteManagementViewModel>(
      builder: (context, viewModel, _) {
        final contacts = viewModel.getContactsForSite(widget.siteId);

        return ListView(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: ElevatedButton.icon(
                onPressed: () => _showContactForm(null),
                icon: const Icon(Icons.add),
                label: const Text('Add Contact'),
              ),
            ),
            if (contacts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No contacts yet'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return ContactTile(
                    contact: contact,
                    onEdit: () => _showContactForm(contact),
                    onDelete: () => _confirmDeleteContact(contact),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildCheckpointsTab() {
    return Consumer<SiteManagementViewModel>(
      builder: (context, viewModel, _) {
        final checkpoints = viewModel.getCheckpointsForSite(widget.siteId);

        return ListView(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: ElevatedButton.icon(
                onPressed: () => _showCheckpointForm(null),
                icon: const Icon(Icons.add),
                label: const Text('Add Checkpoint'),
              ),
            ),
            if (checkpoints.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No checkpoints yet'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: checkpoints.length,
                itemBuilder: (context, index) {
                  final checkpoint = checkpoints[index];
                  return CheckpointTile(
                    checkpoint: checkpoint,
                    onEdit: () => _showCheckpointForm(checkpoint),
                    onDelete: () => _confirmDeleteCheckpoint(checkpoint),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildDocumentsTab() {
    return Consumer<SiteManagementViewModel>(
      builder: (context, viewModel, _) {
        final documents = viewModel.getDocumentsForSite(widget.siteId);

        return ListView(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: ElevatedButton.icon(
                onPressed: () => _showDocumentForm(null),
                icon: const Icon(Icons.add),
                label: const Text('Add Document'),
              ),
            ),
            if (documents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No documents yet'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final document = documents[index];
                  return DocumentTile(
                    document: document,
                    onEdit: () => _showDocumentForm(document),
                    onDelete: () => _confirmDeleteDocument(document),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  void _showEditDialog() {
    final adminVm = context.read<AdminViewModel>();
    // Load data if not already loaded
    adminVm.loadCustomers();
    adminVm.loadServiceGroups();
    adminVm.loadPayGroups();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Site'),
        content: SizedBox(
          width: MediaQuery.of(dialogContext).size.width * 0.8,
          child: SingleChildScrollView(
            child: SiteDetailsForm(
              initialDetails:
                  _site != null ? _convertToSiteDetails(_site!) : null,
              onSave: (details) {
                _handleEditSite(details);
                Navigator.pop(dialogContext);
              },
              serviceGroups: adminVm.serviceGroups,
              payGroups: adminVm.payGroups,
              customers: adminVm.customers,
            ),
          ),
        ),
      ),
    );
  }

  SiteDetails _convertToSiteDetails(Site site) {
    return SiteDetails(
      id: site.id.toString(),
      type: site.type,
      name: site.name,
      customerId: site.customerProfileId?.toString(),
      address: SiteAddress(
        name: site.address['name'] ?? '',
        city: site.address['city'] ?? '',
        state: site.address['state'] ?? '',
        zip: site.address['zip'] ?? '',
        country: site.address['country'] ?? '',
      ),
      geofence: Geofence(
        placeId: site.geofence['place_id'],
        lat: (site.geofence['lat'] as num?)?.toDouble(),
        lon: (site.geofence['lon'] as num?)?.toDouble(),
        checkInDistance: site.geofence['check_in_distance'],
      ),
      instructions: site.instructions,
    );
  }

  Future<void> _handleEditSite(SiteDetails details) async {
    final viewModel = context.read<SiteManagementViewModel>();
    final success = await viewModel.updateSite(
      widget.siteId,
      {
        'type': details.type,
        'name': details.name,
        'address': details.address.toJson(),
        'geofence': details.geofence.toJson(),
        if (details.instructions != null) 'instructions': details.instructions,
      },
    );

    if (success && mounted) {
      await _loadSiteData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Site updated successfully')),
      );
    }
  }

  void _showContactForm(SiteContact? contact) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SiteContactForm(
          initialContact: contact,
          onSave: (updatedContact) {
            _handleSaveContact(updatedContact, isNew: contact == null);
            Navigator.pop(context);
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _handleSaveContact(SiteContact contact,
      {required bool isNew}) async {
    final viewModel = context.read<SiteManagementViewModel>();
    final success = isNew
        ? await viewModel.createSiteContact(widget.siteId, contact.toJson())
        : await viewModel.updateSiteContact(
            widget.siteId,
            contact.id.toString(),
            contact.toJson(),
          );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isNew ? 'Contact added' : 'Contact updated')),
      );
    }
  }

  Future<void> _confirmDeleteContact(SiteContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Delete ${contact.firstName} ${contact.lastName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final viewModel = context.read<SiteManagementViewModel>();
      await viewModel.deleteSiteContact(widget.siteId, contact.id.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact deleted')),
      );
    }
  }

  void _showCheckpointForm(SiteCheckpoint? checkpoint) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SiteCheckpointForm(
          initialCheckpoint: checkpoint,
          onSave: (updatedCheckpoint) {
            _handleSaveCheckpoint(updatedCheckpoint, isNew: checkpoint == null);
            Navigator.pop(context);
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _handleSaveCheckpoint(SiteCheckpoint checkpoint,
      {required bool isNew}) async {
    final viewModel = context.read<SiteManagementViewModel>();
    final success = isNew
        ? await viewModel.createSiteCheckpoint(
            widget.siteId, checkpoint.toJson())
        : await viewModel.updateSiteCheckpoint(
            widget.siteId,
            checkpoint.id.toString(),
            checkpoint.toJson(),
          );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isNew ? 'Checkpoint added' : 'Checkpoint updated')),
      );
    }
  }

  Future<void> _confirmDeleteCheckpoint(SiteCheckpoint checkpoint) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Checkpoint'),
        content: Text('Delete checkpoint "${checkpoint.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final viewModel = context.read<SiteManagementViewModel>();
      await viewModel.deleteSiteCheckpoint(
          widget.siteId, checkpoint.id.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checkpoint deleted')),
      );
    }
  }

  void _showDocumentForm(SiteDocument? document) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SiteDocumentForm(
          initialDocument: document,
          onSave: (updatedDocument) {
            _handleSaveDocument(updatedDocument, isNew: document == null);
            Navigator.pop(context);
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _handleSaveDocument(SiteDocument document,
      {required bool isNew}) async {
    final viewModel = context.read<SiteManagementViewModel>();
    final success = isNew
        ? await viewModel.createSiteDocument(widget.siteId, document.toJson())
        : await viewModel.updateSiteDocument(
            widget.siteId,
            document.id.toString(),
            document.toJson(),
          );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isNew ? 'Document added' : 'Document updated')),
      );
    }
  }

  Future<void> _confirmDeleteDocument(SiteDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete document "${document.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final viewModel = context.read<SiteManagementViewModel>();
      await viewModel.deleteSiteDocument(widget.siteId, document.id.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document deleted')),
      );
    }
  }
}

// Helper widgets for list tiles
class ContactTile extends StatelessWidget {
  final SiteContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ContactTile({
    Key? key,
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: ListTile(
        title: Text('${contact.firstName} ${contact.lastName}'),
        subtitle: Text('${contact.position} • ${contact.contactNumber}'),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            PopupMenuItem(
              child: const Text('Edit'),
              onTap: onEdit,
            ),
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class CheckpointTile extends StatelessWidget {
  final SiteCheckpoint checkpoint;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CheckpointTile({
    Key? key,
    required this.checkpoint,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: ListTile(
        title: Text(checkpoint.name),
        subtitle: Text(
          'Lat: ${checkpoint.geofence.lat?.toStringAsFixed(4)}, Lon: ${checkpoint.geofence.lon?.toStringAsFixed(4)}',
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            PopupMenuItem(
              child: const Text('Edit'),
              onTap: onEdit,
            ),
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentTile extends StatelessWidget {
  final SiteDocument document;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DocumentTile({
    Key? key,
    required this.document,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: ListTile(
        leading: const Icon(Icons.document_scanner),
        title: Text(document.name),
        subtitle: Text('Files: ${document.files.length}'),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            PopupMenuItem(
              child: const Text('Edit'),
              onTap: onEdit,
            ),
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
