# Wholesale Desk

**High-speed B2B wholesale order-taking frontend with direct WhatsApp handoff.**

Wholesale Desk is an order-taking frontend built for FMCG, pharma, and grocery distributors in wholesale trade. It provides a fast, zero-image catalog interface for retailers, field salesmen, and counter staff to prepare structured, mathematically verified wholesale orders and hand them off directly to the distributor via WhatsApp.

[![Version](https://img.shields.io/badge/Version-1.11.0-blue)](CHANGELOG.md)
[![Platform](https://img.shields.io/badge/Platform-Flutter%20Web-teal)](#deployment--developer-setup)
[![Tests](https://img.shields.io/badge/Tests-80%20Passing-success)](test/)
[![Dual Backend](https://img.shields.io/badge/Backend-Firestore%20%7C%20WooCommerce%20REST-orange)](#dual-backend-architecture)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## What Wholesale Desk Is (and What It Is Not)

To evaluate Wholesale Desk accurately, it is important to understand its specific architectural boundaries:

- **What it is:** A focused, lightweight, client-side order-taking frontend. It allows retailers to self-order from their mobile browsers, field salesmen to book orders during shop visits, and counter staff to check availability and packing breakdowns.
- **What it is not:** Wholesale Desk is **not** billing, invoicing, accounting, or ERP software. It does not replace systems like Tally, Marg ERP, Busy, SAP, or QuickBooks. It does not generate GST e-invoices, print tax invoices, manage general ledgers, track customer outstanding balances, or process online card/UPI payment gateway settlements.
- **The End-to-End Workflow:**
  1. **Distributor Setup:** The distributor maintains wholesale rates (PTR), retail reference rates (MRP), promotional trade schemes (`X+Y` or `N%`), minimum order quantities (MOQ), and binary stock availability in Wholesale Desk.
  2. **Order Preparation:** A retailer (self-ordering) or field salesman (route booking) builds an itemized cart. Cart domain logic verifies MOQ thresholds and automatically computes free goods or percentage discounts.
  3. **WhatsApp Handoff:** On checkout, the app compiles the verified order into a clean, itemized text payload and opens it in WhatsApp via a deep link addressed to the distributor's registered WhatsApp number.
  4. **Final Billing & Invoicing:** The distributor or billing clerk receives the WhatsApp message and enters or imports the order into their separate accounting/billing software (e.g., Tally, Marg, SAP) where formal tax invoicing, payment collection, and accounting entries take place.

```
┌────────────────────────────────────────────────────────┐
│                     Wholesale Desk                     │
│  (Catalog Search · Scheme Math · Order Construction)   │
└───────────────────────────┬────────────────────────────┘
                            │
                            │ WhatsApp Deep Link (wa.me)
                            ▼
┌────────────────────────────────────────────────────────┐
│                   WhatsApp Handoff                     │
│   (Structured B2B Text Payload to Distributor Phone)   │
└───────────────────────────┬────────────────────────────┘
                            │
                            │ Manual Entry / Order Import
                            ▼
┌────────────────────────────────────────────────────────┐
│          Existing Billing / ERP System                 │
│      (Tally Prime · Marg ERP · Busy · SAP)             │
│    Tax Invoices · GST E-Way Bills · Payment Ledgers    │
└────────────────────────────────────────────────────────┘
```

---

## Try the Live Demo

A public demonstration is hosted at **[wholesale-desk-hub.web.app](https://wholesale-desk-hub.web.app)**. It is pre-loaded with sample FMCG catalog items, volume schemes, and sample routes.

The login screen provides 1-click quick-fill buttons for testing the following **demo-only credentials**:

| Role | Demo Credentials | Primary Workspace |
|---|---|---|
| **Distributor Admin (Master)** | PIN `5075` | Master catalog CRUD, rates, schemes, retailer accounts, and store settings |
| **Staff Counter (Godown)** | PIN `1122` | Client-side search, rate-shielded stock toggle, and carton breakdown calculator |
| **Field Salesman (Booker)** | PIN `3344` | Route/beat filter, client-side shop selector, cart isolation, and order watermarking |
| **Retailer Order Desk** | Mobile `9876543210` · PIN `1234` | Read-only party ledger profile, MOQ steppers, live scheme math, and WhatsApp checkout |

> **Note on Demo Credentials:** The PINs and phone number listed above are pre-configured strictly for the public evaluation demo and local development. In production deployments, distributors customize their access PINs and contact numbers via `config.json` or the Admin Settings dialog.

---

## Role Workflows & Access Control

Wholesale Desk provides four distinct operational roles designed around counter and field operations:

### 1. Distributor Admin Desk (Master PIN)
The management dashboard for distributor owners and counter managers.
- **Catalog Management:** Add, edit, or delete products with PTR (wholesale rate), MRP, carton pack size, MOQ, and scheme notation.
- **Validation Guards:** Real-time margin preview ($MRP - PTR$), validation warnings if $PTR > MRP$, and non-blocking safety warnings for unusually large quantities or percentage schemes.
- **Retailer Directory:** Register retail store accounts with party codes, route/beat assignments, phone numbers, and 4-digit PINs.
- **Configuration:** Update store name, WhatsApp destination number, and access PINs directly from the UI.
- **Backend Switching & Demo Reset:** Switch between Firestore and WooCommerce backends, or reset sample demo catalog data.

### 2. Staff Counter (Staff PIN)
Designed for godown workers or junior counter assistants who check stock and pack items.
- **Rate & Margin Shielding:** PTR (wholesale rates), retailer margins, and backend configuration are hidden from the staff interface to prevent unauthorized rate exposure.
- **Stock Toggling:** Fast green/red binary stock toggle (`in_stock: true | false`).
- **Carton Breakdown Calculator (`PackagingHelper`):** Utility modal that calculates shipper cartons and loose pieces for any order quantity (e.g., 52 units packed in boxes of 24 = 2 full boxes + 4 loose pieces).

### 3. Field Salesman Mode (Salesman PIN)
Optimized for order bookers visiting retail counters on daily delivery beats.
- **Route / Beat Bar (`SalesmanRouteBar`):** Sticky filter bar allowing salesmen to filter shops by route (e.g., `📍 Central Market Route`, `📍 Station Road Route`, or `📍 All Routes`).
- **Client-Side Shop Selector:** Searchable modal to quickly switch between approved retail accounts.
- **Cart Isolation Guard:** If a salesman switches to another retail counter while the active cart contains items, the app prompts for confirmation and clears the cart, preventing cross-shop item contamination.
- **Salesman Order Watermarking:** Orders dispatched in salesman mode automatically append `Booked by: <Name> (Salesman)` in the WhatsApp header for commission tracking.

### 4. Retailer Self-Order Desk (Mobile + PIN)
A mobile-first ordering interface for verified retail shopkeepers.
- **Party Profile Card:** Displays the store's registered trade identity, party code, and delivery beat.
- **Dual Price & Scheme Display:** Shows MRP alongside PTR, with margin percentage indicators and color transitions when volume schemes apply.
- **MOQ & Carton Quick-Buy:** Steppers enforce minimum order quantities, with adjacent 1-tap buttons to add full carton cases.
- **Proforma Cart & Dispatch:** Itemized review screen showing line rates, earned free units or discount subtotals, notes field, and 1-tap WhatsApp checkout with a clipboard fallback button.

### Authorization Model (Client-Side vs. Server-Side)
- **PIN-Based Access:** PIN verification is designed for rapid counter POS switching and field speed, not cryptographic single sign-on.
- **Firestore Mode:** Role guards and field shielding (such as hiding rates from Staff) operate as **client-side view filters** within the Flutter web application. Raw database access in Firestore is governed by the Firebase project's Firestore Security Rules.
- **WooCommerce REST Mode:** Authorization is verified **server-side** via custom REST authorization callbacks (`swac_desk_is_owner_authorized`, `swac_desk_can_read_retailers`, and role tokens). Requests from staff or salesmen attempting to modify protected fields like prices or schemes are rejected by the WordPress server with HTTP 403 Forbidden.

---

## Operational Model & Limitations

Distributors evaluating Wholesale Desk should note its specific operational constraints:

1. **Strict Binary Stock Model (`in_stock: true | false`):**
   - Stock availability is binary. The app does **not** track quantitative inventory balances (e.g., counting down from 150 units).
   - WhatsApp order submissions **never decrement** inventory counts in the connected database.
   - Out-of-stock products are visually flagged and disabled from cart additions. Stock status is manually toggled in-place by staff or admin.
2. **No Database Order Records:**
   - Checking out does **not** create order documents, customer transactions, or invoice entities in Firestore or WooCommerce.
   - The order exists exclusively as an itemized, mathematically verified text message dispatched to the distributor's WhatsApp chat.
3. **Automated Scheme Math (Two Primitives Only):**
   - Automated cart scheme calculations are strictly limited to two predictable primitives:
     - **Free Goods (`X+Y`):** Adds `floor(qty / X) * Y` bonus pieces to line items on apply.
     - **Flat Percentage (`N%`):** Deducts `N%` from unit PTR on apply. Minimum thresholds are enforced via product `moq`.
   - Any unrecognized string (e.g., custom festive promotions or conditional terms) is badged as an Informational Note (`📢 {text}`) and passed into the WhatsApp message without mutating cart line pricing.
4. **Zero Image Overhead:**
   - The product catalog uses dense typography, packing specifications, and brand badges with no heavy image rendering. This ensures fast rendering and low data consumption across mobile browsers and counter PCs.

---

## Dual Backend Architecture & Standalone Path

Wholesale Desk features a modular repository layer (`WholesaleRepository`) supporting two backend implementations:

```
                        ┌───────────────────────────────┐
                        │      WholesaleRepository      │
                        │    (Abstract Domain Engine)   │
                        └───────────────┬───────────────┘
                                         │
                ┌───────────────────────┴───────────────────────┐
                ▼                                               ▼
┌───────────────────────────────┐               ┌───────────────────────────────┐
│     Cloud Firestore Mode      │               │     WooCommerce REST Mode     │
│   (Standalone / Serverless)   │               │     (WordPress Integration)   │
│  • Direct Firestore sync      │               │  • /wp-json/swac/v1/desk/...  │
│  • /settings/general          │               │  • Syncs with WC products     │
│  • /products & /retailers     │               │  • Server-side REST auth      │
│  • In-memory demo fallback    │               │  • Reads/writes B2B post-meta │
└───────────────────────────────┘               └───────────────────────────────┘
```

### Origin & Standalone Positioning
- **Origin:** Wholesale Desk was originally conceived from the B2B wholesale module in [`0xCoderunknown/woocommerce-whatsapp-commerce`](https://github.com/0xCoderunknown/woocommerce-whatsapp-commerce).
- **Standalone Path:** Many traditional wholesale distributors in India do not run WordPress or WooCommerce, nor do they desire the operational overhead of maintaining a WooCommerce website. Wholesale Desk provides a **fully standalone path**: distributors can deploy Wholesale Desk using Cloud Firestore (or test it locally using the built-in in-memory catalog) with zero WordPress dependencies.
- **Connected Path:** For businesses that already run a WooCommerce store powered by `woocommerce-whatsapp-commerce`, Wholesale Desk can switch to WooCommerce REST mode, syncing rates, carton packs, MOQ, and stock status directly with WooCommerce product post-meta.
- Neither backend is mandatory for local evaluation; the app boots out-of-the-box in demo mode using in-memory mock data if neither backend is configured.

---

## Human-Configurable Root File (`config.json`)

Store identity, contact phone numbers, access PINs, and Firebase credentials reside in `config.json` at the project root:

```json
{
  "store_name": "Apex Wholesale Distributors",
  "whatsapp_phone": "917002796068",
  "master_pin": "5075",
  "staff_pin": "1122",
  "salesman_pin": "3344",
  "backend_type": "firebase",
  "woocommerce_base_url": "https://mywholesalestore.com",
  "firebase": {
    "api_key": "YOUR_FIREBASE_API_KEY",
    "project_id": "YOUR_PROJECT_ID",
    "app_id": "YOUR_APP_ID",
    "messaging_sender_id": "YOUR_SENDER_ID",
    "auth_domain": "YOUR_PROJECT.firebaseapp.com",
    "storage_bucket": "YOUR_PROJECT.appspot.com"
  }
}
```

---

## WhatsApp Order Payload Specification

The compiled order string is structured for readability on warehouse phones, fitting cleanly within WhatsApp URL length constraints:

```text
*ORDER: Gupta Provision Store (Central Market Route)*
Ref: #8YF2 | Reg: 9876543210
Booked by: Salesman (Salesman)
--------------------------------
1. Dettol Antiseptic Liquid 500ml
   12 pcs (+1 Free) @ 285.00 = ₹3,420.00
2. Tata Tea Gold Leaf 500g
   20 pcs (1 Box) @ 268.00 = ₹5,360.00
--------------------------------
*Total: ₹8,780.00 (32 units)*
Notes: Dispatch before 2 PM via Tempo delivery
```

*(Line 3 `Booked by:` is automatically omitted when an authenticated retailer places their own order).*

---

## Platform & Hardware Targets

Wholesale Desk is built using **Flutter** and targets modern desktop and mobile browsers (Chrome, Edge, Safari, Firefox), with native Android compilation readiness pre-configured.

> **Deployment Architecture:** The primary deployment target is Flutter Web, delivering instant, zero-install access across desktop monitors and mobile web browsers. The repository also includes the complete Android platform harness (`android/` scaffolding, Internet permissions, and WhatsApp `<queries>` intent filters), keeping the scope alive so the app can be compiled directly to a native Android APK or App Bundle whenever required.

| Surface | Recommended Device | Optimized Interface |
|---|---|---|
| **Distributor Desk** | Desktop Monitor (1080p / 1366x768) | High-density data table, keyboard shortcuts, inline rate dialogs |
| **Warehouse Counter** | Low-cost Desktop / Counter PC | Rate-shielded stock toggle pills, dispatch carton calculator |
| **Field Salesman** | Mobile Browser / Android Device (390px – 430px) | Sticky route bar, client-side shop selector, cart isolation guard |
| **Retailer Shop** | Mobile Web Browser / Android Device | Single-column card list, MOQ steppers, sticky bottom cart pill |

---

## Deployment & Developer Setup

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.13+ (configured for Web)
- Google Chrome (for local debugging)
- *(Optional)* Firebase project with Cloud Firestore and Hosting enabled

### Run Locally (Demo Mode Out-of-the-Box)
The application starts immediately with an in-memory sample FMCG catalog and mock routes without requiring external database configuration:

```bash
# Clone the repository
git clone https://github.com/0xCoderunknown/wholesale-desk.git
cd wholesale-desk

# Fetch dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome
```

### Verification & Testing Gate
Every commit and pull request must satisfy the automated test suite:

```bash
# Enforces zero static analyzer issues
flutter analyze

# Executes all 80 unit, domain, and widget tests
flutter test
```

### Build & Deploy Targets

**Web Build (Firebase Hosting):**
```bash
# Production Web Build
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

**Android Build (Future Scope / Native App Compilation):**
```bash
# Production Android APK
flutter build apk --release

# Production Android App Bundle (Play Store)
flutter build appbundle --release
```

---

## Architecture & Reference Documents

| Document | Purpose |
|---|---|
| [`AGENTS.md`](AGENTS.md) | **Operating Constitution**: Architectural invariants, red lines, role guardrails, and PM protocol |
| [`CHANGELOG.md`](CHANGELOG.md) | Release history, added features, breaking changes, and domain polish |
| [`.agents/rules/wholesale_desk_rules.md`](.agents/rules/wholesale_desk_rules.md) | Workspace rules and operational directives |
| [`.agents/recipes/add_product_field.md`](.agents/recipes/add_product_field.md) | Implementation checklist for extending product catalog fields |
| [`.agents/recipes/add_store_setting.md`](.agents/recipes/add_store_setting.md) | Implementation checklist for adding system configuration parameters |

---

## License

Open Source under the [MIT License](LICENSE). Maintained by [0xCoderunknown](https://github.com/0xCoderunknown).
