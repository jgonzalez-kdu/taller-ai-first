"""Steps de pytest-bdd para tests/features/envio.feature.

Traduce los criterios de aceptación de la regla de envío gratis a tests
ejecutables. Cada escenario construye su propio `Pedido` y el paso "Cuando"
pasa por `resumen()` (la misma función que usa el CLI), no por las funciones
internas de `envio.py`, para verificar el comportamiento como caja negra.
"""

from pytest_bdd import given, parsers, scenarios, then, when

from carrito.modelo import Cupon, Linea, Pedido, Producto
from carrito.resumen import resumen

scenarios("features/envio.feature")


def pesos(texto: str) -> int:
    """Convierte un monto escrito como "50.000" o "$3.990" a un entero."""
    return int(texto.replace("$", "").replace(".", ""))


@given(
    parsers.parse(
        "un pedido a la región {region} con un producto de ${precio} y cantidad {cantidad:d}"
    ),
    target_fixture="pedido",
    converters={"precio": pesos},
)
def un_pedido_con_un_producto(region, precio, cantidad):
    producto = Producto(sku="SKU-TEST", nombre="Producto de prueba", precio=precio)
    return Pedido(
        numero=1,
        lineas=[Linea(producto=producto, cantidad=cantidad)],
        region=region,
    )


@given(parsers.parse('un cupón "{codigo}" de {porcentaje:d}% de descuento'))
def agrega_cupon_porcentual(pedido, codigo, porcentaje):
    pedido.cupones.append(Cupon(codigo=codigo, tipo="porcentaje", valor=porcentaje))


@given(parsers.parse('el pedido tiene la promoción "{nombre}" (descuento por volumen)'))
def agrega_promocion(pedido, nombre):
    pedido.promociones.append(nombre)


@given("el cliente es nuevo")
def marca_cliente_nuevo(pedido):
    pedido.cliente_nuevo = True


@when("se calcula el envío del pedido", target_fixture="envio_calculado")
def calcula_envio(pedido):
    return resumen(pedido)["Envío"]


@then(
    parsers.parse('el envío debe costar "{monto_esperado}"'),
    converters={"monto_esperado": pesos},
)
def verifica_envio(envio_calculado, monto_esperado):
    assert envio_calculado == monto_esperado
