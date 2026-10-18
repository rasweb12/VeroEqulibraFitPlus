# P3 — Scanner EAN/UPC

Estado: **PARCIAL**.

O Flutter usa `mobile_scanner` no Android para EAN-8, EAN-13, UPC-A e UPC-E. O código é validado com dígito verificador GS1; UPC-A válido é normalizado para GTIN-13. Leituras repetidas são bloqueadas durante o resultado e há entrada manual validada.

O teste de câmera física continua não executado por ausência de emulador/dispositivo ADB nesta estação. Consulta interna, cadastro de produto e sincronização ainda dependem do catálogo interno descrito na matriz.
