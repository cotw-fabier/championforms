# Initial Spec Idea

## User's Initial Description
We recently updated the field registration setup to allow custom fields on top of ChampionForms. Now we need to develop an API for expanding this registration process to support compound fields.

Compound fields are composite fields made up of multiple sub-fields. For example:
- An "address" field with ID "address" would contain sub-fields like:
  - "address_street"
  - "address_street2"
  - "address_city"
  - "address_state"
  - "address_zip"
  - etc.

The compound field would:
- Handle custom layouts for the collection of text fields
- Support validation on individual sub-fields
- Provide an idiomatic registration process on top of our current FormFieldRegistry setup
- Make it quick and easy to declare and register these compound fields with the controller

## Metadata
- Date Created: 2025-11-13
- Spec Name: compound-field-registration-api
- Spec Path: agent-os/specs/2025-11-13-compound-field-registration-api
