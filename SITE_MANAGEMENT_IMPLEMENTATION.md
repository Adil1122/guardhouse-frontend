# Site Management CRUD - Implementation Summary

## Files Created/Modified

### 1. **Updated Models** 
**File**: `lib/models/site_models.dart`

Updated with proper API mapping:
- ✅ `Geofence` class - replaces old `GeofenceLocation`
- ✅ `SiteAddress` - with `name` field instead of `address`
- ✅ `SiteDetails` - complete main site information
- ✅ `SiteContact` - contact management with ID support
- ✅ `SiteCheckpoint` - checkpoint with geofence
- ✅ `SitePreference` - preference settings
- ✅ `SiteDocument` - document management
- ✅ `Site` - list view model

All models include:
- Proper toJson() for API submission (snake_case)
- fromJson() for API responses (handling both formats)
- copyWith() for immutable updates

### 2. **API Service Methods**
**File**: `lib/services/admin_api_service.dart`

Added comprehensive CRUD for:
- ✅ Sites (GET list, POST create, PATCH update, DELETE)
- ✅ Site Contacts (all CRUD operations)
- ✅ Site Checkpoints (all CRUD operations)
- ✅ Site Preferences (all CRUD operations)
- ✅ Site Documents (with file upload support via FormData)

All methods properly handle:
- HTTP verb correctness (PATCH for updates, not PUT)
- Error propagation with meaningful messages
- Response format variations
- Nested API structure (sites/{siteId}/contacts, etc.)

### 3. **ViewModel**
**File**: `lib/viewmodels/site_management_viewmodel.dart`

Complete state management with:
- ✅ Loading/error state management
- ✅ Data caching by site ID
- ✅ CRUD operations as Future<bool>
- ✅ Automatic notifyListeners() calls
- ✅ Related data loaders for all entity types

Methods organized by entity:
- Site management (load, create, update, delete)
- Contact management (load, create, update, delete)  
- Checkpoint management (load, create, update, delete)
- Preference management (load, create, update, delete)
- Document management (load, create, update, delete)

### 4. **Form Widgets**
**File**: `lib/widgets/site_details_form.dart`

Main form with:
- ✅ `SiteFormValidator` class - comprehensive validation logic
- ✅ Full site fields (type, name, address, geofence, defaults)
- ✅ Dropdowns for service/pay groups and customers
- ✅ Complex validation (lat/lon ranges, email format, phone length)
- ✅ Instructions field support

**File**: `lib/widgets/site_form_components.dart`

Individual entity forms:
- ✅ `SiteContactForm` - first/last name, position, phone, email, notes
- ✅ `SiteCheckpointForm` - name, location, radius, QR token
- ✅ `SiteDocumentForm` - name, file list, offsite visibility toggle

All forms include:
- Form validation with GlobalKey
- Cancel/Save buttons
- Callback returns model instead of doing nav pop

### 5. **Detail Screen**
**File**: `lib/views/admin/site_detail_screen.dart`

Complete tabbed management interface:
- ✅ Details tab - view/edit main site info
- ✅ Contacts tab - full CRUD for contacts
- ✅ Checkpoints tab - full CRUD for checkpoints
- ✅ Documents tab - full CRUD for documents

Features:
- ✅ Loads all related data on init
- ✅ Add buttons on each tab
- ✅ List tiles with edit/delete context menus
- ✅ Confirmation dialogs for destructive actions
- ✅ Snackbar feedback for all operations
- ✅ Proper error handling and display
- ✅ Helper widgets: `ContactTile`, `CheckpointTile`, `DocumentTile`

## Backend Integration Summary

### Validation Coverage
✅ All frontend validations match backend rules:
- Site name: required, max 100 chars
- Address fields: all required
- Coordinates: required, proper ranges (-90/90, -180/180)
- Contact name fields: required, max 50 chars
- Contact phone: required, min 7 digits
- Contact email: optional but validated if provided
- Checkpoint name: required, max 50 chars
- Document name: required, max 50 chars

### API Endpoint Coverage
✅ All endpoints implemented:
- Sites: list, create (POST), update (PATCH), delete
- Contacts: list, create, update, delete
- Checkpoints: list, create, update, delete
- Preferences: list, create, update, delete
- Documents: list, create (with FormData), update, delete

### Field Name Mapping
✅ Proper conversion between Dart and Laravel:
- `firstName` ↔ `first_name`
- `lastName` ↔ `last_name`
- `contactNumber` ↔ `contact_number`
- `placeId` ↔ `place_id`
- `qrCodeToken` ↔ `qr_code_token`
- `offsiteVisibility` ↔ `offsite_visibility`
- `customClockInQuestionnaire` ↔ `custom_clockin_questionnaire`

## Setup Instructions

### 1. Add Provider to Your App
In `main.dart` or your providers file:

