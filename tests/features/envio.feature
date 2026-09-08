# language: es
Característica: Envío gratis del carrito
  Como cliente de la tienda
  Quiero que el envío sea gratis cuando el pedido lo justifique
  Para no pagar de más por productos que ya califican

  Reglas de negocio que fijan este comportamiento (no están en discusión aquí,
  solo se documentan como criterio de aceptación):
    1. El umbral de $50.000 se evalúa sobre el monto YA con descuentos
       aplicados (cupones y promociones), no sobre el subtotal.
    2. El IVA se suma al monto (ya con descuentos) antes de compararlo contra
       el umbral.
    3. Las promociones descuentan del monto comparado contra el umbral
       exactamente igual que los cupones.
    4. Cuando el monto con descuentos e IVA es exactamente $50.000 el envío
       es gratis (el umbral es inclusivo).

  Salvo que un paso diga lo contrario, los pedidos de este documento son a la
  región "metropolitana" (tarifa $3.990 cuando se cobra), no traen cupones ni
  promociones, y el cliente no es nuevo.

  Esquema del escenario: Los bordes del umbral de envío gratis, sin cupones ni promociones
    Dado un pedido a la región metropolitana con un producto de $<precio> y cantidad 1
    Cuando se calcula el envío del pedido
    Entonces el envío debe costar "<envio>"

    # El monto que se compara contra el umbral es precio + IVA (19%), sin
    # cupones ni promociones en este escenario, así que ya no coincide con el
    # precio del producto: $50.000 con IVA equivalen a un precio de $42.017.
    #
    # Fila 1: precio $42.016 -> con IVA $49.999, un peso bajo el umbral -> se cobra.
    # Fila 2: precio $42.017 -> con IVA $50.000, exactamente en el umbral -> gratis (decisión 4).
    # Fila 3: precio $42.018 -> con IVA $50.001, un peso sobre el umbral -> gratis.
    # Fila 4: precio $45.000 -> con IVA $53.550, sobre el umbral -> gratis. Antes de
    #         este cambio de reglas este mismo precio daba "se cobra" (el IVA no
    #         contaba); ahora sí cuenta y el resultado se invierte (decisión 2).
    Ejemplos:
      | precio  | envio  |
      | 42.016  | $3.990 |
      | 42.017  | $0     |
      | 42.018  | $0     |
      | 45.000  | $0     |

  Escenario: Un cupón que baja el monto por debajo del umbral hace que se cobre el envío
    Dado un pedido a la región metropolitana con un producto de $60.000 y cantidad 1
    Y un cupón "30OFF" de 30% de descuento
    Cuando se calcula el envío del pedido
    Entonces el envío debe costar "$3.990"

    # Subtotal $60.000 (con IVA $71.400, sobre el umbral) menos 30% ($18.000)
    # = $42.000. Con IVA: $42.000 + $7.980 = $49.980 (bajo el umbral). Si el
    # umbral se evaluara sobre el subtotal el envío sería gratis; como se
    # evalúa después del descuento (y con IVA), se cobra (decisión 1).

  Escenario: Una promoción que baja el monto por debajo del umbral hace que se cobre el envío
    Dado un pedido a la región metropolitana con un producto de $4.300 y cantidad 10
    Y el pedido tiene la promoción "volumen" (descuento por volumen)
    Cuando se calcula el envío del pedido
    Entonces el envío debe costar "$3.990"

    # Subtotal $43.000 (con IVA $51.170, sobre el umbral). Las 10 unidades
    # activan el 5% de descuento por volumen: $43.000 - $2.150 = $40.850. Con
    # IVA: $40.850 + $7.761 = $48.611 (bajo el umbral). El resultado es igual
    # que con el cupón: la promoción descuenta del monto comparado contra el
    # umbral exactamente igual que un cupón (decisión 3).

  Escenario: El cliente nuevo no paga envío aunque el pedido no llegue al umbral
    Dado un pedido a la región metropolitana con un producto de $10.000 y cantidad 1
    Y el cliente es nuevo
    Cuando se calcula el envío del pedido
    Entonces el envío debe costar "$0"

    # $10.000 está muy por debajo del umbral de $50.000: sin la condición de
    # cliente nuevo se cobrarían $3.990. El envío gratis para clientes nuevos
    # no depende del monto del pedido, es una regla aparte del umbral.
