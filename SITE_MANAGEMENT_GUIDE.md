## Site Management CRUD - Complete Integration Guide

### Overview
This document outlines the complete Site Management CRUD implementation for the Guard House system with proper integration between Flutter frontend and Laravel backend.

### Architecture Layers

#### 1. **Models Layer** (`lib/models/site_models.dart`)
Updated models with proper naming conventions matching Laravel API responses:

- **`Geofence`**: Location coordinates with check-in distance
  - Fields: `placeId`, `lat`, `lon`, `checkInDistance`
  - Maps from API snake_case fields: `place_id`, `lat`, `lon`, `check_in_distance`

- **`SiteAddress`**: Address information
  - Fields: `name`, `city`, `state`, `zip`, `country`
  - All required for API submission

- **`SiteDetails`**: Main site information
  - Includes type, name, address, geofence, default groups, instructions
  - Maps to Laravel Site model fields

- **`SiteContact`**: Contact persons for a site
  - Fields: `firstName`, `lastName`, `position`, `email`, `contactNumber`, `notes`
  - Maps to `first_name`, `last_name`, `contact_number` in API

- **`SiteCheckpoint`**: Security checkpoints within a site
  - Fields: `name`, `geofence`, `qrCodeToken`
  - Maps to `qr_code_token` in API

- **`SitePreference`**: Staff or form preferences for a site
  - Fields: `mode` (staff-setting/form-setting), `setting` (preferred/blacklisted/enabled)

- **`SiteDocument`**: Documents associated with a site
  - Fields: `name`, `files` (list), `offsiteVisibility`
  - Maps to `offsite_visibility` in API

- **`Site`**: List view model with core site data
  - Used for site listings and dashboard

### 2. **API Service Layer** (`lib/services/admin_api_service.dart`)
New comprehensive CRUD methods added:

#### Site Management
```dart
// Get all sites
Future<List<Map<String, dynamic>>> getSites()

// Create new site
Future<bool> createSite(Map<String, dynamic> siteData)
Future<String?> createSiteAndGetId(Map<String, dynamic> siteData)

// Update site (PATCH /sites/{id})
Future<bool> updateSite(String siteId, Map<String, dynamic> siteData)

// Get site details
Future<Map<String, dynamic>?> getSiteDetails(String siteId)

// Delete site
Future<bool> deleteSite(String siteId)
```

#### Site Contacts Management
```dart
Future<List<Map<String, dynamic>>> getSiteContacts(String siteId)
Future<bool> createSiteContact(String siteId, Map<String, dynamic> contactData)
Future<bool> updateSiteContact(String siteId, String contactId, Map<String, dynamic> contactData)
Future<bool> deleteSiteContact(String siteId, String contactId)
```

#### Site Checkpoints Management
```dart
Future<List<Map<String, dynamic>>> getSiteCheckpoints(String siteId)
Future<bool> createSiteCheckpoint(String siteId, Map<String, dynamic> checkpointData)
Future<bool> updateSiteCheckpoint(String siteId, String checkpointId, Map<String, dynamic> checkpointData)
Future<bool> deleteSiteCheckpoint(String siteId, String checkpointId)
```

#### Site Preferences Management
```dart
Future<List<Map<String, dynamic>>> getSitePreferences(String siteId)
Future<bool> createSitePreference(String siteId, Map<String, dynamic> preferenceData)
Future<bool> updateSitePreference(String siteId, String preferenceId, Map<String, dynamic> preferenceData)
Future<bool> deleteSitePreference(String siteId, String preferenceId)
```

#### Site Documents Management
```dart
Future<List<Map<String, dynamic>>> getSiteDocuments(String siteId)
Future<bool> createSiteDocument(String siteId, Map<String, dynamic> documentData)
Future<bool> updateSiteDocument(String siteId, String documentId, Map<String, dynamic> documentData)
Future<bool> deleteSiteDocument(String siteId, String documentId)
```

**Note**: All methods use proper HTTP verbs:
- POST for create endpoints
- PATCH for update endpoints (not PUT)
- DELETE for delete endpoints

