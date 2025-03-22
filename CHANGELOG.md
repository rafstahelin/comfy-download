# Changelog

## v1.6.0 - 2025-03-22

### Added
- Custom node data synchronization for:
  - `/workspace/comfy-data/milehighstyler` ↔ `dbx:/studio/ai/libs/comfy-data/milehighstyler`
  - `/workspace/comfy-data/plushparameters` ↔ `dbx:/studio/ai/libs/comfy-data/plushparameters`
  - `/workspace/comfy-data/plushprompts` ↔ `dbx:/studio/ai/libs/comfy-data/plushprompts`
- Custom node configuration management for:
  - Plush-for-ComfyUI text_file_dirs.json configuration
  - ComfyUI-Easy-Use styles symlink
- New commands: `dl customsync`, `dl cs`, `dl checkconfig`, `dl cc`
- Enhanced status reporting for custom node data

### Changed
- Updated `setup.sh` to create custom node data directories
- Enhanced `dl status` and `dl report` commands with custom sync information

## v1.5.0 - 2025-03-01

### Changed
- Separated from Easy repository for independent installation and management

## v1.4.0 - 2025-02-15

### Changed
- Replaced hyphenated commands with space-separated commands for improved usability

## v1.3.0 - 2025-02-01

### Added
- Bidirectional sync of templates, settings, and workflows with Dropbox

## v1.2.0 - 2025-01-15

### Added
- Automatic backup of ComfyUI user settings to Dropbox

## v1.1.0 - 2025-01-01

### Added
- Integration with Easy system
- Improved aliasing

## v1.0.0 - 2024-12-15

### Added
- Initial release with basic download functionality