// This is a backup of the correct widget structure for the problematic section
// The correct structure should be:
/*
SingleChildScrollView(
  child: Column(
    children: [
      Offstage(
        offstage: _currentTabIndex != 0,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // All form fields including timezone dropdown
              UltimateMobileDropdown<String>(
                value: _selectedTimezone,
                decoration: _inputDecoration('Choose Timezone'),
                hintText: 'Choose Timezone',
                items: _timezones
                    .map((tz) => DropdownMenuItem(
                      value: tz,
                      child: Text(tz.replaceAll('_', ' '), overflow: TextOverflow.ellipsis),
                    ))
                    .toList(),
                onChanged: (tz) => setState(() => _selectedTimezone = tz),
              ),
            ],
          ),
        ),
      ),
      Offstage(
        offstage: _currentTabIndex != 1,
        child: _notesStep(),
      ),
    ],
  ),
),
*/