### 3. **ViewModel Layer** (`lib/viewmodels/site_management_viewmodel.dart`)

`SiteManagementViewModel` handles all business logic with proper error management:

```dart
// Site operations
Future<void> loadSites()
Future<bool> createSite(Map<String, dynamic> siteData)
Future<bool> updateSite(String siteId, Map<String, dynamic> siteData)
Future<bool> deleteSite(String siteId)

// Contact operations
Future<void> loadSiteContacts(String siteId)
Future<bool> createSiteContact(String siteId, Map<String, dynamic> contactData)
Future<bool> updateSiteContact(String siteId, String contactId, Map<String, dynamic> contactData)
Future<bool> deleteSiteContact(String siteId, String contactId)

// Checkpoint operations
Future<void> loadSiteCheckpoints(String siteId)
Future<bool> createSiteCheckpoint(String siteId, Map<String, dynamic> checkpointData)
// ... similar update/delete methods

// Preference operations
// Document operations
// (Similar structure for preferences and documents)
```

**Error Handling**: All methods set `_errorMessage` on failure and normalize loading states.

### 4. **UI Components** (`lib/widgets/`)

#### Form Validators and Main Form
**File**: `site_details_form.dart`

Includes:
- **`SiteFormValidator`**: Static validation methods matching backend rules
  - `validateSiteName()`: 1-100 characters required
  - `validateAddress/City/State/Zip/Country()`: Required fields
  - `validateLatitude()`: -90 to 90
  - `validateLongitude()`: -180 to 180
  - `validateDistance()`: Must be positive integer
  - `validateEmail()`: Valid email format (optional)
  - `validatePhoneNumber()`: Minimum 7 digits required
  - `validateFirstName/LastName()`: 1-50 characters
  - `validatePosition()`: 1-50 characters
  - `validateCheckpointName()`: 1-50 characters
  - `validateDocumentName()`: 1-50 characters

- **`SiteDetailsForm`**: Full form for site creation/editing
  - Takes `SiteDetails` initial data
  - Returns callback with updated `SiteDetails`
  - Includes dropdowns for service groups, pay groups, customers
  - Proper geofence and address input validation

#### Related Entity Forms
**File**: `site_form_components.dart`

- **`SiteContactForm`**: Create/edit contact form
  - First/Last name, position, email, phone, notes
  - Callback returns `SiteContact`

- **`SiteCheckpointForm`**: Create/edit checkpoint form
  - Name, location (lat/lon), QR code token
  - Callback returns `SiteCheckpoint`

- **`SiteDocumentForm`**: Create/edit document form
  - Document name, file list, offsite visibility toggle
  - Callback returns `SiteDocument`

### 5. **Detail Screen** (`lib/views/admin/site_detail_screen.dart`)

Comprehensive tabbed interface for managing single site:

**Tabs**:
1. **Details Tab**: View/edit main site information
2. **Contacts Tab**: CRUD operations for site contacts
3. **Checkpoints Tab**: CRUD operations for checkpoints
4. **Documents Tab**: CRUD operations for documents

**Features**:
- Loads all related data on init
- Each tab has Add button for creating new items
- List tiles with edit/delete options
- Confirmation dialogs for deletions
- Success/error snackbars
- Proper loading states

### Error Handling & Validation

#### Backend Validation Rules (from Laravel)
All validations must match backend expectations:

**Site Creation (store)**:
```php
'type' => 'required|in:static,mobile-patrol',
'customer_profile_id' => 'nullable|exists:customer_profiles,id',
'name' => 'required|string|max:100',
'geofence' => ['required', new GeofenceRule()],
'address' => ['required', new AddressRule()],
'default_pay_group_id' => 'nullable|exists:pay_groups,id',
'default_service_group_id' => 'nullable|exists:service_groups,id',
'custom_clockin_questionnaire' => 'nullable|array',
'instructions' => 'nullable|string',
```

**Site Update (update)**:
```php
'type' => 'nullable|in:static,mobile-patrol',
// ... all other fields nullable
```

