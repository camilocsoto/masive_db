-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost:3308
-- Tiempo de generación: 30-08-2024 a las 10:15:20
-- Versión del servidor: 10.4.28-MariaDB
-- Versión de PHP: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";



--
-- Base de datos: `neutech`
--
CREATE DATABASE IF NOT EXISTS `neutech` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `neutech`;

DELIMITER $$
--
-- Procedimientos
--
DROP PROCEDURE IF EXISTS `comprarF`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `comprarF` (IN `documento` VARCHAR(15), IN `idProducto` INT, IN `cantidad` INT, IN `fecha` DATE)   BEGIN

    
    IF EXISTS (SELECT 1 FROM Factura WHERE Cliente_idCliente = (SELECT idCliente FROM Cliente WHERE
cedula = documento LIMIT 1) AND fecha = fecha LIMIT 1) THEN
INSERT INTO detalle(cantidad,precio,Factura_idFactura,Producto_idProducto) VALUES 
(cantidad,(SELECT precio * cantidad FROM Producto WHERE idProducto = idProducto LIMIT 1),
(SELECT idFactura FROM Factura WHERE Cliente_idCliente = (SELECT idCliente FROM Cliente WHERE
cedula = documento LIMIT 1)),idProducto);

        
        SELECT 'Compra realizada exitosamente' AS mensaje;

UPDATE producto SET stock = stock - cantidad WHERE producto.idProducto = idProducto LIMIT 1;
    ELSE
        
        INSERT INTO Factura (fecha,Cliente_idCliente)
        VALUES (fecha, (SELECT idCliente FROM Cliente WHERE
cedula = documento LIMIT 1));
        SELECT 'Factura creada exitosamente.' AS mensaje;
CALL comprarF(documento,idProducto,cantidad,fecha);
    END IF;
END$$

DROP PROCEDURE IF EXISTS `comprarP`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `comprarP` (IN `documento` VARCHAR(15), IN `idProducto` INT, IN `cantidad` INT)   BEGIN

    
    IF EXISTS (SELECT 1 FROM Factura WHERE Cliente_idCliente = (SELECT idCliente FROM Cliente WHERE
cedula = documento LIMIT 1) AND fecha = CURDATE() LIMIT 1) THEN
INSERT INTO detalle(cantidad,precio,Factura_idFactura,Producto_idProducto) VALUES 
(cantidad,(SELECT precio * cantidad FROM Producto WHERE idProducto = idProducto LIMIT 1),
(SELECT idFactura FROM Factura WHERE Cliente_idCliente = (SELECT idCliente FROM Cliente WHERE
cedula = documento LIMIT 1)),idProducto);

        
        SELECT 'Compra realizada exitosamente' AS mensaje;

UPDATE producto SET stock = stock - cantidad WHERE producto.idProducto = idProducto LIMIT 1;
    ELSE
        
        INSERT INTO Factura (fecha,Cliente_idCliente)
        VALUES (CURDATE(), (SELECT idCliente FROM Cliente WHERE
cedula = documento LIMIT 1));
        SELECT 'Factura creada exitosamente.' AS mensaje;
CALL comprarP(documento,idProducto,cantidad);
    END IF;
END$$

DROP PROCEDURE IF EXISTS `generarFactura`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `generarFactura` (IN `documento` VARCHAR(15), IN `fecha` DATE)   BEGIN

IF EXISTS (SELECT 1 FROM Factura WHERE Cliente_idCliente = (SELECT idCliente FROM Cliente WHERE
cedula = documento LIMIT 1) AND Factura.fecha = fecha) THEN

SELECT '<<Neutech>>' AS Empresa;
SELECT CONCAT('Cliente: ', nombres, ' ', apellidos, '\r\nDocumento: ', cedula, '\r\nCorreo: ', correo, '\r\nTelefono: ', telefono) AS Cliente
FROM Cliente WHERE cedula = documento;

SELECT idFactura, fecha FROM Factura WHERE Cliente_idCliente = (SELECT idCliente FROM Cliente WHERE
cedula = documento LIMIT 1) AND Factura.fecha = fecha;


SELECT 
    p.nombreProducto,
    p.descripcion,
    d.cantidad,
    d.precio AS precio_unitario
