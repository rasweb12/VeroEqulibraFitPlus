class BarcodeValidation {
  const BarcodeValidation._(this.gtin, this.error);
  const BarcodeValidation.valid(String gtin) : this._(gtin, null);
  const BarcodeValidation.invalid(String error) : this._('', error);
  final String gtin;
  final String? error;
  bool get isValid => error == null;
}

/// Validates numeric GTIN-8, UPC-A and GTIN-13 values with the GS1 check digit.
class BarcodeValidator {
  static BarcodeValidation validate(String raw) {
    final code = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (code.length == 12) {
      return _validate(code) ? BarcodeValidation.valid('0$code') : const BarcodeValidation.invalid('Código UPC-A inválido.');
    }
    if (code.length == 8 || code.length == 13) {
      return _validate(code) ? BarcodeValidation.valid(code) : const BarcodeValidation.invalid('Dígito verificador inválido.');
    }
    return const BarcodeValidation.invalid('Use EAN-8, EAN-13 ou UPC-A válido.');
  }

  static bool _validate(String value) {
    if (!RegExp(r'^\d+$').hasMatch(value)) return false;
    var sum = 0;
    for (var index = 0; index < value.length - 1; index++) {
      final digit = int.parse(value[value.length - 2 - index]);
      sum += digit * (index.isEven ? 3 : 1);
    }
    return (10 - (sum % 10)) % 10 == int.parse(value[value.length - 1]);
  }
}
