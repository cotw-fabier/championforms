# Initial Spec Idea

## User's Initial Description
**Feature Description:**
File uploads keep a running tally of uploaded files in memory which are displayed below the file upload field. The user has found that often they don't wish to retain uploads between uploads.

**Requirements:**
- If multi-file uploads are enabled: clear all previously uploaded files, then handle all files which have been dragged in or selected
- If multi-file uploads are disabled: clear all previous files, then handle only the new file
- Create a new flag called "clearOnUpload" which can be set to true to enable this behavior
- If left unset or set to false, retain the current functionality (keep running tally)

Please create the dated spec folder (YYYY-MM-DD-spec-name format) and save this raw idea. Return the spec folder path to me so I can proceed with the requirements research phase.

## Metadata
- Date Created: 2025-10-17
- Spec Name: file-upload-clear-on-upload
- Spec Path: /Users/fabier/Documents/code/championforms/agent-os/specs/2025-10-17-file-upload-clear-on-upload
