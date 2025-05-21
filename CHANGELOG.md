# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2025-05-21

### Added
- Added support for Pi-hole v6's embedded web server and REST API
- Added detailed server information display (IP and location)
- Added loading states and better UI feedback
- Added automatic message dismissal for alerts
- Added proper Bootstrap 5 classes for better responsiveness

### Changed
- Updated web interface integration to use Pi-hole v6's widget system
- Updated API to use Pi-hole v6's embedded REST API
- Updated database schema to store more detailed speedtest information
- Modernized JavaScript to use Fetch API
- Updated UI components to match Pi-hole v6 design
- Improved error handling and user feedback

### Fixed
- Fixed database ownership for Pi-hole v6
- Fixed API endpoint integration
- Fixed widget styling to match Pi-hole v6
- Fixed permission issues with database files

## [2.1.3] - 2024-03-25

### Added
- Added rollback mechanism for failed installations
- Added verification steps for insertion points
- Added separate settings page for speedtest configuration

### Changed
- Improved installation reliability with better error handling
- Updated web interface integration to prevent duplicate elements
- Enhanced logging and user feedback during installation

### Fixed
- Fixed multiple widget appearance issue
- Fixed settings page integration
- Fixed installation rollback process

## [2.1.2] - 2024-03-25

### Added
- Added uninstall script for clean removal of the mod
- Added better error handling during uninstallation
- Added automatic cleanup of all mod files and configurations

### Changed
- Improved script insertion points for Pi-hole 6's web interface
- Enhanced error messages and user feedback
- Updated installation and uninstallation documentation

### Fixed
- Fixed widget removal during uninstallation
- Fixed script reference cleanup in index.lp
- Fixed database directory cleanup

## [2.1.1] - 2024-03-25

### Changed
- Updated installation script to better handle Pi-hole 6's `.lp` files
- Improved script insertion points to match Pi-hole 6's web interface structure
- Added proper handling of Lua template syntax in script tags
- Updated widget placement to match Pi-hole 6's dashboard layout
- Added loading overlay spinner to speedtest widget
- Improved error handling and user feedback during installation
- Added support for Pi-hole 6's file versioning system

### Fixed
- Fixed script insertion issues with Pi-hole 6's web interface
- Fixed widget styling to match Pi-hole 6's design
- Fixed file permission issues during installation
- Fixed script path handling for Pi-hole 6

### Added
- Added support for Pi-hole 6's embedded web server
- Added better error messages for installation failures
- Added manual intervention instructions when automatic installation fails

## [2.1.0] - 2024-03-24

### Changed
- Updated version number to reflect Pi-hole 6 compatibility
- Updated installation script to handle Pi-hole 6's file structure
- Improved error handling in installation script

### Fixed
- Fixed compatibility issues with Pi-hole 6
- Fixed file path handling in installation script

## [2.0.0] - 2024-03-21

### Added
- Initial release of Pi-hole 6 Speedtest Mod
- Added speedtest functionality to Pi-hole web interface
- Added speedtest results visualization
- Added speedtest settings to Pi-hole dashboard
- Added automatic speedtest scheduling
- Added speedtest history tracking

### Changed
- Updated for Pi-hole 6 compatibility
- Improved installation process
- Enhanced error handling

### Fixed
- Fixed various installation issues
- Fixed file permission problems
- Fixed script loading issues

### Removed
- Removed support for older Pi-hole versions
- Removed deprecated features

## [1.0.0] - 2024-03-20
- Initial release 