FROM 
    Cliente c
JOIN 
    Factura f ON c.idCliente = f.Cliente_idCliente
JOIN 
    Detalle d ON f.idFactura = d.Factura_idFactura
JOIN 
    Producto p ON d.Producto_idProducto = p.idProducto
WHERE 
    c.cedula = documento
    AND f.fecha = fecha;
SELECT 
    SUM(d.precio) AS subtotal,
    '19%' AS iva,
    SUM(d.precio) * 0.19 + SUM(d.precio) AS total_factura
FROM 
    Cliente c
JOIN 
    Factura f ON c.idCliente = f.Cliente_idCliente
JOIN 
    Detalle d ON f.idFactura = d.Factura_idFactura
WHERE 
    c.cedula = documento
    AND f.fecha = fecha;

ELSE
SELECT CONCAT('<<Neutech>> \n No existe una factura para el cliente con el Numero de documento: ', documento, ' fecha: ', fecha) AS mensaje;
END IF;

END$$

DROP PROCEDURE IF EXISTS `MejoresCompradores`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `MejoresCompradores` ()   BEGIN

SELECT 
    c.idCliente,
    c.nombres,
    c.apellidos,
    COUNT(f.idFactura) AS numeroCompras,
    SUM(d.cantidad * p.precio) AS totalGastado
FROM 
    Cliente c
INNER JOIN 
    Factura f ON c.idCliente = f.Cliente_idCliente
INNER JOIN 
    Detalle d ON f.idFactura = d.Factura_idFactura
INNER JOIN 
    Producto p ON d.producto_idProducto = p.idProducto
GROUP BY 
    c.idCliente, c.nombres, c.apellidos
ORDER BY 
    totalGastado DESC;
END$$

DROP PROCEDURE IF EXISTS `ProductosVendidosPorCategoria`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `ProductosVendidosPorCategoria` (IN `categoria` VARCHAR(15))   BEGIN
    SELECT 
        p.idProducto,
        p.nombreProducto AS productoUnitario,
        p.precio,
        c.nombreCategoria,
        d.cantidad,
        f.fecha
    FROM 
        Producto p
    INNER JOIN 
        Categoria c ON p.categoria_idCategoria = c.idCategoria
    INNER JOIN 
        Detalle d ON p.idProducto = d.producto_idProducto
    INNER JOIN 
        Factura f ON d.Factura_idFactura = f.idFactura
    WHERE 
        c.nombreCategoria = categoria;
END$$

DROP PROCEDURE IF EXISTS `ProductosVendidosPorFecha`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `ProductosVendidosPorFecha` (IN `fechaVenta` DATE)   BEGIN
    DECLARE totalVentas INT;

    SELECT 
        COUNT(*) INTO totalVentas
    FROM 
        Factura f
    WHERE 
        f.fecha = fechaVenta;
    IF totalVentas = 0 THEN
        SELECT 'No hay productos vendidos en la fecha ingresada' AS mensaje;
    ELSE

        SELECT 
            p.idProducto,
            p.nombreProducto, 
            p.precio AS precioUnitario,
            c.nombreCategoria,
            d.cantidad,
            f.fecha,
            (p.precio * d.cantidad) AS ganancia
        FROM 
            Producto p
        INNER JOIN 
            Categoria c ON p.categoria_idCategoria = c.idCategoria
        INNER JOIN 
            Detalle d ON p.idProducto = d.producto_idProducto
        INNER JOIN 
            Factura f ON d.Factura_idFactura = f.idFactura
        WHERE 
            f.fecha = fechaVenta;
        SELECT 
            SUM(d.cantidad) AS totalProductosVendidos,
            SUM(p.precio * d.cantidad) AS gananciaTotal
        FROM 
            Producto p
        INNER JOIN 
            Detalle d ON p.idProducto = d.producto_idProducto
        INNER JOIN 
            Factura f ON d.Factura_idFactura = f.idFactura
        WHERE 
            f.fecha = fechaVenta;
    END IF;
END$$

