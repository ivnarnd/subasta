# Contrato de Subasta

Este proyecto implementa un contrato inteligente de subasta con funcionalidades básicas y avanzadas. Fue desarrollado como ejercicio de práctica para aplicar conceptos de Solidity, incluyendo manejo de ofertas, reembolsos, eventos, y seguridad en el manejo de fondos.

## Descripción general

El contrato permite llevar a cabo una subasta entre múltiples participantes. Cada oferta debe superar a la anterior por al menos un 5%. La subasta puede extenderse automáticamente si una oferta se realiza en los últimos minutos. Además, se permite el retiro de fondos por parte de los oferentes no ganadores, así como el reembolso parcial de ofertas anteriores.

---

## Estructura y funcionalidades

### Constructor

```solidity
constructor(uint _duracionEnSegundos)
```

Inicializa la subasta con una duración específica. El `msg.sender` se define como el propietario del contrato y la subasta comienza al momento de despliegue.

---

### Función `ofertar`

```solidity
function ofertar() external payable
```

- Permite realizar una oferta si:
  - La subasta sigue activa.
  - El monto supera al menos en un 5% la mejor oferta actual.
- Si el oferente ya había ofertado antes, el monto anterior queda como retiro disponible.
- Si la oferta se realiza en los últimos 10 minutos de la subasta, esta se extiende automáticamente 10 minutos más.

---

### Función `finalizarSubasta`

```solidity
function finalizarSubasta() external
```

- Solo puede ser ejecutada por el propietario.
- Puede llamarse únicamente después del fin de la subasta.
- Envía al propietario el monto de la oferta ganadora, menos un 2% de comisión.
- Marca la subasta como finalizada.

---

### Función `obtenerGanador`

```solidity
function obtenerGanador() external view returns (address, uint)
```

- Devuelve la dirección del mejor postor y el monto de su oferta.
- Solo se puede consultar una vez que la subasta finalizó.

---

### Función `verOfertas`

```solidity
function verOfertas(address _postor) external view returns (Oferta[] memory)
```

- Devuelve un array con todas las ofertas realizadas por una dirección específica.

---

### Función `verTodasLasOfertas`

```solidity
function verTodasLasOfertas() external view returns (Oferta[] memory)
```

- Devuelve un array con todas las ofertas realizadas durante la subasta, sin importar quién las haya hecho.

---

### Función `retirar`

```solidity
function retirar() external
```

- Permite a los participantes no ganadores retirar los fondos correspondientes a sus ofertas anteriores.
- Solo disponible después de finalizada la subasta.
- Utiliza `call` para enviar ETH de forma segura.

---

### Función `reembolsoParcial`

```solidity
function reembolsoParcial() external
```

- Permite a un usuario que realizó varias ofertas retirar las ofertas anteriores a su última oferta válida mientras la subasta sigue activa.

---

## Estructura de datos

### Struct `Oferta`

```solidity
struct Oferta {
    address postor;
    uint monto;
}
```

- Se utiliza para almacenar el historial de ofertas.

---

## Eventos

- `NuevaOferta(address postor, uint monto)`
- `SubastaFinalizada(address ganador, uint monto)`
- `Retiro(address postor, uint monto)`

