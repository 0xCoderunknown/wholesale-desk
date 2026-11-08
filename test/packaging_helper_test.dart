import 'package:flutter_test/flutter_test.dart';
import 'package:wholesale_desk/models/packaging_helper.dart';

void main() {
  group('PackagingHelper Pure Domain Math & Trade Nomenclature', () {
    test('Calculates exact full cartons with zero loose units', () {
      final breakdown = PackagingHelper.calculate(quantity: 48, cartonPack: 24);

      expect(breakdown.fullBoxes, equals(2));
      expect(breakdown.looseUnits, equals(0));
      expect(breakdown.boxedUnits, equals(48));
      expect(breakdown.tradeNomenclature, equals('2 Boxes'));
      expect(breakdown.dispatchSummary, contains('2 Full Boxes (48 pcs) — Zero Loose Units'));
    });

    test('Calculates mixed full cartons and loose units', () {
      final breakdown = PackagingHelper.calculate(quantity: 52, cartonPack: 24);

      expect(breakdown.fullBoxes, equals(2));
      expect(breakdown.looseUnits, equals(4));
      expect(breakdown.boxedUnits, equals(48));
      expect(breakdown.tradeNomenclature, equals('2 Boxes + 4 Loose'));
      expect(breakdown.dispatchSummary, contains('2 Full Boxes (48 pcs)  +  🧴 4 Loose Pieces'));
    });

    test('Calculates loose units when quantity is less than one full carton', () {
      final breakdown = PackagingHelper.calculate(quantity: 7, cartonPack: 24);

      expect(breakdown.fullBoxes, equals(0));
      expect(breakdown.looseUnits, equals(7));
      expect(breakdown.boxedUnits, equals(0));
      expect(breakdown.tradeNomenclature, equals('7 Loose'));
      expect(breakdown.dispatchSummary, contains('7 Loose Pieces (Less than 1 full carton)'));
    });

    test('Handles single box singular vs plural grammar', () {
      final singleBox = PackagingHelper.calculate(quantity: 24, cartonPack: 24);
      expect(singleBox.tradeNomenclature, equals('1 Box'));

      final multiBox = PackagingHelper.calculate(quantity: 72, cartonPack: 24);
      expect(multiBox.tradeNomenclature, equals('3 Boxes'));
    });

    test('Handles zero or unassigned carton pack safely', () {
      final zeroCarton = PackagingHelper.calculate(quantity: 15, cartonPack: 0);

      expect(zeroCarton.fullBoxes, equals(0));
      expect(zeroCarton.looseUnits, equals(15));
      expect(zeroCarton.boxedUnits, equals(0));
      expect(zeroCarton.tradeNomenclature, equals('15 Loose'));
    });
  });
}

