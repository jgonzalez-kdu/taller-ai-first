# language: es
Característica: Envío gratis del carrito
  Como cliente de la tienda
  Quiero que el envío sea gratis cuando el pedido lo justifique
  Para no pagar de más por productos que ya califican

  Reglas de negocio que fijan este comportamiento (no están en discusión aquí,
  solo se documentan como criterio de aceptación):
    1. El umbral de $50.000 se evalúa sobre el monto YA con descuentos
       aplicados (cupones y promociones), no sobre el subtotal.
    2. El IVA no se suma al monto que se compara contra el umbral.
    3. Las promociones descuentan del monto comparado contra el umbral
       exactamente igual que los cupones.
    4. Con $50.000 exactos el envío es gratis (el umbral es inclusivo).

  Salvo que un paso diga lo contrario, los pedidos de este documento son a la
  región "metropolitana" (tarifa $3.990 cuando se cobra), no traen cupones ni
  promociones, y el cliente no es nuevo.

  Esquema del escenario: Los bordes del umbral de envío gratis, sin cupones ni promociones
    Dado un pedido a la región metropolitana con un producto de $<precio> y cantidad 1
    Cuando se calcula el envío del pedido
    Entonces el envío debe costar "<envio>"

    # Fila 1: un peso bajo el umbral -> se cobra.
    # Fila 2: exactamente en el umbral -> gratis (confirma la decisión 4).
    # Fila 3: un peso sobre el umbral -> gratis.
    # Fila 4: bajo el umbral en pesos, pero $45.000 x 1,19 (IVA) = $53.550,
    #         que sí superaría el umbral. Se sigue cobrando porque el IVA no
    #         cuenta para el umbral (confirma la decisión 2).
    Ejemplos:
      | precio  | envio  |
      | 49.999  | $3.990 |
      | 50.000  | $0     |
      | 50.001  | $0     |
      | 45.000  | $3.990 |

  Escenario: Un cupón que baja el monto por debajo del umbral hace que se cobre el envío
    Dado un pedido a la región metropolitana con un producto de $60.000 y cantidad 1
    Y un cupón "20OFF" de 20% de descuento
    Cuando se calcula el envío del pedido
    Entonces el envío debe costar "$3.990"

    # Subtotal $60.000 (sobre el umbral) menos 20% ($12.000) = $48.000 (bajo el
    # umbral). Si el umbral se evaluara sobre el subtotal el envío sería
    # gratis; como se evalúa después del descuento, se cobra (decisión 1).

  Escenario: Una promoción que baja el monto por debajo del umbral hace que se cobre el envío
    Dado un pedido a la región metropolitana con un producto de $5.020 y cantidad 10
    Y el pedido tiene la promoción "volumen" (descuento por volumen)
    Cuando se calcula el envío del pedido
    Entonces el envío debe costar "$3.990"

    # Subtotal $50.200 (sobre el umbral). Las 10 unidades activan el 5% de
    # descuento por volumen: $50.200 - $2.510 = $47.690 (bajo el umbral). El
    # resultado es igual que con el cupón: la promoción descuenta del monto
    # comparado contra el umbral exactamente igual que un cupón (decisión 3).

  Escenario: El cliente nuevo no paga envío aunque el pedido no llegue al umbral
    Dado un pedido a la región metropolitana con un producto de $10.000 y cantidad 1
    Y el cliente es nuevo
    Cuando se calcula el envío del pedido
    Entonces el envío debe costar "$0"

    # $10.000 está muy por debajo del umbral de $50.000: sin la condición de
    # cliente nuevo se cobrarían $3.990. El envío gratis para clientes nuevos
    # no depende del monto del pedido, es una regla aparte del umbral.
