# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Density measurement class** with comprehensive unit support
  - Metric units: gram_per_milliliter, kilogram_per_liter, gram_per_cubic_centimeter, kilogram_per_cubic_meter
  - Imperial units: pound_per_gallon, pound_per_cubic_foot, ounce_per_cubic_inch
  - Full arithmetic, comparison, and serialization support
- **Weight ↔ Volume conversion methods** using density
  - `weight.to_volume(density)` and `weight.to_volume(value, unit)` overloads
  - `volume.to_weight(density)` and `volume.to_weight(value, unit)` overloads
  - Explicit naming aliases: `volume_given()` and `weight_given()`
- **Density string parsing** support for formats like "1.0 g/mL" and "62.4 lb/ft³"
- **Density numeric extensions** for convenient syntax like `1.42.g_per_ml`
- **Comprehensive test suite** with integration tests for density conversions
- **Updated documentation** with density conversion examples and scientific applications

## [0.1.0] - 2025-10-14

### Added
- Numeric extensions for convenient measurement creation
- Initial project structure and setup

### Fixed
- Add missing newline at end of postgres_spec.cr
- Fix test suite issues
- Fix all ameba linting issues (143 → 0 failures)

### Changed
- Move repository to ButterbaseApp organization
- Enhance documentation and update README.md
- Code formatting improvements

### Removed
- Remove cursor and taskmaster configuration files
- Ignore TODOs in ameba linting

[Unreleased]: https://github.com/ButterbaseApp/unit/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ButterbaseApp/unit/releases/tag/v0.1.0