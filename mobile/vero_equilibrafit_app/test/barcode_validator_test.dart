import 'package:flutter_test/flutter_test.dart';
import 'package:vero_equilibrafit_app/features/nutrition/data/barcode_validator.dart';

void main() {
  test('validates EAN-13 and normalizes UPC-A to GTIN-13', () {
    expect(BarcodeValidator.validate('7891000100103').isValid, isTrue);
    expect(BarcodeValidator.validate('036000291452').gtin, '0036000291452');
  });
  test('validates EAN-8 and rejects invalid check digits', () {
    expect(BarcodeValidator.validate('96385074').isValid, isTrue);
    expect(BarcodeValidator.validate('7891000100104').isValid, isFalse);
  });
}
