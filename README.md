# Wholesale Desk

**The high-speed B2B ordering and distributor desk built for Indian wholesale trade.**

Wholesale Desk replaces messy handwritten parchaas, cluttered WhatsApp voice notes, and sluggish ERP ordering portals with a single, lightning-fast screen. Built for FMCG, pharma, and grocery distributors who need POS counter speed, zero latency, and seamless WhatsApp dispatch. No expensive software installations. Runs directly in any modern browser.

[![Version](https://img.shields.io/badge/Version-1.8.0-blue)](CHANGELOG.md)
[![Platform](https://img.shields.io/badge/Platform-Flutter%20Web-teal)](#deployment--developer-setup)
[![Speed](https://img.shields.io/badge/Search%20Speed-%3C1ms%20In--Memory-brightgreen)](#core-operational-invariants)
[![Tests](https://img.shields.io/badge/Tests-57%20Passing-success)](test/)
[![Dual Backend](https://img.shields.io/badge/Backend-Firestore%20%7C%20WooCommerce%20REST-orange)](#dual-backend-architecture)

---

## Try the Live Demo

**[▶ wholesale-desk-hub.web.app](https://wholesale-desk-hub.web.app)** — Pre-loaded with FMCG catalog, active schemes, and sample routes. Resets in one tap.

| Role | Access Credentials | Primary Workspace |
|---|---|---|
| **Distributor Admin (Master)** | PIN `5075` | Master catalog CRUD, rates, schemes, retailer PINs, and store config |
| **Staff Counter (Restricted)** | PIN `1122` | 0ms catalog search, rate-shielded stock toggle, and carton calculator |
| **Field Salesman (Booker)** | PIN `3344` | Route/beat filter, 0ms shop picker, cart isolation, and order watermarking |
| **Retailer Order Desk** | Mobile `9876543210` · PIN `1234` | Read-only ERP ledger, MOQ steppers, live scheme math, and WhatsApp checkout |

*(All demo credentials have 1-click quick-fill chips on the login screen).*

---

## The Operational Problem It Solves

In traditional Indian distribution (Marg, Tally, Busy setups), distributors manage 500–5,000 SKUs with constantly fluctuating trade rates, volume schemes (e.g. `12+1 Free`, `3% Cash Scheme`), and minimum order quantities (MOQ). 

Retailers either send garbled WhatsApp voice notes, call busy counter staff during peak billing hours, or wait for a field salesman to visit their shop once a week. When distributors deploy conventional B2B apps or heavy SFA tools (Bizom, FieldAssist), they fail because:
- High-res product images consume mobile data and choke counter loading speeds.
- Heavy sync spinners lock the UI during shop visits.
- Complex payment gateways introduce transaction drop-offs and settlement delays.

Wholesale Desk solves this with **POS-speed architecture**: everything executes in-memory, product cards have zero image weight, and orders compile directly into verified WhatsApp deep links.

```
Traditional Flow:
Retailer sends messy voice note ➔ Counter boy mishears item ➔ Wrong carton billed in Tally ➔ Dispute on delivery

Wholesale Desk Flow:
Retailer/Salesman taps verified MOQ & scheme ➔ Live PTR & savings verified ➔ 1-tap WhatsApp dispatch with ERP Ref # ➔ Clerk imports directly
```

---

## What It Covers

### 1. Distributor Admin Desk (Master Access)
The command center for distributor owners and billing managers. Protected by Master PIN (`5075` or dynamic from database).

- **High-Density Split Panel (Desktop Monitors):** Designed for 1080p and 1366x768 billing desk monitors with zero vertical margin waste.
- **In-Place Catalog Management:** Edit PTR (distributor price to retailer), MRP, MOQ, box pack sizes, and scheme configurations in-place without sluggish popup save cycles.
- **Instant Stock Control:** Toggle binary stock availability (`in_stock: true | false`) with instant green/red status pills.
- **Retailer PIN & Party Ledger Management:** Create and manage retailer accounts linked directly to ERP party codes, assigned routes, and phone numbers.
- **Store & Identity Configuration:** Configure billing WhatsApp number, store title, backend mode, and access PINs directly from the UI without redeployment.
- **1-Click Demo Reset:** Instantly resets the database to standard demonstration products and routes for testing and onboarding.

### 2. Staff Counter (Restricted Assistant)
Designed for the warehouse boy or junior counter assistant. Protected by Staff PIN (`1122`).

- **Rate & Margin Shielding:** PTR (Rate), Margins, MRP, and wholesale scheme structures are strictly hidden from staff view to protect distributor trade secrets.
- **0ms Catalog Search:** Rapidly scan products by name, brand, or packing size with sub-millisecond in-memory response.
- **Stock Availability Toggling:** Staff are permitted only to toggle binary stock availability (Green = In Stock, Red = Out of Stock).
- **Warehouse Carton Breakdown Calculator:** Instant modal calculator that decomposes total required units into full sealed shipper cartons and loose units (`e.g. 52 pcs in Box of 24 = 2 Full Boxes + 4 Loose Units`).

### 3. Field Salesman Mode (Route Order Booker)
Built for field order bookers who visit 25–40 retail counters per day. Protected by Salesman PIN (`3344`).

- **Sticky Beat & Route Selector (`SalesmanRouteBar`):** Compact 44px sticky bar at the top of the mobile catalog allowing salesmen to filter shops by route (`📍 Central Market Route`, `📍 Station Road Route`, or `📍 All Routes`).
- **Sub-Millisecond Shop Picker:** Instant searchable bottom sheet to select active retailer by store name, phone, or beat.
- **Cart Isolation Guard:** When switching between shops, automatically prompts confirmation if the active cart contains items, preventing accidental cross-shop order contamination.
- **Salesman Order Watermark:** WhatsApp orders automatically include `Booked by: Salesman Name (Salesman)` in the header for transparent commission attribution and clerk verification.

### 4. Retailer Self-Order Desk
The mobile-first ordering portal given to verified shopkeepers. Authenticates via Registered Mobile + 4-Digit PIN.

- **Immutable ERP Ledger Profile:** Displays read-only party ledger credentials (Store Name, Party Code, Route, Registered Mobile) with `🔒 Managed by Distributor ERP` lock indicator and distributor dispute contact footer.
- **Unified Price Bar:** Clear typography displaying `[₹MRP  [MARGIN %]  ₹PTR]`. MRP and PTR share identical font sizing; PTR dynamically transitions to vibrant emerald green when volume schemes take effect.
- **MOQ Stepper & 1-Tap Carton Quick-Buy:** Quantity steppers enforce minimum order quantities, with adjacent `[ Buy 1 Box (N) ]` pills to add full case packs in a single tap.
- **Collapsible Tiered Scheme Accordion:** Shikhar-style expandable deals drawer showing tiered slabs (`Buy 10+1 Free`, `Buy 50 Get ₹5 Off`) with instant 1-tap undo (`[REMOVE]`).
- **Enterprise 2-Column Desktop Cart & Mobile Sticky Bar:** Split proforma invoice table with pinned summary dock on desktop (≥1024px) and thumb-friendly sticky checkout bar on mobile (<768px).
- **WhatsApp B2B Checkout & Clipboard Fallback:** Compiles itemized B2B order string directly into WhatsApp URL, complete with 4-character reference hash (`Ref: #XXXX`) and 1-tap copy button (`[ 📋 Copy ]`) for desktop or web fallback.

---

## Core Operational Invariants

Any code or modification in Wholesale Desk strictly adheres to five non-negotiable invariants:

1. **High-Speed In-Memory Operations (<1ms):** Catalog filtering, route switching, and cart calculations happen entirely in-memory on the client without blocking network spinners.
2. **Zero Image Overhead:** No heavy media or image rendering in the product catalog. Scanning density, visual clarity, and counter speed take absolute priority over decorative pictures.
3. **Strict Binary Stock Model (`in_stock: true | false`):** Orders **never** decrement quantitative inventory counts in the database. Stock status is binary and toggled in-place by staff or admin.
4. **WhatsApp B2B Checkout (Zero Gateway Overhead):** No payment gateway SDKs, merchant transaction fees, or cart checkout server sessions. Calculations (MRP, PTR, Scheme savings, Total Bill) are mathematically verified in domain logic and dispatched directly via WhatsApp deep links.
5. **4-Tier Sovereign Role Guarding:** Admin, Staff, Salesman, and Retailer roles are strictly isolated with dedicated PIN authentication and client-side view shielding.

---

## Dual Backend Architecture

Wholesale Desk features a pluggable repository architecture (`WholesaleRepository`) supporting two enterprise backends:

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
│   (Realtime serverless B2B)   │               │   (WordPress Enterprise B2B)  │
│  /settings/general            │               │   /wp-json/swac/v1/desk/...   │
│  /products                    │               │   Full sync with WP catalog   │
│  /retailers                   │               │   Carton packs & custom schemes│
└───────────────────────────────┘               └───────────────────────────────┘
```

You can toggle between backends at any time in `config.json` or live through the Admin Store Settings dialog.

---

## Human-Configurable Root File (`config.json`)

To prevent hardcoding business details or distributor secrets, configuration is stored in a clean, human-editable `config.json` at the project root:

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

The compiled order string is optimized for WhatsApp deep links, staying within URL character limits and providing a clean, parseable header for warehouse clerks:

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

*(Line 3 `Booked by:` is automatically omitted when a retailer self-orders).*

---

## Hardware & Environment Standards

Wholesale Desk runs in modern web browsers (Chrome, Edge, Safari, Firefox). Zero native installations required.

| Terminal | Target Device | Layout Experience |
|---|---|---|
| **Distributor Desk** | Desktop Monitor (1080p / 1366x768) | High-density data table, keyboard shortcuts, inline rate editors |
| **Warehouse Counter** | Low-cost Celeron / Core i3 PC | Rate-shielded stock toggle pills, dispatch box breakdown calculator |
| **Field Salesman** | Mobile Browser (390px – 430px) | Sticky beat bar, sub-millisecond shop selector, cart isolation guard |
| **Retailer Shop** | Android / iOS Mobile Browser | 1-Handed single-column card list, MOQ steppers, sticky cart pill |

---

## Deployment & Developer Setup

### Prerequisites
- Flutter 3.x Web SDK
- Chrome Browser
- *(Optional)* Firebase project with Firestore and Hosting enabled

### Run Locally (Demo Mode Out-of-the-Box)
The app runs immediately with rich in-memory sample FMCG products, sample routes, and mock fallback stores without requiring Firebase credentials:

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
Every commit and PR must strictly satisfy:

```bash
flutter analyze   # Enforces zero analyzer issues
flutter test      # All 57 automated unit and widget tests must pass
```

### Build & Deploy to Firebase Hosting
```bash
# Production Web Build
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

---

## Documentation & Architecture Guide

| Document | Purpose |
|---|---|
| [`AGENTS.md`](AGENTS.md) | **Operating Constitution**: Architectural invariants, red lines, role guardrails, and PM protocol |
| [`CHANGELOG.md`](CHANGELOG.md) | Release history, added features, breaking changes, and domain polish |
| [`.agents/rules/wholesale_desk_rules.md`](.agents/rules/wholesale_desk_rules.md) | AI workspace rules and operational directives |
| [`.agents/recipes/add_product_field.md`](.agents/recipes/add_product_field.md) | Implementation checklist for extending product catalog fields |
| [`.agents/recipes/add_store_setting.md`](.agents/recipes/add_store_setting.md) | Implementation checklist for adding system configuration parameters |

---

## License

Open Source / MIT. Maintained by [0xCoderunknown](https://github.com/0xCoderunknown).
