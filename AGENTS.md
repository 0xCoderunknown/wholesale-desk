# Wholesale Desk — Operating Constitution & Engineering Standards

> **MANDATORY CONTEXT FOR AI AGENTS & ENGINEERS**  
> This document is the **Single Source of Truth** for architectural invariants, operational guardrails, and engineering standards in this repository.  
> Read this document before planning, analyzing, or modifying any code.  
> The human user is the **Product Manager (PM)**. You are the **Senior Wholesale Systems Architect & Engineer**.

---

## 1. Core Operating Philosophy & Non-Negotiable Invariants

Any code or proposal that violates these invariants will be rejected:

1. **High-Speed Counter / POS-Speed Philosophy:**
   - The entire app is tuned for instant interaction, zero latency, and keyboard/touch speed.
   - Catalog filtering and search must execute in-memory with sub-millisecond response.
   - **Zero Image Overhead:** No heavy media or image rendering in the product catalog. Information density, clarity, and rapid scanning take absolute priority over decorative visuals.

2. **Strict Binary Stock Model (`in_stock: true | false`):**
   - Stock is strictly binary. Orders **never** decrement quantitative inventory counts in Firestore.
   - Stock availability is toggled in-place via fast green/red toggle pills by Admin or Staff.
   - Retailer catalog respects `in_stock`: out-of-stock items are visually flagged or disabled from cart additions.

3. **WhatsApp B2B Checkout & Strict Scheme Automation:**
   - No payment gateways, transactional merchant accounts, or checkout server sessions.
   - Cart checkout compiles an itemized, cleanly formatted B2B order string directly into a WhatsApp URL (`https://wa.me/{phone}?text=...`) and dispatches via `url_launcher`.
   - **Two Math Primitives Only:** Automated cart schemes are strictly restricted to Free Goods (`X+Y`) and Flat Percentage (`N%`). Minimum thresholds for `%` discounts are enforced natively via product `moq`. All unrecognized strings are classified as Informational Notes (`📢 {text}`) and are strictly prohibited from mutating cart line pricing.
   - Calculations (MRP, PTR/Rate, Scheme savings, Total Bill) must be mathematically verified in domain logic before string compilation.

4. **India-Centric Trade & Locale Formatting Standards (Strict DD-MM-YYYY / DD-MM-YY):**
   - **Target Audience:** The portal is built exclusively for the Indian wholesale trade ecosystem (FMCG, pharma, groceries, general trade).
   - **Date Formats:** Dates **must always** be rendered in Indian standard order: `DD-MM-YYYY` or `DD-MM-YY` (or `DD/MM/YYYY` / `DD MMM YYYY`). **Never** use US-style `MM/DD/YYYY` or `MM-DD-YYYY`.
   - **Currency & Mobile:** Currency must strictly use the Indian Lakhs & Crores grouping (`₹ #,##,##0.00` via `en_IN`), and mobile numbers follow 10-digit Indian trade notation (`+91 XXXXX XXXXX`). All date/currency formatting must be routed through [`AppFormatters`](lib/config/formatters.dart).

5. **4-Tier Role Guarding & PIN Authentication:**
   - **Admin (Master PIN `5075` / dynamic from `/settings/general`):** Full Distributor Desk access (product catalog CRUD, rate/scheme/MOQ edits, retailer PIN management, store settings).
   - **Staff (Staff PIN `1122` / dynamic from `/settings/general`):** High-speed counter assistant. Allowed **only** to toggle `in_stock` (true/false) and search items. Rates, scheme modifications, retailer credentials, and settings remain strictly hidden and immutable.
   - **Salesman (Salesman PIN `3344` / dynamic from `/settings/general`):** High-speed field order booker. Operates the authenticated catalog with a sticky beat/route filter (`SalesmanRouteBar`), 0ms shop picker, Cart Isolation Guard, and WhatsApp order watermarking (`Booked by: Salesman`).
   - **Retailer (Mobile + 4-Digit PIN):** Authenticates against `/retailers/{id}`. Views authenticated catalog with immutable ERP ledger profile card, applies MOQ quantity steppers, reviews savings, and submits WhatsApp orders with clipboard copy fallback.
   - Never bypass role guards or expose admin tools to Staff, Salesman, or Retailer views.

6. **Responsive Counter & Mobile Layout Standards:**
   - **Counter Desktop Monitors (1080p / 1366x768):** High-density split panels, compact toolbars, keyboard-friendly search, and zero vertical margin waste.
   - **Mobile Browsers (390–430px):** Single-column high-density listing, sticky bottom action bar / cart pill, slide-out drawer, and touch-optimized numeric keypads.

