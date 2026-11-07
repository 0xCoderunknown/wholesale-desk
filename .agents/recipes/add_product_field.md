# Recipe: Adding a Field to Product Model

Follow this checklist when adding a new field (e.g. barcode, pack size, category, tax rate) to the `Product` entity.

---

### Step 1: Update Domain Model (`lib/models/product.dart`)
1. Add the field with appropriate nullability and default value to `Product`.
2. Update constructor.
3. Update `toMap()` / `toJson()`:
   - Match Firestore naming convention (`snake_case`).
4. Update `fromMap()` / `fromFirestore()`:
   - Add defensive parsing for nulls or type conversions.
5. Update `copyWith()` method if present.

---

### Step 2: Update Distributor Edit Dialog (`lib/views/distributor/product_edit_dialog.dart`)
1. Add `TextEditingController` or toggle state for the new field.
2. Initialize from incoming `widget.product`.
3. Add input field to dialog form layout.
4. Pass value into `Product` instantiation inside save action.

---

### Step 3: Wire Retailer Presentation (if applicable)
1. If relevant to retailer ordering (e.g. pack size or scheme info), display in `lib/views/retailer/retailer_catalog_screen.dart` or `cart_drawer.dart`.
2. Ensure high-density layout constraints are maintained.

---

### Step 4: Verification Gate
Run:
```bash
flutter analyze
flutter test
```
Both must pass with zero issues.

