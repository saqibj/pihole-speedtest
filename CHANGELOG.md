# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.2] - 2024-03-25

### Changed
- Added more script insertion points for Pi-hole 6's .lp files
- Improved script insertion error handling
- Enhanced manual intervention guidance

### Fixed
- Script insertion failures in Pi-hole 6's web interface
- Added support for more common script locations in .lp files
- Better handling of file modification failures

### Added
- Manual script insertion instructions when automatic insertion fails
- Support for additional script insertion points:
  - `<!-- Footer -->`
  - `<script src="scripts/pi-hole/js/"`
  - `<script src="scripts/pi-hole/js/scripts.js"`

## [2.1.1] - 2024-03-24

### Changed
- Improved error handling and reporting during installation
- Added detailed error messages for each installation step
- Enhanced installation success/failure feedback
- Added proper error tracking and reporting system

### Fixed
- Installation script now properly reports failures
- Success message only shows when installation is truly successful
- Better handling of file modification failures
- More accurate error reporting for file operations

## [2.1.0] - 2024-03-24

### Added
- Automatic web interface directory detection
- Support for multiple Pi-hole web interface locations
- Flexible file detection for index and settings files
- Better error handling and user feedback during installation

### Changed
- Improved installation script robustness
- Enhanced error messages and warnings
- Better handling of file modifications
- More informative progress messages

### Fixed
- Installation failures on different Pi-hole web interface paths
- File permission issues during installation
- Script insertion point detection
- Web interface file modification reliability

## [2.0.0] - 2024-03-21

### Changed
- Renamed project to "PiHole 6 Speedtest" for better clarity
- Updated database directory structure to use project-specific path
- Improved error handling and permissions management
- Enhanced installation feedback and progress messages
- Updated branch structure to use `main` as default branch

### Added
- Better error handling for speedtest operations
- Improved database file permissions
- More descriptive installation progress messages
- Proper directory creation with correct permissions

### Fixed
- Database directory permissions issues
- Installation script feedback
- Branch naming consistency

### Removed
- Legacy `master` branch
- Old project naming references

## [1.0.0] - 2024-03-20
- Initial release 