```dart
import 'viewmodels/site_management_viewmodel.dart';

MultiProvider(
  providers: [
    // ... existing providers
    ChangeNotifierProvider(
      create: (context) => SiteManagementViewModel(
        context.read<AdminApiService>(),
      ),
    ),
  ],
  child: MyApp(),
),
```

### 2. Add Routes
In `routes/routes.dart`:

```dart
GoRoute(
  path: 'sites/:siteId',
  builder: (context, state) => SiteDetailScreen(
    siteId: state.pathParameters['siteId']!,
  ),
),
```

### 3. Update Site Lists Links
In `site_management_screen.dart`, update the edit/view handler to navigate to detail screen:

```dart
// Instead of showing edit dialog:
context.push('/admin/sites/${site['id']}'); // Using GoRouter

// Or in the card's Edit button:
ElevatedButton(
  onPressed: () => context.push('/admin/sites/${site['id']}'),
  child: const Text('Manage'),
),
```

## Usage Examples

### Creating a New Site
```dart
final viewModel = context.read<SiteManagementViewModel>();

final success = await viewModel.createSite({
  'type': 'static',
  'name': 'USAID Home Office',
  'customer_profile_id': null,
  'address': {
    'name': '110-Z',
    'city': 'DGKhan',
    'state': 'Punjab',
    'zip': '32200',
    'country': 'Pakistan',
  },
  'geofence': {
    'place_id': 'jf8ryu4rbhvbrhfbr',
    'lat': 7.85652,
    'lon': 88.587964,
    'check_in_distance': 50,
  },
  'instructions': 'This is what it is',
});

if (success) {
  // Success - site created
}, else {
  // Failed - show error
}
```

### Adding a Contact
```dart
final success = await viewModel.createSiteContact(siteId, {
  'first_name': 'John',
  'last_name': 'Doe',
  'position': 'Manager',
  'email': 'john@example.com',
  'contact_number': '03001234567',
  'notes': 'Backup contact',
});
```

### Adding a Checkpoint
```dart
final success = await viewModel.createSiteCheckpoint(siteId, {
  'name': 'Main Gate',
  'geofence': {
    'lat': 7.85652,
    'lon': 88.587964,
    'check_in_distance': 50,
  },
  'qr_code_token': 'abc123xyz',
});
```

## Testing the Implementation

### Full CRUD Test Flow
1. ✅ Navigate to site management
2. ✅ Create new site with form validation
3. ✅ View site details (all tabs)
4. ✅ Add contact with validation
5. ✅ Edit contact
6. ✅ Delete contact (with confirmation)
7. ✅ Add checkpoint with geofence validation
8. ✅ Edit checkpoint location
9. ✅ Delete checkpoint
10. ✅ Add document
11. ✅ Edit document
12. ✅ Delete document
13. ✅ Update site details
14. ✅ Delete site (with confirmation)

### API Verification
- ✅ Check Network tab - PATCH is used for updates (not PUT)
- ✅ Check request payload - field names are snake_case
- ✅ Check response parsing - models handle both camelCase and snake_case
- ✅ Check error handling - meaningful error messages from backend

## Key Design Decisions

1. **Nested API Structure**: Site-related operations are nested under `/sites/{siteId}/`
2. **Field Name Convention**: API uses snake_case, models translate automatically
3. **No Direct FormData in Views**: Forms return model objects, ViewModel handles API
4. **Proper HTTP Verbs**: PATCH for updates (not PUT), POST for creates
5. **Immutable Models**: copyWith() for updates, proper serialization
6. **Callback Pattern**: Forms use callbacks instead of navigation returns
7. **Centralized Error Handling**: ViewModel manages all error states
8. **Cached Data Structure**: Map<siteId, List<Entity>> for efficient lookups

## Common Issues & Solutions

### Issue: "Invalid latitude/longitude"
**Solution**: Ensure values are passed as doubles, not strings in API request

### Issue: "Site not found" on update
**Solution**: Verify site ID is passed as string, not int

### Issue: Contact not created - "site_id missing"
**Solution**: The ViewModel automatically adds site_id, ensure you're using the viewModel methods not calling API directly

###Issue: "Field contact_number is required"
**Solution**: Phone number is mandatory for contacts - validate min 7 digits on frontend

### Issue: File upload failing
**Solution**: File upload requires proper file path and FormData - see AdminApiService.createSiteDocument()

## Future Enhancements

- [ ] Batch operations (multi-select delete)
- [ ] File upload UI component
- [ ] Photo/attachment support for documents
- [ ] Staff preference UI with staff list selection
- [ ] Preference mode filter (preferred/blacklisted)
- [ ] Export site as PDF/CSV
- [ ] Site templates/copy functionality
- [ ] Bulk site import
- [ ] Site archive feature