DROP PROCEDURE IF EXISTS `Top5ProductosMasVendidos`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `Top5ProductosMasVendidos` ()   BEGIN
    SELECT 
        p.idProducto,
        p.nombreProducto,
        SUM(d.cantidad) AS cantidadTotalVendida
    FROM 
        Producto p
    INNER JOIN 
        Detalle d ON p.idProducto = d.producto_idProducto
    GROUP BY 
        p.idProducto, p.nombreProducto
    ORDER BY 
        cantidadTotalVendida DESC
    LIMIT 5;
END$$

DROP PROCEDURE IF EXISTS `verFacturas`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `verFacturas` (IN `tipoDoc` VARCHAR(100))   BEGIN
SELECT * FROM factura WHERE Cliente_idCliente = ( 
    SELECT idCliente FROM cliente WHERE cedula = tipoDoc 
)
;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categoria`
--

DROP TABLE IF EXISTS `categoria`;
CREATE TABLE IF NOT EXISTS `categoria` (
  `idCategoria` int(11) NOT NULL AUTO_INCREMENT,
  `nombreCategoria` varchar(30) NOT NULL,
  PRIMARY KEY (`idCategoria`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `categoria`
--

INSERT INTO `categoria` (`idCategoria`, `nombreCategoria`) VALUES
(1, 'Memoria RAM'),
(2, 'Disco Duro'),
(3, 'Tarjeta Gráfica'),
(4, 'Placa Base'),
(5, 'Fuente de Alimentación'),
(6, 'Procesador'),
(7, 'Ventiladores y Refrigeración'),
(8, 'Cajas de Computadora'),
(9, 'Teclado'),
(10, 'Mouse'),
(11, 'Monitor');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cliente`
--