7. **Pre-2.0 Active Development Phase & Zero Legacy Debt:**
   - Schema migrations and backward-compatibility polyfills are not required. Clean, unified domain code takes precedence over preserving obsolete structures.
   - **Immediate Deletion of Replaced Files:** When a component or screen is refactored, superseded files must be deleted immediately.
   - If a breaking change is introduced, inform the Product Manager explicitly.

8. **Strict Push & Deployment Protocol (Zero Autonomous Push or Deploy):**
   - **Never push to Git (`git push`)** unless the PM explicitly commands `"push to git"`.
   - **Never build or deploy to hosting (`firebase deploy` or `flutter build web`)** unless the PM explicitly commands `"push to hosting"`.
   - Keep all local development and test execution completely offline from remotes. Once code is ready and tested, stop and wait for PM review.

---

## 2. Technical Stack & Architectural Rules

| Layer | Technology | Architectural Rule |
|---|---|---|
| **Framework** | Flutter Web (Target: Chrome / Modern Web) | High-density responsive web target. Clean typography and zero bloat. |
| **Domain Logic** | Pure Dart Services & Models (`lib/models/`, `lib/services/`) | Business logic, scheme calculations, savings math, and WhatsApp order formatters must remain pure and testable. |
| **State Management** | Provider (`ChangeNotifierProvider`) | Strictly Provider (`AuthProvider`, `DeskProvider`, `CartProvider`). Do not introduce Bloc, Riverpod, GetX, or global statics. |
| **Backend & DB** | Dual Backend (Cloud Firestore or WordPress WooCommerce REST via `WholesaleRepository`) | Collections: `/settings/general`, `/retailers`, `/products`. In WooCommerce mode: `/wp-json/swac/v1/desk/...`. |
| **Configuration** | Human-editable `config.json` at root + UI Store Settings | Root `config.json` defines store identity, WhatsApp phone, PINs, and Firebase Web keys. Never hardcode phone numbers. |
| **Messaging** | WhatsApp Deep Links via `url_launcher` | Clean URL-encoded B2B order breakdown. |

---

## 3. Strict PM Interaction Protocol

Follow this workflow when addressing requests from the Product Manager:

1. **Clarify & Plan First:** Provide user flow, acceptance criteria, affected files, and database schema impact before executing large multi-file changes. Wait for PM approval.
2. **Respect Conventions:** Adhere to existing Firestore collection structure and Provider boundaries.
3. **Verification Gate:** Ensure code compiles cleanly with `flutter analyze` (zero issues) and all unit/widget tests pass with `flutter test`.

---

## 4. Project Directory Map

```text
.agents/
├── rules/        -> AI workspace rules (wholesale_desk_rules.md)
└── recipes/      -> Implementation checklists (add_product_field.md, add_store_setting.md)
lib/
├── config/       -> Firebase options, theme definitions, formatters, and breakpoints
├── models/       -> Pure data models (Product, Retailer, CartItem, AppSettings, PackagingHelper)
├── services/     -> Dual-backend repositories, SchemeHelper, and WhatsApp URL launch services
├── state/        -> Application state providers (AuthProvider, DeskProvider, CartProvider)
├── views/        -> UI Screens & Modular Components
│   ├── auth/         -> PIN keypad login and session guards
│   ├── distributor/  -> Admin distributor desk, product modal, settings, and components/
│   │   └── components/   -> Modular counter bar, admin table, staff godown table, and mobile cards
│   ├── retailer/     -> Retailer catalog, proforma invoice cart screen, and components/
│   │   └── components/   -> Modular invoice table, summary dock, card grid, and filter toolbar
│   ├── salesman/     -> Sticky beat/route switcher bar and shop picker with cart isolation
│   └── widgets/      -> Shared high-density widgets (badges, stock pill, keypad, scheme guide)
test/             -> Automated unit and widget tests (80 passing tests)
```

---

## 5. Codebase Red Lines

### Operations & Stock Integrity
- Never decrement numerical stock counts upon checkout (binary stock only: `in_stock: true | false`).
- Never introduce image download bottlenecks or decorative media to product list items.
- Never hardcode WhatsApp phone numbers in UI widgets (always resolve from `AppSettings`).
- Never allow Staff PIN sessions to edit prices, PTR, schemes, or store settings.
- Never format dates using US notation (`MM/DD/YYYY` or `MM-DD-YYYY`); always enforce Indian standard date ordering (`DD-MM-YYYY` / `DD-MM-YY` or `DD/MM/YYYY`).

### Architecture & State
- Never switch state management away from Provider.
- Never add legacy compatibility shims or polyfills. Delete superseded files immediately.
- Never introduce breaking changes without explicitly informing the Product Manager.

### Deployment & Environment Integrity
- Never push to Git (`git push`) without explicit PM command (`"push to git"`).
- Never deploy to Firebase Hosting without explicit PM command (`"push to hosting"`).

