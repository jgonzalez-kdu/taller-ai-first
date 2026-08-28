"""Verifica el orden de aplicación de descuentos documentado en el README
y en el docstring de `carrito.descuentos`: primero el cupón porcentual,
después el vale de monto fijo.
"""

from carrito.descuentos import total_con_descuentos
from carrito.modelo import Cupon, Linea, Pedido, Producto


def test_cupon_porcentual_se_aplica_antes_que_vale_monto_fijo():
    producto = Producto(sku="SKU-1", nombre="Producto de prueba", precio=100_000)
    pedido = Pedido(
        numero=1,
        lineas=[Linea(producto=producto, cantidad=1)],
        cupones=[
            Cupon(codigo="10OFF", tipo="porcentaje", valor=10),
            Cupon(codigo="VALE5000", tipo="monto", valor=5_000),
        ],
    )

    # Subtotal: 100.000
    # 1) Cupón porcentual (10%): 100.000 - 10.000 = 90.000
    # 2) Vale de monto fijo ($5.000): 90.000 - 5.000 = 85.000
    assert total_con_descuentos(pedido) == 85_000