DROP TABLE IF EXISTS `cliente`;
CREATE TABLE IF NOT EXISTS `cliente` (
  `idCliente` int(11) NOT NULL AUTO_INCREMENT,
  `nombres` varchar(45) NOT NULL,
  `apellidos` varchar(45) NOT NULL,
  `cedula` varchar(15) NOT NULL,
  `telefono` varchar(10) NOT NULL,
  `correo` varchar(45) NOT NULL,
  `TipoDocumento_idDocumento` int(11) NOT NULL,
  PRIMARY KEY (`idCliente`,`TipoDocumento_idDocumento`),
  KEY `fk_Cliente_TipoDocumento_idx` (`TipoDocumento_idDocumento`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `cliente`
--

INSERT INTO `cliente` (`idCliente`, `nombres`, `apellidos`, `cedula`, `telefono`, `correo`, `TipoDocumento_idDocumento`) VALUES
(1, 'Carlos', 'Pérez', '1234567890', '0987654321', 'carlos.perez@gmail.com', 5),
(2, 'María', 'Gómez', '2345678901', '0987654322', 'maria.gomez@gmail.com', 6),
(3, 'Juan', 'Rodríguez', '3456789012', '0987654323', 'juan.rodriguez@gmail.com', 7),
(4, 'Ana', 'López', '4567890123', '0987654324', 'ana.lopez@gmail.com', 8),
(5, 'Luis', 'Martínez', '5678901234', '0987654325', 'luis.martinez@gmail.com', 5),
(6, 'Sofía', 'García', '6789012345', '0987654326', 'sofia.garcia@gmail.com', 6),
(7, 'José', 'Fernández', '7890123456', '0987654327', 'jose.fernandez@gmail.com', 7),
(8, 'Laura', 'Hernández', '8901234567', '0987654328', 'laura.hernandez@gmail.com', 8),
(9, 'Pedro', 'Ramírez', '9012345678', '0987654329', 'pedro.ramirez@gmail.com', 5),
(10, 'Isabel', 'Torres', '0123456789', '0987654330', 'isabel.torres@gmail.com', 6),
(11, 'Fernando', 'Díaz', '1123456789', '0987654331', 'fernando.diaz@gmail.com', 7),
(12, 'Elena', 'Sánchez', '2123456789', '0987654332', 'elena.sanchez@gmail.com', 8),
(13, 'Miguel', 'Castillo', '3123456789', '0987654333', 'miguel.castillo@gmail.com', 5),
(14, 'Patricia', 'Molina', '4123456789', '0987654334', 'patricia.molina@gmail.com', 6),
(15, 'Andrés', 'Suárez', '5123456789', '0987654335', 'andres.suarez@gmail.com', 7),
(16, 'Claudia', 'Rojas', '6123456789', '0987654336', 'claudia.rojas@gmail.com', 8),
(17, 'Ricardo', 'Vega', '7123456789', '0987654337', 'ricardo.vega@gmail.com', 5),
(18, 'Carmen', 'Cruz', '8123456789', '0987654338', 'carmen.cruz@gmail.com', 6),
(19, 'Julio', 'Méndez', '9123456789', '0987654339', 'julio.mendez@gmail.com', 7),
(20, 'Gloria', 'Flores', '1234509876', '0987654340', 'gloria.flores@gmail.com', 8);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle`
--

DROP TABLE IF EXISTS `detalle`;
CREATE TABLE IF NOT EXISTS `detalle` (
  `idDetalle` int(11) NOT NULL AUTO_INCREMENT,
  `cantidad` int(11) NOT NULL,
  `precio` decimal(10,0) NOT NULL,
  `Factura_idFactura` int(11) NOT NULL,
  `Producto_idProducto` int(11) NOT NULL,
  PRIMARY KEY (`idDetalle`,`Factura_idFactura`,`Producto_idProducto`),
  KEY `fk_Detalle_Factura1_idx` (`Factura_idFactura`),
  KEY `fk_Detalle_Producto1_idx` (`Producto_idProducto`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `detalle`
--

INSERT INTO `detalle` (`idDetalle`, `cantidad`, `precio`, `Factura_idFactura`, `Producto_idProducto`) VALUES
(1, 2, 680000, 10, 1),
(2, 2, 680000, 11, 1),
(3, 2, 680000, 12, 2),
(4, 8, 2720000, 12, 3),
(5, 1, 340000, 12, 3),
(6, 2, 680000, 13, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `factura`
--

DROP TABLE IF EXISTS `factura`;
CREATE TABLE IF NOT EXISTS `factura` (
  `idFactura` int(11) NOT NULL AUTO_INCREMENT,
  `fecha` date NOT NULL,
  `Cliente_idCliente` int(11) NOT NULL,
  PRIMARY KEY (`idFactura`,`Cliente_idCliente`),
  KEY `fk_Factura_Cliente1_idx` (`Cliente_idCliente`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `factura`
--

INSERT INTO `factura` (`idFactura`, `fecha`, `Cliente_idCliente`) VALUES
(1, '2024-08-18', 12),
(2, '2024-08-19', 9),
(3, '2024-08-19', 1),
(4, '2024-08-19', 13),
(5, '2024-08-19', 2),
(6, '2024-08-19', 18),
(7, '2024-08-19', 5),
(10, '2024-08-19', 17),
(11, '2024-08-19', 10),
(12, '2024-08-19', 6),
(13, '2024-07-12', 4),
(14, '2024-08-30', 12),
(15, '2024-08-30', 6);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `marca`
--

DROP TABLE IF EXISTS `marca`;
CREATE TABLE IF NOT EXISTS `marca` (
  `idMarca` int(11) NOT NULL AUTO_INCREMENT,
  `nombreMarca` varchar(30) NOT NULL,
  PRIMARY KEY (`idMarca`)
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `marca`
--

INSERT INTO `marca` (`idMarca`, `nombreMarca`) VALUES
(1, 'Corsair'),
(2, 'G.Skill'),
(3, 'Kingston'),
(4, 'Crucial'),
(5, 'ADATA'),
(6, 'Seagate'),
(7, 'Western Digital'),
(8, 'Samsung'),
(9, 'SanDisk'),
(10, 'Toshiba'),
(11, 'NVIDIA'),
(12, 'MSI'),
(13, 'Gigabyte'),
(14, 'ASUS'),
(15, 'ASRock'),
(16, 'Biostar'),
(17, 'EVGA'),
(18, 'Cooler Master'),
(19, 'Thermaltake'),
(20, 'Seasonic'),
(21, 'Intel'),
(22, 'AMD'),
(23, 'Noctua'),
(24, 'Be Quiet!'),
(25, 'NZXT'),
(26, 'Fractal Design'),
(27, 'Razer'),
(28, 'Logitech'),
(29, 'SteelSeries'),
(30, 'HyperX'),
(31, 'Roccat');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `producto`
--

DROP TABLE IF EXISTS `producto`;
CREATE TABLE IF NOT EXISTS `producto` (
  `idProducto` int(11) NOT NULL AUTO_INCREMENT,
  `nombreProducto` varchar(45) NOT NULL,
  `descripcion` tinytext NOT NULL,
  `precio` decimal(10,0) NOT NULL,
  `stock` int(11) NOT NULL DEFAULT 20,
  `Marca_idMarca` int(11) NOT NULL,
  `Categoria_idCategoria` int(11) NOT NULL,
  PRIMARY KEY (`idProducto`,`Marca_idMarca`,`Categoria_idCategoria`),
  KEY `fk_Producto_Marca1_idx` (`Marca_idMarca`),
  KEY `fk_Producto_Categoria1_idx` (`Categoria_idCategoria`)
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `producto`
--

INSERT INTO `producto` (`idProducto`, `nombreProducto`, `descripcion`, `precio`, `stock`, `Marca_idMarca`, `Categoria_idCategoria`) VALUES
(1, 'Corsair Vengeance 16GB', 'Memoria RAM DDR4 16GB 3200MHz', 340000, 7, 1, 1),
(2, 'G.Skill Ripjaws V 16GB', 'Memoria RAM DDR4 16GB 3600MHz', 360000, 10, 2, 1),
(3, 'Seagate Barracuda 1TB', 'Disco Duro HDD 1TB 7200RPM', 210000, 9, 6, 2),
(4, 'Western Digital Blue 500GB', 'Disco Duro HDD 500GB 7200RPM', 170000, 10, 7, 2),
(5, 'NVIDIA GeForce GTX 1660', 'Tarjeta Gráfica 6GB GDDR5', 880000, 10, 11, 3),
(6, 'MSI Gaming X RTX 3060', 'Tarjeta Gráfica 12GB GDDR6', 1400000, 10, 12, 3),
(7, 'ASUS ROG Strix B550-F', 'Placa Base ATX B550', 720000, 10, 14, 4),
(8, 'Gigabyte Z490 AORUS', 'Placa Base ATX Z490', 800000, 10, 13, 4),
(9, 'Corsair RM750x', 'Fuente de Alimentación 750W 80+ Gold', 480000, 10, 1, 5),
(10, 'Seasonic FOCUS GX-650', 'Fuente de Alimentación 650W 80+ Gold', 440000, 10, 20, 5),
(11, 'Intel Core i5-12600K', 'Procesador 6 núcleos 12 hilos 3.7GHz', 1200000, 10, 21, 6),
(12, 'AMD Ryzen 5 5600X', 'Procesador 6 núcleos 12 hilos 3.7GHz', 1100000, 10, 22, 6),
(13, 'Noctua NH-U12S', 'Refrigeración por aire 120mm', 280000, 10, 23, 7),
(14, 'Cooler Master Hyper 212', 'Refrigeración por aire 120mm', 200000, 10, 18, 7),
(15, 'NZXT H510', 'Caja ATX con paneles templados', 400000, 10, 25, 8),
(16, 'Fractal Design Meshify C', 'Caja ATX con excelente ventilación', 360000, 10, 26, 8),
(17, 'Razer BlackWidow V3', 'Teclado mecánico RGB', 520000, 10, 27, 9),
(18, 'Logitech G Pro X', 'Teclado mecánico compacto', 460000, 10, 28, 9),
(19, 'Logitech G502 Hero', 'Mouse gaming con 16,000 DPI', 320000, 10, 28, 10),
(20, 'Razer DeathAdder V2', 'Mouse gaming ergonómico', 300000, 10, 27, 10),
(21, 'ASUS VG248QE', 'Monitor 24\" 144Hz Full HD', 880000, 10, 14, 11),
(22, 'Dell UltraSharp U2719D', 'Monitor 27\" QHD IPS', 1400000, 10, 15, 11),
(23, 'Kingston HyperX Fury 8GB', 'Memoria RAM DDR4 8GB 2666MHz', 160000, 10, 3, 1),
(24, 'Crucial Ballistix 8GB', 'Memoria RAM DDR4 8GB 3200MHz', 180000, 10, 4, 1),
(25, 'ADATA HD710 Pro 1TB', 'Disco Duro HDD 1TB 5400RPM', 230000, 10, 5, 2),
(26, 'Toshiba Canvio Basics 2TB', 'Disco Duro HDD 2TB 5400RPM', 290000, 10, 10, 2),
(27, 'ASUS TUF Gaming RTX 3070', 'Tarjeta Gráfica 8GB GDDR6', 1600000, 10, 14, 3),
(28, 'Gigabyte Radeon RX 6700 XT', 'Tarjeta Gráfica 12GB GDDR6', 1750000, 10, 13, 3),
(29, 'MSI MAG B550 TOMAHAWK', 'Placa Base ATX B550', 650000, 10, 12, 4),
(30, 'ASRock B560M Pro4', 'Placa Base Micro-ATX B560', 550000, 10, 15, 4),
(31, 'Thermaltake Toughpower GF1 750W', 'Fuente de Alimentación 750W 80+ Gold', 470000, 10, 19, 5),
(32, 'Be Quiet! Straight Power 11 650W', 'Fuente de Alimentación 650W 80+ Platinum', 500000, 10, 24, 5),
(33, 'AMD Ryzen 7 5800X', 'Procesador 8 núcleos 16 hilos 3.8GHz', 1600000, 10, 22, 6),
(34, 'Intel Core i7-12700K', 'Procesador 12 núcleos 20 hilos 3.6GHz', 1500000, 10, 21, 6),
(35, 'Cooler Master Hyper 212 Black Edition', 'Refrigeración por aire 120mm', 220000, 10, 18, 7),
(36, 'Be Quiet! Dark Rock 4', 'Refrigeración por aire 135mm', 350000, 10, 24, 7),
(37, 'Fractal Design Define 7', 'Caja ATX silenciosa', 600000, 10, 26, 8),
(38, 'Cooler Master HAF XB EVO', 'Caja ATX con excelente ventilación', 550000, 10, 18, 8),
(39, 'Corsair K95 RGB Platinum', 'Teclado mecánico con retroiluminación RGB', 700000, 10, 1, 9),
(40, 'Ducky One 2 Mini', 'Teclado mecánico compacto con retroiluminación RGB', 450000, 10, 2, 9),
(41, 'Razer Viper Ultimate', 'Mouse inalámbrico con 20,000 DPI', 350000, 10, 27, 10),
(42, 'SteelSeries Rival 600', 'Mouse gaming con sensor dual', 320000, 10, 29, 10),
(43, 'AOC 24G2', 'Monitor 24\" 144Hz Full HD', 500000, 10, 14, 11),
(44, 'HP Omen X 27', 'Monitor 27\" 240Hz QHD', 1200000, 10, 15, 11);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipodocumento`
--

DROP TABLE IF EXISTS `tipodocumento`;
CREATE TABLE IF NOT EXISTS `tipodocumento` (
  `idDocumento` int(11) NOT NULL AUTO_INCREMENT,
  `tipoDocumento` varchar(35) NOT NULL,
  PRIMARY KEY (`idDocumento`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `tipodocumento`
--

INSERT INTO `tipodocumento` (`idDocumento`, `tipoDocumento`) VALUES
(5, 'Cédula de Ciudadanía'),
(6, 'Tarjeta de Identidad'),
(7, 'Cédula de Extranjería'),
(8, 'Pasaporte');

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD CONSTRAINT `fk_Cliente_TipoDocumento` FOREIGN KEY (`TipoDocumento_idDocumento`) REFERENCES `tipodocumento` (`idDocumento`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `detalle`
--
ALTER TABLE `detalle`
  ADD CONSTRAINT `fk_Detalle_Factura1` FOREIGN KEY (`Factura_idFactura`) REFERENCES `factura` (`idFactura`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_Detalle_Producto1` FOREIGN KEY (`Producto_idProducto`) REFERENCES `producto` (`idProducto`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `factura`
--
ALTER TABLE `factura`
  ADD CONSTRAINT `fk_Factura_Cliente1` FOREIGN KEY (`Cliente_idCliente`) REFERENCES `cliente` (`idCliente`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `producto`
--
ALTER TABLE `producto`
  ADD CONSTRAINT `fk_Producto_Categoria1` FOREIGN KEY (`Categoria_idCategoria`) REFERENCES `categoria` (`idCategoria`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_Producto_Marca1` FOREIGN KEY (`Marca_idMarca`) REFERENCES `marca` (`idMarca`) ON DELETE NO ACTION ON UPDATE NO ACTION;
COMMIT;
-- Procesos

DELIMITER $$
CREATE PROCEDURE comprarP(IN documento VARCHAR(15), idProducto INT, cantidad INT)
BEGIN
	
    IF EXISTS (SELECT 1 FROM Factura WHERE Cliente_idCliente = (SELECT idCliente FROM Cliente WHERE
	cedula = documento LIMIT 1) AND fecha = CURDATE() LIMIT 1) THEN
	INSERT INTO detalle(cantidad,precio,Factura_idFactura,Producto_idProducto) VALUES 
	(cantidad,(SELECT precio * cantidad FROM Producto WHERE idProducto = idProducto LIMIT 1),
	(SELECT idFactura FROM Factura WHERE Cliente_idCliente = (SELECT idCliente FROM Cliente WHERE
	cedula = documento LIMIT 1)),idProducto);

        SELECT 'La factura con el ID proporcionado ya existe.' AS mensaje;

	UPDATE producto SET stock = stock - cantidad WHERE producto.idProducto = idProducto LIMIT 1;
    ELSE
        INSERT INTO Factura (fecha,Cliente_idCliente)
        VALUES (CURDATE(), (SELECT idCliente FROM Cliente WHERE
	cedula = documento LIMIT 1));
        SELECT 'Factura creada exitosamente.' AS mensaje;
	CALL comprarP(documento,idProducto,cantidad);
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE comprarF(IN documento VARCHAR(15), idProducto INT, cantidad INT)
BEGIN
	
    -- Verifica si existe una factura con el ID proporcionado
    IF EXISTS (SELECT 1 FROM Factura WHERE Cliente_idCliente = (SELECT idCliente FROM Cliente WHERE
	cedula = documento LIMIT 1) AND fecha = fecha LIMIT 1) THEN
	INSERT INTO detalle(cantidad,precio,Factura_idFactura,Producto_idProducto) VALUES 
	(cantidad,(SELECT precio * cantidad FROM Producto WHERE idProducto = idProducto LIMIT 1),
	(SELECT idFactura FROM Factura WHERE Cliente_idCliente = (SELECT idCliente FROM Cliente WHERE
	cedula = documento LIMIT 1)),idProducto);

 
        SELECT 'La factura con el ID proporcionado ya existe.' AS mensaje;
	UPDATE producto SET stock = stock - cantidad WHERE producto.idProducto = idProducto LIMIT 1;
    ELSE
      
        INSERT INTO Factura (fecha,Cliente_idCliente)
        VALUES (CURDATE(), (SELECT idCliente FROM Cliente WHERE
	cedula = documento LIMIT 1));
        SELECT 'Factura creada exitosamente.' AS mensaje;
	CALL comprarF(documento,idProducto,cantidad);
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE generarFactura(IN documento VARCHAR(15), fecha DATE)
BEGIN
	IF EXISTS (SELECT 1 FROM Factura WHERE Cliente_idCliente = (SELECT idCliente FROM Cliente WHERE
	cedula = documento LIMIT 1) AND Factura.fecha = fecha) THEN
	
	SELECT '<<Neutech>>' AS Nombre Empresa;
	SELECT CONCAT('Cliente: ', nombres, ' ', apellidos, '\nDocumento: ', cedula, '\nCorreo: ', correo, '\nTelefono: ', telefono) AS Datos del Cliente
	FROM Cliente WHERE cedula = documento;

	SELECT idFactura, fecha FROM Factura WHERE Cliente_idCliente = (SELECT idCliente FROM Cliente WHERE
	cedula = documento LIMIT 1) AND Factura.fecha = fecha;
	SELECT 
    	p.nombreProducto,
    	p.descripcion,
    	d.cantidad,
    	d.precio AS precio_unitario
	FROM 
    	Cliente c
	JOIN 
    	Factura f ON c.idCliente = f.Cliente_idCliente
	JOIN 
    	Detalle d ON f.idFactura = d.Factura_idFactura
	JOIN 
    	Producto p ON d.Producto_idProducto = p.idProducto
	WHERE 
    	c.cedula = documento
    	AND f.fecha = fecha;
	SELECT 
    	SUM(d.precio) AS total_factura
	FROM 
    	Cliente c
	JOIN 
    	Factura f ON c.idCliente = f.Cliente_idCliente
	JOIN 
    	Detalle d ON f.idFactura = d.Factura_idFactura
	WHERE 
    	c.cedula = documento
    	AND f.fecha = fecha;
	
	ELSE
	SELECT CONCAT('<<Neutech>> \n No existe una factura para el cliente con el Numero de documento: ', documento, ' fecha: ', fecha) AS mensaje;
	END IF;
END$$
DELIMITER ;


DELIMITER $$

CREATE PROCEDURE MejoresCompradores()
BEGIN

SELECT 
    c.idCliente,
    c.nombres,
    c.apellidos,
    COUNT(f.idFactura) AS numeroCompras,
    SUM(d.cantidad * p.precio) AS totalGastado
FROM 
    Cliente c
INNER JOIN 
    Factura f ON c.idCliente = f.Cliente_idCliente
INNER JOIN 
    Detalle d ON f.idFactura = d.Factura_idFactura
INNER JOIN 
    Producto p ON d.producto_idProducto = p.idProducto
GROUP BY 
    c.idCliente, c.nombres, c.apellidos
ORDER BY 
    totalGastado DESC;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE ProductosVendidosPorCategoria(IN categoria VARCHAR(15))
BEGIN
    SELECT 
        p.idProducto,
        p.nombreProducto, 
        p.precio AS precioUnitario,
        c.nombreCategoria,
        d.cantidad,
        f.fecha
    FROM 
        Producto p
    INNER JOIN 
        Categoria c ON p.categoria_idCategoria = c.idCategoria
    INNER JOIN 
        Detalle d ON p.idProducto = d.producto_idProducto
    INNER JOIN 
        Factura f ON d.Factura_idFactura = f.idFactura
    WHERE 
        c.nombreCategoria = categoria;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE ProductosVendidosPorFecha(IN fechaVenta DATE)
BEGIN
    DECLARE totalVentas INT;

    SELECT 
        COUNT(*) INTO totalVentas
    FROM 
        Factura f
    WHERE 
        f.fecha = fechaVenta;
    IF totalVentas = 0 THEN
        SELECT 'No hay productos vendidos en la fecha ingresada' AS mensaje;
    ELSE

        SELECT 
            p.idProducto,
            p.nombreProducto, 
            p.precio AS precioUnitario,
            c.nombreCategoria,
            d.cantidad,
            f.fecha,
            (p.precio * d.cantidad) AS ganancia
        FROM 
            Producto p
        INNER JOIN 
            Categoria c ON p.categoria_idCategoria = c.idCategoria
        INNER JOIN 
            Detalle d ON p.idProducto = d.producto_idProducto
        INNER JOIN 
            Factura f ON d.Factura_idFactura = f.idFactura
        WHERE 
            f.fecha = fechaVenta;
        SELECT 
            SUM(d.cantidad) AS totalProductosVendidos,
            SUM(p.precio * d.cantidad) AS gananciaTotal
        FROM 
            Producto p
        INNER JOIN 
            Detalle d ON p.idProducto = d.producto_idProducto
        INNER JOIN 
            Factura f ON d.Factura_idFactura = f.idFactura
        WHERE 
            f.fecha = fechaVenta;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE Top5ProductosMasVendidos()
BEGIN
    SELECT 
        p.idProducto,
        p.nombreProducto,
        SUM(d.cantidad) AS cantidadTotalVendida
    FROM 
        Producto p
    INNER JOIN 
        Detalle d ON p.idProducto = d.producto_idProducto
    GROUP BY 
        p.idProducto, p.nombreProducto
    ORDER BY 
        cantidadTotalVendida DESC
    LIMIT 5;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE verFacturas()
    
BEGIN
SELECT * FROM factura WHERE Cliente_idCliente = ( 
    SELECT idCliente FROM cliente WHERE cedula = tipoDoc);
END$$
DELIMITER ;