# Wholesale Desk (Flutter Web + Firebase / WooCommerce REST)

A high-speed, zero-bloat **B2B Wholesale Order & Distributor Desk** built for Flutter Web with dual backend support (**Cloud Firestore** or **WordPress + WooCommerce REST API**), inspired by POS counter-speed operations and WhatsApp-driven B2B commerce.

---

## ⚡ Core Philosophy & Invariants
1. **Web-Only Target**: Zero mobile/desktop bloat (`flutter run -d chrome`). High-density Tally/POS responsive layout for both desktop monitors and mobile browsers.
2. **Binary Stock Model**: Strictly binary stock (`in_stock: true | false`). Customer orders **never** reduce inventory counts; stock status is flipped instantly in-place via green/red pills by Staff or Admin without a "Save" button.
3. **No Image Overhead**: Zero media/image rendering in the catalog for maximum counter speed and low bandwidth usage.
4. **WhatsApp B2B Checkout**: Zero payment gateway or checkout server sessions. Itemized, structured B2B orders compile into clean WhatsApp URL messages (`https://wa.me/{phone}?text=...`) launched via `url_launcher`.
5. **Dual Backend Provider (Pluggable Repository)**:
   - **Cloud Firestore**: Serverless, realtime Firestore collections (`/settings/general`, `/retailers`, `/products`).
   - **WordPress + WooCommerce**: Direct REST API integration with `woocommerce-whatsapp-commerce` (`/wp-json/swac/v1/`).
6. **Role-Based 4-Digit PIN Access**:
   - **Admin (Master PIN `5075`)**: Full Distributor Desk with catalog management, in-place rate/scheme/MOQ/box size editing, stock toggle, Retailer PIN management, and Store Settings.
   - **Staff (Staff PIN `1122`)**: Restricted Counter Desk. Can search catalog with 0ms latency; **only** permitted action is toggling `in_stock` (true/false). Rates and settings are hidden/read-only.
   - **Retailer (Mobile + 4-Digit PIN, e.g. `9876543210` / `1234`)**: Authenticates into verified Retailer Catalog with store name & route banner, in-memory instant search, MOQ-enforcing quantity steppers, live savings calculator, and slide-out WhatsApp cart drawer.

---

## 🛠️ Human-Configurable Root File (`config.json`)

To prevent hardcoding of business details (such as phone numbers or store identity), a human-editable `config.json` lives at the project root:

```json
{
  "store_name": "Apex Wholesale Distributors",
  "whatsapp_phone": "917002796068",
  "master_pin": "5075",
  "staff_pin": "1122",
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

## 🚀 Quick Start

### Run locally on Chrome:
```bash
flutter run -d chrome
```

### Test Demo Credentials:
- **Admin Desk**: PIN `5075`
- **Staff Counter**: PIN `1122`
- **Retailer Order Desk**: Mobile `9876543210`, PIN `1234`
