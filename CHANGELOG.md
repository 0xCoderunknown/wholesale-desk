# Changelog

All notable changes to the **Wholesale Desk** portal will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-11-07

### Added
- **Dual-Backend Provider Architecture**:
  - Introduced `WholesaleRepository` abstract contract to unify backend interactions.
  - Added `WooCommerceRestService` providing direct client integration with WordPress WooCommerce REST API (`/wp-json/swac/v1/`).
  - Added `RepositoryManager` singleton to switch between Firebase Cloud Firestore and WooCommerce on the fly without changing UI state.
- **Human-Configurable Root File (`config.json`)**:
  - Placed human-editable `config.json` at root to configure store identity, WhatsApp dispatch number, PINs, and Firebase Web keys without modifying code.
  - Added `AppConfig` service to load and apply `config.json` before app rendering.
- **Carton Pack / Box Size (`box_size` / `carton_pack`)**:
  - Added `cartonPack` field to `Product` model, serializing to both `carton_pack` and `box_size`.
  - Added `BoxPackBadge` widget (`📦 Box: 24`) in distributor desk and retailer catalog.
  - Added optional carton pack input in `ProductEditDialog`.
  - Updated `WhatsAppService` to format and embed carton packing metrics in generated order strings.
- **Retailer Self-Registration CTA**:
  - Added "Apply for Retailer Account via WhatsApp" button on the retailer PIN authentication tab.
- **Test Suites**:
  - Added `test/app_config_test.dart` for root configuration parsing and fallback handling.
  - Added `test/woocommerce_integration_test.dart` for WooCommerce payload parsing, carton packing, and backend switching.

### Changed
- Refactored `AuthProvider` and `DeskProvider` to delegate all data operations to `RepositoryManager`.
- Updated `StoreSettingsDialog` with an active backend selector (Firebase vs WordPress WooCommerce REST) and WordPress site URL configuration.
- Enhanced `README.md` and `AGENTS.md` with dual-backend documentation and root configuration standards.

---

## [1.0.0] - 2026-11-07

### Added
- **Initial Release of Wholesale Desk** (Flutter Web + Firebase).
- **High-Speed Counter & POS Layout**:
  - High-density desktop data table and touch-optimized mobile list.
  - Zero image overhead in catalog for sub-millisecond scanning speed.
- **Strict Binary Stock Model**:
  - `in_stock: true | false` model where customer orders never decrement inventory counts.
  - In-place Green/Red stock toggle pills for instant database updates without a "Save" button.
- **3-Tier Role Guarding via 4-Digit PIN**:
  - **Admin (Master PIN `5075`)**: Full Distributor Desk access (product CRUD, rates/schemes/MOQ edits, retailer PIN management, store settings).
  - **Staff (Staff PIN `1122`)**: Restricted counter assistant; permitted only to toggle stock and search items.
  - **Retailer (Mobile + 4-Digit PIN)**: Authenticated catalog view with route badge, MOQ steppers, and slide-out cart drawer.
- **WhatsApp B2B Checkout**:
  - Pure Dart order serialization compiling itemized B2B purchase orders directly into `https://wa.me/{phone}?text=...`.
- **Database & Offline Fallback**:
  - Cloud Firestore integration (`/settings/general`, `/retailers`, `/products`) with seamless in-memory offline fallback for zero-setup demo testing.

