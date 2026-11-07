# Changelog

All notable changes to the **Wholesale Desk** portal will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.5.0] - 2026-11-07

### Changed & Fixed
- **Mobile View Single-Item-Per-Line & Pack-Size Legibility**:
  - Enforced strictly **1 item/card per line** (`crossAxisCount: 1`) on mobile viewports (< 600px) in `CatalogCardGrid`, eliminating cramped 2-column squeezing on smartphones.
  - Eliminated product name truncation and ellipsis clipping across mobile list and card tiles so product pack size, grammage, and volume variants (e.g., `Surf Excel Easy Wash Powder 500gm`, `Dettol 500ml`) remain 100% visible to retailers.
  - Added `84px` bottom inset padding on mobile lists and grid views to guarantee the bottom product's action controls are never occluded by the floating cart button.
  - Wrapped price row inside `Wrap` and `Expanded` to prevent horizontal overflow on narrow 360px mobile viewports.
- **Mobile Responsive Search & Filter Toolbar**:
  - Re-architected `CatalogFilterToolbar` into a responsive 2-tier layout for mobile screens: full-width search input for zero-fatigue typing, with view switcher (`List/Cards`) and stock filter chips cleanly grouped beneath.
- **Dialog Keyboard Scroll Safety**:
  - Wrapped `ProductEditDialog` and `RetailerManagementView`'s retailer dialog forms inside `SingleChildScrollView` to prevent virtual keyboard `RenderFlex` overflow errors on mobile screens.
- **Cart Bottom Sheet Polish**:
  - Replaced hardcoded width in `CartDrawer` with responsive `BoxConstraints(maxWidth: 440)`.
  - Added a subtle mobile drag indicator pill at the top of the modal bottom sheet for intuitive downward swipe dismissal.
- **Scheme Parser & 1-Tap Apply Logic Refinement**:
  - Restamped `[Apply (+N)]` action buttons exclusively to Free Goods / Volume Tier Schemes with clear purchase thresholds (e.g. `10+1`, `12+1 Free`, `20 Bags + 1 Free`, `Buy 24 Get ₹100 Off`).
  - Cash discounts, percentages, and net rates (e.g. `5% Cash Disc`, `3% Special Scheme`, `Net Rate`) are strictly rendered as static informational badges (`[ 🏷️ 5% Cash Disc ]`) with zero spurious `Apply` buttons.
- **State-Driven Scheme Micro-Copy (Hidden at Qty = 0)**:
  - Yellow micro-copy hint lines (`💡 ...`) are completely hidden by default when `qty == 0` across all views.
  - Progressive distance guidance (`💡 Add X more to get +1 Free`) renders only when active `qty > 0 && qty < threshold`, and celebratory unlocked text when threshold is reached or exceeded.
  - Non-tiered schemes (e.g. `Net Rate`, `5% Cash Disc`) omit micro-copy lines entirely.
- **Out-of-Stock (OOS) Visual Lockdown**:
  - Out-of-stock items (`in_stock: false`) completely suppress all `[Apply (+N)]` buttons and scheme micro-copy lines.
  - Metadata badges (Scheme, MOQ, Box Pack) are dimmed (`opacity: 0.45`) and actions locked with disabled `[ Out of Stock ]` badge.
  - Preserved identical fixed card heights between in-stock and out-of-stock cards in Grid view to prevent layout shift.
- **Table & Grid Density Polish**:
  - **Table View**: Cleaned Margin column to render concise emerald value chips (`+13.6%`) without redundant `Retailer Margin:` label. Side-by-side flex layout for Scheme badge and `Apply (+N)` button, keeping row height compact ($\le 64$px). Compact MOQ and Box pack layout (`MOQ: X · Box: Y`).
  - **Grid View**: Clean metadata grouping beneath scheme tag (`MOQ: X | Box: Y`), enforcing uniform card heights across all row tiles.
  - **Desktop Floating Cart Suppression**: Floating bottom-right cart bubble is automatically hidden on desktop viewports ($\ge 1024$px) in favor of the persistent top app bar cart button, retaining the floating pill exclusively on mobile/tablet screens ($< 1024$px).

## [1.4.0] - 2026-11-07

