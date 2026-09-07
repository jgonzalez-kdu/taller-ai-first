"""Pruebas de `carrito.dinero.formatear`: separador de miles con punto y
signo `$`, incluyendo montos negativos (así se muestran los descuentos en
el resumen del CLI)."""

from carrito.dinero import formatear


def test_formatea_monto_positivo_con_separador_de_miles():
    assert formatear(85_000) == "$85.000"


def test_formatea_monto_con_varios_separadores_de_miles():
    assert formatear(1_234_567) == "$1.234.567"


def test_formatea_monto_negativo():
    assert formatear(-15_000) == "-$15.000"


def test_formatea_cero():
    assert formatear(0) == "$0"
