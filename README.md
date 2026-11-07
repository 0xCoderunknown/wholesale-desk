# Wholesale Desk (Flutter Web + Firebase)

A high-speed, zero-bloat **B2B Wholesale Order & Distributor Desk** built for Flutter Web and Cloud Firestore, inspired by POS/counter-speed operations and WhatsApp-driven commerce.

---

## ⚡ Core Philosophy & Invariants
1. **Web-Only Target**: Zero mobile/desktop bloat (`flutter run -d chrome`). High-density Tally/POS responsive layout for both desktop monitors and mobile browsers.
2. **Binary Stock Model**: Strictly binary stock (`in_stock: true | false`). Customer orders **do not** reduce inventory counts; stock status is flipped instantly in-place via green/red pills by Staff or Admin.
3. **No Image Overhead**: Zero media/image rendering in the catalog for maximum counter speed and low bandwidth usage.
4. **WhatsApp B2B Checkout**: Zero payment gateway or server order sessions. Itemized, structured B2B orders compile into clean WhatsApp URL messages (`https://wa.me/{phone}?text=...`) launched via `url_launcher`.
5. **Role-Based 4-Digit PIN Access**:
   - **Admin (Master PIN `5075`)**: Full Distributor Desk with catalog management, in-place rate/scheme/MOQ editing, stock toggle, Retailer PIN management, and Store Settings.
   - **Staff (Staff PIN `1122`)**: Restricted Counter Desk. Can search catalog with 0ms latency; **only** permitted action is toggling `in_stock` (true/false). Rates and settings are hidden/read-only.
   - **Retailer (Mobile + 4-Digit PIN, e.g. `9876543210` / `1234`)**: Authenticates into verified Retailer Catalog with store name & route banner, in-memory instant search, MOQ-enforcing quantity steppers, live savings calculator, and slide-out WhatsApp cart drawer.

---

## 🗄️ Firestore Database Schema

### 1. `/settings/general`
```json
{
  "store_name": "Apex Wholesale Distributors",
  "whatsapp_phone": "917002796068",
  "master_pin": "5075",
  "staff_pin": "1122"
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

### Build for production Web:
```bash
flutter build web --wasm
```

### Test Demo Credentials:
- **Admin Desk**: PIN `5075`
- **Staff Counter**: PIN `1122`
- **Retailer Order Desk**: Mobile `9876543210`, PIN `1234`