### Refactored
- **Separation of Concerns (SoC) Architectural Decoupling**:
  - **Pure Domain Model**: Decoupled `Product` from `cloud_firestore` SDK and `FieldValue.serverTimestamp()`, eliminating Firebase dependency leaks in WooCommerce mode.
  - **Dependency Injection**: Refactored `AuthProvider` and `DeskProvider` constructors to accept optional repository instances (`RepositoryManager? repository`) for testability.
  - **Centralized Formatters (`AppFormatters`)**: Created `lib/config/formatters.dart` single source of truth for Indian currency, rate formatting, percentage calculations, and carton pack representations across all UI layers.
  - **Unified Stepper (`CatalogQuantityStepper`)**: Replaced 4 duplicate stepper implementations with a single canonical component supporting `.compact`, `.fullWidth`, and `.drawer` presentation layouts.
  - **God-Widget Decomposition**: Decomposed the monolithic 1,111-line `RetailerCatalogScreen` into isolated, focused components:
    - `CatalogFilterToolbar` (search text field, brand dropdown, stock filter, view mode toggle).
    - `CatalogCardGrid` & `ProductCardTile` (isolated card grid with granular `context.select` cart listener).
    - `CatalogDataTable` (isolated high-density desktop table).
    - `CatalogMobileList` & `MobileProductListItem` (isolated mobile POS list).
  - **Granular Rebuild Optimization**: Replaced coarse-grained root `context.watch<CartProvider>()` with granular tile-level `context.select` subscriptions and localized `Consumer<CartProvider>` wrappers, preventing unnecessary full-screen re-renders on counter web sessions.


## [1.3.0] - 2026-11-07

### Added
- **1-Tap Scheme Direct Auto-Fill (`SchemeApplyPill` & `CartProvider.applyScheme`)**:
  - Automatically parses scheme trigger threshold integer ($X$) from `X+Y`, `X:Y%`, `Buy X`, and leading numeric patterns.
  - Adds 1-tap `[ Apply Scheme (+X) ]` and `[ +X Units ]` pill directly next to scheme badges on both Cards and Table rows.
  - Tapping immediately jumps item quantity to the exact qualifying threshold or increments by full slabs without intermediate step clicks.
- **Direct Item Deletion & Zero-Reset (`✕` Tap Targets)**:
  - Added direct 1-tap delete targets (`✕` icon) next to steppers in Table View, Grid Cards, Mobile List, and Cart Drawer.
  - Any quantity (e.g. 50 units) can be zeroed out instantly in 1 tap, clearing scheme badges and restoring the `[Add to Cart]` button.
  - Stepper minus button supports long-press to zero and drops to 0 when stepping down from MOQ / 1.
- **Progressive Scheme Distance Micro-Copy**:
  - Distance micro-copy updates dynamically with each quantity change:
    - Below threshold: `Add N more to unlock +Y Free Unit(s)`
    - Threshold reached: `✓ Active Scheme: X + Y Free Applied` (high-contrast emerald styling)
    - Multiples calculated: `✓ Active Scheme: 20 + 2 Free Applied` for $2\times$ slabs.
- **Dynamic Margin & Effective Unit Rate Boost (`MarginBoostBadge`)**:
  - Computes `Effective Unit Cost = (Billed Qty * PTR) / Total Units Received`.
  - Calculates boosted retailer margin when a scheme is active: `Margin: 12.6% → 17.1% (Eff: ₹395.0/u)`.
- **WhatsApp B2B Order Bonus Itemization**:
  - WhatsApp order string compilation itemizes billed units, free scheme bonus units (`🎁 Bonus: +2 Free Units (Total: 22u)`), effective rate, and total line PTR.
- **Unit Test Coverage**:
  - Expanded `test/scheme_and_moq_test.dart` to 21 automated tests covering threshold extraction, 1-tap auto-fill, direct zero-reset, effective margin math, and WhatsApp string formatting.


## [1.2.0] - 2026-11-07

### Added
- **Floating Action Cart Button**:
  - Persistent, high-visibility floating action cart button (`FloatingActionButton.extended`) displaying live item count and running total.
- **Distributor MOQ Toggle (`enforceMoq`)**:
  - Added "Enforce MOQ on Orders" toggle switch in Distributor Store Settings.
  - When disabled by the distributor, retailers can order starting from 1 unit regardless of individual product MOQ values.
- **Real-Time Scheme Upselling Nudges (`SchemeHelper`)**:
  - Domain parser and nudge engine that analyzes B2B schemes (`6+1`, `10+1`, `12+2`, `5% CD`) against cart quantities.
  - Generates live contextual prompts (e.g., `"Add 1 more to get 1 FREE!"`, `"🎉 Qualified for 1 FREE item!"`).
  - Added `SchemeNudgePill` widget displaying nudges in both the product catalog and the cart drawer.
- **View Mode Switcher & Letter Monogram Avatars**:
  - Retailers can toggle between **Thumbnail Cards (Grid)** and **High-Density List/Table View**.
  - Integrated `ProductAvatar` zero-overhead letter monogram avatars with deterministic palette selection based on brand/product name hash.
- **Enhanced Add to Cart Button**:
  - Replaced compact "Add (MOQ)" label with a prominent, touch-friendly `[Add to Cart]` button with icon.
- **Test Suite**:
  - Added `test/scheme_and_moq_test.dart` covering scheme nudge parsing, boundary conditions, and MOQ relaxation.

### Changed
- **Removed MRP Strikethrough**: Removed `TextDecoration.lineThrough` from all retailer catalog views, grid cards, and cart drawers for clean, standard Indian wholesale price presentation.


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

