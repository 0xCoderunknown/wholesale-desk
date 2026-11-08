# Changelog

All notable changes to the **Wholesale Desk** portal will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.8.0] - 2026-11-08

### Added
- **Field Salesman Role (`UserRole.salesman`)**: Dedicated in-memory ordering mode for field order bookers (PIN: `3344` configurable in Store Settings). Reuses the high-density retailer catalog with instantaneous shop switching and zero backend bloat.
- **Sticky 44px Salesman Route Bar (`SalesmanRouteBar`)**:
  - Embedded beneath the AppBar in salesman mode with a Route filter dropdown (`📍 All Routes` or specific beats) and 1-tap Shop selector bottom sheet.
  - Sub-millisecond in-memory search across store name, phone, and route.
- **Cart Isolation Guard & Dynamic Route Synchronization**:
  - Tapping a new shop switches immediately when the cart is empty.
  - When the cart contains items, prompts confirmation (`"Switch Active Shop? Active Cart has items for [Shop Name]"`) to prevent cross-retailer order contamination.
  - Changing the route dropdown dynamically switches the active retailer to the first shop on the new route (with Cart Isolation Guard protection if cart has items) to prevent route-shop desynchronization.
  - Shop picker selection synchronizes the route bar filter bidirectionally.
- **Mobile Warehouse Staff Card Optimization**: Compacted warehouse mobile staff card to a single horizontal action row featuring the interactive Box Pack Badge / Calculator and Stock Toggle Pill side-by-side, maximizing vertical scanning density.
- **Salesman Order Watermark**: Compiles `Booked by: Salesman Name (Salesman)` into the WhatsApp order header line 3, while preserving clean direct order formatting for self-ordering retailers.
- **WooCommerce Dual-Backend Parity**:
  - Whitelisted `X-SWAC-Master-Token` and `X-SWAC-Retailer-Token` in WordPress `rest_allowed_cors_headers` to resolve cross-origin preflight (`OPTIONS`) blocks on Flutter Web.
  - Broadened `/desk/products` catalog authorization to validate Retailer HMAC tokens alongside Master, Staff, and Salesman tokens.
  - Added Salesman PIN (`3344`) authentication support to WordPress `/desk/auth`.
  - Added `moq` and `scheme_shorthand` parsing in `create-product.php` to prevent data loss when adding items from Admin Desk.
  - Retained retailer session tokens upon login and role-guarded `/desk/settings` calls to prevent 403 authorization locks.

---

## [1.7.0] - 2026-11-08

### Added
- **Retailer Profile & ERP Ledger Guardrails**: Added read-only `RetailerProfileDialog` displaying immutable party ledger credentials (Store Name, Party Code, Assigned Route, Registered Phone) with `🔒 Managed by Distributor ERP` lock indicator, distributor dispute contact footer, and `[ Sign Out / Switch Store ]` counter session handoff.
- **WhatsApp Order Identity Watermark**: Strict 2-line header in `WhatsAppService.buildOrderMessage` embedding a 4-character reference hash (`Ref: #XXXX`) and registered phone (`Reg: XXXXXXXXXX`) without emoji clutter for instant ERP ledger matching.
- **Order Text Clipboard Fallback**: Added a secondary `[ 📋 Copy ]` button adjacent to the WhatsApp CTA across mobile sticky bar and desktop valuation dock, enabling instant copy-paste fallback for desktop or web environments.
- **Compressed WhatsApp Order Payload**: Ultra-compact, clean plaintext format (`*ORDER: Store (Route)*`, itemized lines with `@ PTR = ₹Total`, and summary grand totals) preventing URL query string truncation on large multi-item orders.
- **1-Tap Scheme Undo ([REMOVE])**: Applied schemes in catalog listings can be reversed in 1 tap with the red `[REMOVE]` button, restoring base quantities or clearing the lot.
- **Quick-Buy 1 Box Action in Desktop Table**: Added adjacent `[1 Box (N)]` quick-add button in the desktop catalog table for instant carton ordering.

### Changed
- **Enterprise Desktop Cart Redesign (≥ 1024px)**:
  - Main container set to enterprise `max-width: 1240px` centered with `margin: 32px auto`.
  - 2-Column split with 28px gap: ~70% scrollable Proforma Invoice Table and ~30% pinned/sticky Order Valuation Dock.
  - Removed redundant `"PTR:"` and `"Line:"` prefixes from table columns; displays clean, bold currency figures (`₹285.00` and `₹3,420.00`).
  - Formatted product column with title breathing on top line and secondary metadata (`Brand · Box: N`) beneath.
- **Mobile Cart Polish (< 768px)**:
  - Eliminated inner duplicate WhatsApp CTA in the valuation card; sticky bottom bar is now the sole checkout button.
  - Enclosed red trash delete button in a 40x40px minimum touch target.
  - Tightened card vertical margins to 6px and configured 90px bottom scroll padding for safe clearance above the sticky footer.
  - Single-line identity subheader (`Ordering for: Store · Route`) beneath minimal app bar.

### Fixed
- **Double Checkmark Bug**: Resolved duplicate checkmark symbols in scheme unlocked status banners.
- **Stepper Drawer Layout**: Replaced unbounded textfield intrinsic width in drawer steppers with fixed sizing, eliminating horizontal RenderFlex layout overflows.

---

## [1.6.0] - 2026-11-07

