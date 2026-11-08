# Wholesale Desk (Flutter Web + Firebase / WooCommerce REST)

A high-speed, zero-bloat **B2B Wholesale Order & Distributor Desk** built for Flutter Web with dual backend support (**Cloud Firestore** or **WordPress + WooCommerce REST API**), inspired by POS counter-speed operations and WhatsApp-driven B2B commerce.

---

## ⚡ Core Philosophy & Invariants
1. **Web-Only Target**: Zero mobile/desktop bloat (`flutter run -d chrome`). High-density Tally/POS responsive layout for both desktop monitors and mobile browsers.
2. **Binary Stock Model**: Strictly binary stock (`in_stock: true | false`). Customer orders **never** reduce inventory counts; stock status is flipped instantly in-place via green/red pills by Staff or Admin without a "Save" button.
3. **No Image Overhead**: Zero media/image rendering in the catalog for maximum counter speed and low bandwidth usage.
4. **WhatsApp B2B Checkout & Clipboard Fallback**: Zero payment gateway or checkout server sessions. Itemized, structured B2B orders compile into clean WhatsApp URL messages (`https://wa.me/{phone}?text=...`) launched via `url_launcher`, with 2-line order reference watermark and 1-tap clipboard fallback (`[ 📋 Copy ]`).
5. **Dual Backend Provider (Pluggable Repository)**:
   - **Cloud Firestore**: Serverless, realtime Firestore collections (`/settings/general`, `/retailers`, `/products`).
   - **WordPress + WooCommerce**: Direct REST API integration with `woocommerce-whatsapp-commerce` (`/wp-json/swac/v1/`).
6. **Role-Based 4-Digit PIN Access**:
   - **Admin (Master PIN `5075`)**: Full Distributor Desk with catalog management, in-place rate/scheme/MOQ/box size editing, stock toggle, Retailer PIN management, and Store Settings.
   - **Staff (Staff PIN `1122`)**: Restricted Counter Desk. Can search catalog with 0ms latency; **only** permitted action is toggling `in_stock` (true/false). Rates and settings are hidden/read-only.
   - **Salesman (Salesman PIN `3344`)**: Field Order Booker. Route & beat dropdown filter, 0ms searchable shop selector with Cart Isolation Guard, and WhatsApp watermark tagging (`Booked by: Salesman`).
   - **Retailer (Mobile + 4-Digit PIN, e.g. `9876543210` / `1234`)**: Authenticates into verified Retailer Catalog with read-only ERP ledger profile card, in-memory instant search, MOQ-enforcing quantity steppers, live savings calculator, and dedicated Wholesale Order Desk.

---

## 🛠️ Human-Configurable Root File (`config.json`)

To prevent hardcoding of business details (such as phone numbers or store identity), a human-editable `config.json` lives at the project root:

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

- When phone numbers or store names change, edit `config.json` directly or use the in-app **Store Settings Dialog** in the Admin Desk.
- Firebase Web credentials can be placed directly in `config.json` under `"firebase"`.

---

## 📡 How Wholesale Desk Queries Firebase

1. **Bootstrap & Initialization** (`lib/main.dart`):
   - `AppConfig.load()` reads `config.json` from the root.
   - `Firebase.initializeApp(options: AppConfig.firebaseOptions)` initializes Firebase with the options from `config.json` (with graceful fallback to demo mode if keys are not yet configured).
2. **Reactive Query Streams** (`lib/services/database_service.dart`):
   - **Settings**: Reads `/settings/general` via `.snapshots()`.
   - **Catalog Products**: Reads `/products` collection via `.snapshots()`. In-memory filtering executes on the client keystroke-by-keystroke with 0ms network lag.
   - **Retailer Directory**: Reads `/retailers` collection via `.snapshots()`.
3. **Instant Writes**:
   - Stock toggle (`toggleStock`) executes `.update({'in_stock': inStock, 'updated_at': FieldValue.serverTimestamp()})` immediately upon clicking the Green/Red pill.

---

## 🗄️ Firestore Database Schema

### 1. `/settings/general`
```json
{
  "store_name": "Apex Wholesale Distributors",
  "whatsapp_phone": "917002796068",
  "master_pin": "5075",
  "staff_pin": "1122",
  "salesman_pin": "3344",
  "backend_type": "firebase",
  "wp_base_url": ""
}
```

### 2. `/retailers/{id}`
```json
{
  "store_name": "Gupta Provision Store",
  "mobile": "9876543210",
  "pin": "1234",
  "route": "Central Market Route",
  "status": "active"
}
```

### 3. `/products/{id}`
```json
{
  "name": "Dettol Antiseptic Liquid 500ml",
  "brand": "Reckitt",
  "mrp": 330.0,
  "ptr": 285.0,
  "scheme": "12+1 Free",
  "moq": 12,
  "carton_pack": 24,
  "box_size": 24,
  "in_stock": true,
  "image_url": "",
  "updated_at": "timestamp"
}
```

---

## 🌐 Live Public Demo

Experience the high-speed B2B Wholesale Desk live in your browser:  
👉 **[https://wholesale-desk-hub.web.app](https://wholesale-desk-hub.web.app)**

### Test Credentials (1-Click Chips on Login):
- **Admin Desk (Master)**: PIN `5075` — full catalog CRUD, schemes, retailer PIN management, and 1-click `[⚡ Reset Demo]`
- **Staff Counter (Restricted)**: PIN `1122` — 0ms catalog search and in-place stock toggle pills
- **Field Salesman**: PIN `3344` — route/beat dropdown, 0ms shop picker with cart isolation, and WhatsApp watermark
- **Retailer Order Desk**: Mobile `9876543210`, PIN `1234` — high-density catalog, MOQ steppers, and dedicated Wholesale Order & Dispatch Desk

---

## 🔒 Open-Source (FOSS) Setup & Firebase Config

This repository is hardened for open-source (FOSS) safety with zero committed secrets:
1. **Local Evaluation**: The app runs immediately out-of-the-box (`flutter run -d chrome`) with rich in-memory sample FMCG products, sample retailers, and fallback settings without requiring Firebase setup.
2. **Connecting Your Firebase Project**:
   - Copy `.firebaserc.example` to `.firebaserc` and set your Firebase project ID.
   - Supply your web credentials in `config.json` under `"firebase"` or run `flutterfire configure --platforms=web`.
   - In Firestore, enable Cloud Firestore in your Firebase console.

---

## 🚀 Quick Start

### Run locally on Chrome:
```bash
flutter run -d chrome
```

### Build & Deploy:
```bash
flutter build web --release
firebase deploy --only hosting
```