**Site Contact**:
```php
'site_id' => 'required|exists:sites,id',
'first_name' => 'required|string|max:50',
'last_name' => 'required|string|max:50',
'email' => 'nullable|email|max:30',
'contact_number' => 'required|string|max:30',  // Note: required phone
'position' => 'required|string|max:50',
'notes' => 'nullable|string',
```

**Site Checkpoint**:
```php
'site_id' => 'required|exists:sites,id',
'name' => 'required|string|max:50',
'geofence' => ['required', new GeofenceRule()],
'qr_code_token' => 'required|string|max:255',
```

### API Endpoints Reference

```
GET    /api/sites                          -> List all sites
POST   /api/sites                          -> Create site
PATCH  /api/sites/{id}                     -> Update site
DELETE /api/sites/{id}                     -> Delete site

GET    /api/sites/{siteId}/contacts        -> List contacts
POST   /api/sites/{siteId}/contacts        -> Create contact
PATCH  /api/sites/{siteId}/contacts/{id}   -> Update contact
DELETE /api/sites/{siteId}/contacts/{id}   -> Delete contact

GET    /api/sites/{siteId}/checkpoints     -> List checkpoints
POST   /api/sites/{siteId}/checkpoints     -> Create checkpoint
PATCH  /api/sites/{siteId}/checkpoints/{id} -> Update checkpoint
DELETE /api/sites/{siteId}/checkpoints/{id} -> Delete checkpoint

GET    /api/sites/{siteId}/preferences     -> List preferences
POST   /api/sites/{siteId}/preferences     -> Create preference
PATCH  /api/sites/{siteId}/preferences/{id} -> Update preference
DELETE /api/sites/{siteId}/preferences/{id} -> Delete preference

GET    /api/sites/{siteId}/documents       -> List documents
POST   /api/sites/{siteId}/documents       -> Create document
PATCH  /api/sites/{siteId}/documents/{id}  -> Update document
DELETE /api/sites/{siteId}/documents/{id}  -> Delete document
```

### Integration Steps

#### 1. Provider Setup (main.dart or app_providers.dart)
```dart
ChangeNotifierProvider(
  create: (context) => SiteManagementViewModel(
    context.read<AdminApiService>(),
  ),
),
```

#### 2. Route Configuration (routes/routes.dart)
```dart
GoRoute(
  path: 'sites/:siteId',
  builder: (context, state) => SiteDetailScreen(
    siteId: state.pathParameters['siteId']!,
  ),
),
```

#### 3. Using in Screens
```dart
Consumer<SiteManagementViewModel>(
  builder: (context, viewModel, _) {
    // Use viewModel methods
    await viewModel.loadSites();
    await viewModel.createSite(siteData);
    // etc.
  },
)
```

### Important Notes

1. **Field Name Mapping**: API uses snake_case but Dart models use camelCase
   - Models' toJson() must convert to snake_case
   - Models' fromJson() must handle both formats

2. **Geofence Field Names**:
   - API expects: `place_id`, `lat`, `lon`, `check_in_distance`
   - Models use: `placeId`, `lat`, `lon`, `checkInDistance`

3. **Upload Handling**: SiteDocument creation uses FormData for file uploads
   - Implementation in AdminApiService handles MultipartFile conversion
   - Actual file picker UI needs to be implemented separately

4. **Validation Priority**:
   - Frontend MUST validate before submission
   - Error messages should match backend constraint descriptions
   - Phone numbers are required for contacts

5. **State Management**:
   - ViewModel maintains loading state globally
   - Each entity type has its own Map for caching
   - Clearing happens automatically on deletions

### Testing Checklist

- [ ] Create site with all required fields
- [ ] Update site with partial fields
- [ ] Delete site with confirmation
- [ ] Add contact with all validations
- [ ] Edit contact preserving ID
- [ ] Delete contact
- [ ] Create checkpoint with geofence validation
- [ ] Update checkpoint location
- [ ] Add document with multiple files
- [ ] Verify all error messages display correctly
- [ ] Verify all snackbar notifications appear
- [ ] Test loading states during operations
- [ ] Verify API calls use correct HTTP verbs (PATCH not PUT)
- [ ] Test field name mapping (camelCase in Dart, snake_case in API)
