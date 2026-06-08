# Development Workflow for Site Creation Steps

This document explains how to use the enhanced development workflow for working on individual site creation wizard steps.

## Hot Reload Navigation Support

The app now supports staying on specific wizard steps during hot reload, making development much easier when working on individual steps.

### How to Use

1. **Edit `main.dart`**: Open `lib/main.dart` and find the `_kDevInitialRoute` constant at the top of the file.

2. **Set Your Development Route**: Uncomment and modify one of the example routes:

```dart
// For the main site creation wizard (step 1):
const String? _kDevInitialRoute = Routes.adminSiteWizard;

// For specific steps (direct access):
const String? _kDevInitialRoute = '/dev/site-wizard/staff-preferences';
const String? _kDevInitialRoute = '/dev/site-wizard/contacts';  
const String? _kDevInitialRoute = '/dev/site-wizard/checkpoints';
```

3. **Hot Reload**: After setting your route, hot reload the app and it will open directly to your chosen step.

4. **Development**: Make changes to your step files and hot reload - you'll stay on the same step!

5. **Reset**: Set `_kDevInitialRoute` back to `null` when you're done developing.

## Available Development Routes

| Route | Step | File |
|-------|------|------|
| `/dev/site-wizard/details` | Site Details | `lib/views/admin/steps/site_details_step.dart` |
| `/dev/site-wizard/contacts` | Site Contacts | `lib/views/admin/steps/site_contacts_step.dart` |
| `/dev/site-wizard/staff-preferences` | Staff Preferences | `lib/views/admin/steps/site_staff_preferences_step.dart` |
| `/dev/site-wizard/instructions` | Instructions | `lib/views/admin/steps/site_instructions_step.dart` |
| `/dev/site-wizard/checkpoints` | Checkpoints | `lib/views/admin/steps/site_checkpoints_step.dart` |
| `/dev/site-wizard/incident-reports` | Incident Reports | `lib/views/admin/steps/site_incident_reports_step.dart` |
| `/dev/site-wizard/clock-in-questionnaires` | Clock-in Questionnaires | `lib/views/admin/steps/site_clock_in_questionnaires_step.dart` |
| `/dev/site-wizard/documents` | Documents | `lib/views/admin/steps/site_documents_step.dart` |
| `/dev/site-wizard/access-codes` | Access Codes | `lib/views/admin/steps/site_access_codes_step.dart` |

## Features

- **Full wizard navigation**: Even when starting on a specific step, you can still navigate forward/backward through all steps
- **State persistence**: The wizard maintains all your form data when navigating between steps
- **Provider context**: All Provider services (AdminViewModel, etc.) are available
- **Debug only**: Development routes only work in debug mode for security

## Tips

1. Use this workflow when working on individual step UI/UX improvements
2. Perfect for testing form validations on specific steps  
3. Great for screenshot/testing specific step layouts
4. Remember to reset `_kDevInitialRoute` to `null` before committing code

## Normal Navigation

When `_kDevInitialRoute` is `null`, the app follows normal navigation:
- Login screen → Admin Dashboard → Site Management → Site Creation Wizard

This maintains the production navigation flow while allowing development shortcuts when needed.