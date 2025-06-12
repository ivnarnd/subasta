// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Subasta {
    address public propietario;
    address public mejorPostor;
    uint public mejorOferta;

    uint public finDeLaSubasta;
    uint public comision = 2;
    
    uint public extensionDeTiempo = 10 minutes;
    bool public finalizada = false;

    struct Oferta {
        address postor;
        uint monto;
    }

    mapping(address => Oferta[]) public ofertas;

    Oferta[] public todasLasOfertas;

    mapping(address => uint) public devolucionesPendientes;

    event NuevaOferta(address indexed postor, uint monto);
    event SubastaFinalizada(address ganador, uint monto);
    event Retiro(address postor, uint monto);

    modifier soloAntesDelFin() {
        require(block.timestamp < finDeLaSubasta, "La subasta ya finalizo");
        _;
    }

    modifier soloDespuesDelFin() {
        require(block.timestamp >= finDeLaSubasta, "La subasta sigue activa");
        _;
    }

    modifier soloPropietario() {
        require(msg.sender == propietario, "Solo el propietario puede ejecutar esto");
        _;
    }

    constructor(uint _duracionEnSegundos) {
        propietario = msg.sender;
        finDeLaSubasta = block.timestamp + _duracionEnSegundos;
    }

    function ofertar() external payable soloAntesDelFin {
        require(msg.value >= (mejorOferta * 105) / 100, "La oferta debe superar al menos en un 5% la actual");
        if (mejorOferta != 0) {
            devolucionesPendientes[mejorPostor] += mejorOferta;
        }

        Oferta memory nuevaOferta = Oferta(msg.sender, msg.value);
        ofertas[msg.sender].push(nuevaOferta);
        todasLasOfertas.push(nuevaOferta);

        mejorPostor = msg.sender;
        mejorOferta = msg.value;

        if (finDeLaSubasta - block.timestamp < 10 minutes) {
            finDeLaSubasta += extensionDeTiempo;
        }

        emit NuevaOferta(msg.sender, msg.value);
    }

    function retirar() external {
        uint monto = devolucionesPendientes[msg.sender];
        require(monto > 0, "No hay nada para retirar");

        devolucionesPendientes[msg.sender] = 0;

        (bool exito, ) = payable(msg.sender).call{value: monto}("");
        require(exito, "Fallo el envio del retiro");

        emit Retiro(msg.sender, monto);
    }

    function finalizarSubasta() external soloPropietario soloDespuesDelFin {
        require(!finalizada, "La subasta ya fue finalizada");
        finalizada = true;

        uint montoComision = (mejorOferta * comision) / 100;
        uint montoParaPropietario = mejorOferta - montoComision;

        (bool exito, ) = payable(propietario).call{value: montoParaPropietario}("");
        require(exito, "Fallo el envio al propietario");

        emit SubastaFinalizada(mejorPostor, mejorOferta);
    }

    function obtenerGanador() external view soloDespuesDelFin returns (address, uint) {
        return (mejorPostor, mejorOferta);
    }

    function verOfertas(address _postor) external view returns (Oferta[] memory) {
        return ofertas[_postor];
    }

    function verTodasLasOfertas() external view returns (Oferta[] memory) {
        return todasLasOfertas;
    }

    function reembolsoParcial() external {
        Oferta[] storage misOfertas = ofertas[msg.sender];
        require(misOfertas.length > 1, "Debes tener al menos dos ofertas");

        uint reembolsable = 0;

        for (uint i = 0; i < misOfertas.length - 1; i++) {
            reembolsable += misOfertas[i].monto;
            misOfertas[i].monto = 0;
        }

        require(reembolsable > 0, "No hay monto para reembolsar");

        (bool exito, ) = payable(msg.sender).call{value: reembolsable}("");
        require(exito, "Fallo el envio del reembolso parcial");

        emit Retiro(msg.sender, reembolsable);
    }
}