### Added
- **Dynamic Green Scheme Recalculation**: Live effective PTR and boosted margin pills transition directly to new values in vibrant emerald green without cluttering strikethroughs when volume thresholds are met.
- **1-Tap Carton Quick-Buy**: Dedicated `[ Buy 1 Box (N) ]` action pill adjacent to the cart stepper to instantly order full box quantities.
- **Collapsible Tiered Scheme Accordion**: Clean Shikhar-style collapsible deal drawer for volume/tiered schemes (`X+Y`, `Buy X Get ₹Y Off`) displaying direct deal rules and 1-tap slab increments.
- **Single-Row Mobile Search & Filter**: Consolidated search input and stock filter into a compact, space-saving 48px header row on mobile viewports (< 768px).

### Changed
- **Unified Price Bar Layout**: Standardized all product listings to the wholesale format `[₹MRP  [MARGIN: XYZ%]  ₹PTR]` where MRP and PTR share identical font size (`14.5px`) and neutral color, with PTR dynamically transitioning to vibrant emerald green when its value changes.
- **In-Place Stepper Replacement**: When added to cart, the quantity stepper and 1-tap delete (`✕`) replace the `[Add to Cart]` button in-place without causing price row layout shifts.
- **Contextual Single Cart Button**: Exclusively shows the floating cart button on mobile screens (< 768px) and top app bar cart button on desktop/tablet (≥ 768px).
- **Mobile-Locked Single Column**: Retailer catalog on mobile is locked to a clean single-column list with full product packaging visibility; view switcher (Table/Grid) is restricted to desktop and tablet.

### Removed
- **Redundant Card Elements**: Removed duplicate `[In Stock]` badges from product card headers and redundant price/margin text across scheme drawers to eliminate repetitive clutter on mobile screens.

---

## [1.5.0] - 2026-11-07

### Added
- **Progressive Scheme Guidance**: Real-time contextual distance cues (`Add X more to get +1 Free`) when cart quantity approaches a deal threshold.

### Changed
- **Mobile Packing Legibility**: Ensured full display of end-of-title pack sizes and variants (e.g. `500gm`, `100ml`) across mobile listings without text truncation.
- **Scheme Action Gating**: 1-tap apply actions are strictly gated to tiered/volume schemes; flat percentage and net-rate discounts render as clean static info tags.
- **Out-of-Stock Visual Lockdown**: Out-of-stock items disable scheme actions, dim metadata badges, and present a locked `[Out of Stock]` indicator.

---

## [1.4.0] - 2026-11-07

### Refactored
- **Domain & UI Architectural Decoupling**:
  - Decoupled `Product` and core domain models from Firestore SDK dependencies for seamless dual-backend support.
  - Decomposed monolithic catalog screens into focused, reusable components (`CatalogFilterToolbar`, `CatalogDataTable`, `CatalogMobileList`, `ProductCardTile`).
  - Optimized Provider state subscriptions with granular selectors (`context.select`) to eliminate unnecessary full-screen re-renders on counter web sessions.
  - Centralized Indian currency and rate formatting under `AppFormatters`.

---

## [1.3.0] - 2026-11-07

### Added
- **1-Tap Scheme Auto-Fill**: Instant threshold fill (`[Apply Scheme (+N)]`) for tiered and free-goods schemes without manual stepping.
- **Direct 1-Tap Item Zero-Reset**: Dedicated `✕` delete button next to quantity steppers to immediately clear an item from the cart.
- **Dynamic Retailer Margin Math**: Domain engine calculating effective unit rates and boosted margins for active schemes.
- **WhatsApp B2B Bonus Itemization**: Automatically formats and itemizes free bonus units and carton metrics into dispatchable WhatsApp order text.

---

## [1.2.0] - 2026-11-07

### Added
- **Floating Cart Pill**: High-visibility floating cart action button displaying live item counts and running order totals.
- **Configurable MOQ Enforcement**: Distributor toggle in store settings allowing optional relaxation of minimum order quantities.
- **Deterministic Letter Monograms**: Lightweight avatar generator providing instant visual brand recognition without image download overhead.

### Changed
- **Wholesale Price Typography**: Cleaned price displays by eliminating strikethrough decorations in favor of clear wholesale PTR/MRP presentation.

---

## [1.1.0] - 2026-11-07

### Added
- **Dual-Backend Architecture**: Seamless switching between Cloud Firestore and WordPress WooCommerce REST API (`/wp-json/swac/v1/`) via `WholesaleRepository`.
- **Root Configuration (`config.json`)**: Human-editable configuration file for store branding, WhatsApp dispatch numbers, and PIN credentials.
- **Carton Pack Support**: Added box size metrics (`carton_pack` / `box_size`) across product models, editing dialogs, and WhatsApp order summaries.
- **Retailer WhatsApp Self-Registration**: Quick CTA for new retail shops to request portal access directly via WhatsApp.

---

## [1.0.0] - 2026-11-07

### Added
- **Initial Release of Wholesale Desk**:
  - High-speed B2B counter & POS web portal built with Flutter Web.
  - Zero image overhead for sub-millisecond catalog browsing and search.
  - Strict binary stock model (`in_stock: true | false`) with instant in-place toggle pills.
  - 3-tier PIN authentication (Admin Master PIN, Staff Counter PIN, Retailer Mobile + PIN).
  - WhatsApp B2B checkout with zero-gateway overhead.
  - Cloud Firestore integration with offline in-memory fallback.
