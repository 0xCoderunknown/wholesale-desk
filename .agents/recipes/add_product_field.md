# Recipe: Adding a Field to Product Model

Follow this checklist when adding a new field (e.g. barcode, pack size, category, tax rate) to the `Product` entity.

---

### Step 1: Update Domain Model (`lib/models/product.dart`)
1. Add the field with appropriate nullability and default value to `Product`.
2. Update constructor.
3. Update `toMap()` / `toJson()`:
   - Match backend naming convention (`snake_case`).
4. Update `fromMap()`:
   - Add defensive parsing for nulls, numeric type conversions, or string representations.
5. Update `copyWith()` method.

---

### Step 2: Update Distributor Edit Dialog (`lib/views/distributor/product_edit_dialog.dart`)
1. Add `TextEditingController` or toggle state for the new field.
2. Initialize from incoming `widget.product`.
3. Add input field to dialog form layout with appropriate formatters and text actions.
4. Pass value into `Product` instantiation inside `_handleSave()`.

---

### Step 3: Wire Desk & Retailer Presentation (if applicable)
1. **Distributor Desk:** If visible to distributor or staff, add column/cell to:
   - `lib/views/distributor/components/distributor_admin_table.dart` (Admin view)
   - `lib/views/distributor/components/distributor_staff_table.dart` (Staff view, if rate-shielded)
   - `lib/views/distributor/components/distributor_mobile_card.dart` (Mobile card)
2. **Retailer Desk:** If relevant to retailer ordering (e.g. pack size or scheme info), display in:
   - `lib/views/retailer/retailer_catalog_screen.dart` / `components/product_card_tile.dart`
   - `lib/views/retailer/retailer_cart_screen.dart` / `components/cart_invoice_table.dart`
3. Ensure high-density layout constraints and zero image overhead are strictly maintained.

---

### Step 4: Verification Gate
Run:
```bash
flutter analyze
flutter test
```
Both must pass with zero issues.
