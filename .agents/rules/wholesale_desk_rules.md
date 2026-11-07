# Wholesale Desk AI Workspace Rules

[`AGENTS.md`](../../AGENTS.md) is the canonical Single Source of Truth for product invariants, architecture, database contracts, and verification requirements. Do not duplicate or override its rules here.

## Core Operational Directives

- **Verification:** Always verify changes with `flutter analyze` and `flutter test`. Both must pass with zero issues.
- **Stock Model:** Binary stock only (`in_stock: true | false`). Never deduct numerical stock counts.
- **Zero Image Overhead:** Maintain zero media/image rendering in the catalog for instant counter-speed performance.
- **Role Security:** Strictly isolate Admin (full desk), Staff (stock toggle only), and Retailer (authenticated ordering) permissions.
- **State Management:** Provider strictly (`ChangeNotifierProvider`). Do not introduce external state management libraries.
- **Zero Legacy Debt:** Backward compatibility is not required during pre-2.0 active development. Never add compatibility shims or polyfills. Immediately delete superseded or replaced legacy files.
- **Zero Autonomous Push or Deploy:** Never push to Git (`git push`) or deploy to hosting autonomously. Only push to Git when PM explicitly says `"push to git"`. Only deploy when PM explicitly says `"push to hosting"`.

