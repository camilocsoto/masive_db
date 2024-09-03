-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost:3308
-- Tiempo de generación: 03-09-2024 a las 06:58:21
-- Versión del servidor: 10.4.28-MariaDB
-- Versión de PHP: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `formato_hoja_vida`
--
CREATE DATABASE IF NOT EXISTS `formato_hoja_vida` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `formato_hoja_vida`;

DELIMITER $$
--
-- Procedimientos
--
DROP PROCEDURE IF EXISTS `buscarES`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `buscarES` (IN `modalidad` VARCHAR(15))   BEGIN
    DECLARE total_registros INT;

    
    SELECT COUNT(*)
    INTO total_registros
    FROM educacionsuperior es
    JOIN personanatural p ON p.idpersonanatural = es.PersonaNatural_idPersonaNatural
    JOIN modalidadacademica m ON m.idmodalidadacademica = es.ModalidadAcademica_idModalidadAcademica
    WHERE m.nombremodalidad = modalidad;

    
    IF total_registros > 0 THEN
        
        SELECT 
            p.nombres, p.primerapellido, p.segundoapellido, 
es.nTarjeta, 
            p.email, p.telefono, 
            CASE
WHEN m.nombremodalidad = 'TC' THEN 'T�cnica'
WHEN m.nombremodalidad = 'TL' THEN 'Tecnol�gica'
WHEN m.nombremodalidad = 'TE' THEN 'Tecnol�gica Especializada'
WHEN m.nombremodalidad = 'UN' THEN 'Universitaria'
WHEN m.nombremodalidad = 'ES' THEN 'Especializaci�n'
WHEN m.nombremodalidad = 'MG' THEN 'Maestr�a o Mag�ster'
WHEN m.nombremodalidad = 'DOC' THEN 'Doctorado o PhD'
ELSE 'Desconocido'
END AS ModalidadAcademica,
            es.tituloProfesional AS TituloProfesional 
FROM educacionsuperior es
        JOIN personanatural p ON p.idpersonanatural = es.PersonaNatural_idPersonaNatural
        JOIN modalidadacademica m ON m.idmodalidadacademica = es.ModalidadAcademica_idModalidadAcademica
        WHERE m.nombremodalidad = modalidad;
    ELSE
        
        SELECT 'No existen registros en la base de datos para la modalidad proporcionada' AS mensaje;
    END IF;
END$$

DROP PROCEDURE IF EXISTS `buscarPCE`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `buscarPCE` (IN `cargo` VARCHAR(50))   BEGIN
    DECLARE total_registros INT;
    
    SELECT COUNT(*)
    INTO total_registros
    FROM experiencialaboral e
    JOIN personanatural p ON p.idpersonanatural = e.PersonaNatural_idPersonaNatural
    JOIN cargo c ON c.idcargo = e.Cargo_idCargo
    WHERE c.tipocargo = cargo;
    
    IF total_registros > 0 THEN
        
        SELECT
            p.nombres, p.primerapellido, p.segundoapellido,
            e.Cargo_idCargo,
            c.tipocargo,
            CASE WHEN e.esvigente = 0 THEN 'Desempleado' ELSE 'Empleado' END AS Disponibilidad
        FROM experiencialaboral e
        JOIN personanatural p ON p.idpersonanatural = e.PersonaNatural_idPersonaNatural
        JOIN cargo c ON c.idcargo = e.Cargo_idCargo
        WHERE c.tipocargo = cargo;
    ELSE
        
        SELECT 'No existen registros en la base de datos para dicho cargo' AS mensaje;
    END IF;
END$$

DROP PROCEDURE IF EXISTS `buscarPorIdioma`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `buscarPorIdioma` (IN `idioma` VARCHAR(45))   BEGIN

SELECT pn.idPersonaNatural, pn.primerApellido, pn.nombres, pn.nacionalidad, i.nombreIdioma, nh.nivel AS nivelHabla, ne.nivel AS nivelEscribe, nl.nivel AS nivelLee
FROM  idiomapersona ip INNER JOIN personanatural pn ON ip.PersonaNatural_idPersonaNatural = pn.idPersonaNatural
INNER JOIN idioma i ON ip.Idioma_idIdioma = i.idIdioma
INNER JOIN nivel nh ON ip.Nivel_idHabla = nh.idNivel
INNER JOIN nivel ne ON ip.Nivel_idEscribe = ne.idNivel
INNER JOIN nivel nl ON ip.Nivel_idLee = nl.idNivel
WHERE i.nombreIdioma = idioma;
END$$

DROP PROCEDURE IF EXISTS `InsertarExperienciaLaboral`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertarExperienciaLaboral` (IN `id_persona` INT)   BEGIN
    -- Declarar variables
    DECLARE puntador CHAR(2);
    DECLARE ID INT;
    DECLARE CARGO VARCHAR(30);
    DECLARE meses INT;
    DECLARE años INT;
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_fechaIngreso DATE;
    DECLARE v_fechaRetiro DATE;
    DECLARE v_sector CHAR(2);

    -- Declarar el cursor para recorrer los registros
    DECLARE cur CURSOR FOR
        SELECT sector, fechaIngreso, fechaRetiro
        FROM experiencialaboral 
        WHERE PersonaNatural_idPersonaNatural = id_persona;
        
    -- Declarar el manejador para la condición de fin del cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Abrir el cursor
    OPEN cur;

    -- Bucle para recorrer los registros
    read_loop: LOOP
        FETCH cur INTO v_sector, v_fechaIngreso, v_fechaRetiro;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Asignar el cargo según el sector
        IF v_sector = 'PU' THEN 
            SET CARGO = 'SERVIDOR PÚBLICO';
        ELSEIF v_sector = 'PR' THEN
            SET CARGO = 'EMPLEADO DEL SECTOR PRIVADO';
        ELSE
            SET CARGO = 'TRABAJADOR INDEPENDIENTE';
        END IF;

        -- Verificar si el cargo existe en la tabla tiposector y obtener el ID
        SET ID = (SELECT idtipoSector 
                  FROM tiposector 
                  WHERE nombreTipoSector = CARGO LIMIT 1);
                  
        -- Calcular los años y meses de experiencia
        SET años = TIMESTAMPDIFF(YEAR, v_fechaIngreso, v_fechaRetiro);
        SET meses = TIMESTAMPDIFF(MONTH, v_fechaIngreso, v_fechaRetiro) % 12;

        -- Verificar si ya existe un registro en tiempoexperiencia con los mismos datos
        IF NOT EXISTS (
            SELECT 1 
            FROM tiempoexperiencia 
            WHERE años = años
              AND meses = meses
              AND tipoServidor_idtipoServidor = ID
              AND PersonaNatural_idPersonaNatural = id_persona
        ) THEN
            -- Insertar el registro si no existe
            INSERT INTO tiempoexperiencia (años, meses, tipoServidor_idtipoServidor, PersonaNatural_idPersonaNatural)
            VALUES (años, meses, ID, id_persona);
        END IF;

    END LOOP;

    -- Cerrar el cursor
    CLOSE cur;

END$$

DROP PROCEDURE IF EXISTS `spAnioMesesExperiencia`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `spAnioMesesExperiencia` (IN `anios_solicitados` INT, IN `meses_solicitados` INT)   BEGIN
    SELECT p.nombres, p.primerApellido, p.segundoApellido, p.telefono, p.email,
           t.años, t.meses, (t.años * 12 + t.meses) AS TotalMesesExperiencia
    FROM personanatural p
    INNER JOIN tiempoexperiencia t ON p.idPersonaNatural = t.PersonaNatural_idPersonaNatural
    WHERE t.años >= anios_solicitados 
      AND t.meses >= meses_solicitados;
END$$

DROP PROCEDURE IF EXISTS `spMunicipio`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `spMunicipio` (IN `municipio_solicitado` VARCHAR(11))   BEGIN
select p.nombres, p.primerApellido, p.segundoApellido, p.telefono, email
from personanatural p inner join municipio m where m.nombreMunicipio = municipio_solicitado 
and m.idMunicipio = p.Municipio_idMunicipio;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `acuerdo`
--

DROP TABLE IF EXISTS `acuerdo`;
CREATE TABLE IF NOT EXISTS `acuerdo` (
  `idAcuerdo` int(11) NOT NULL,
  `acepto` tinyint(4) NOT NULL,
  `firma` varchar(45) NOT NULL,
  `fecha` date NOT NULL,
  `ciudad` varchar(45) NOT NULL,
  `HojaDeVida_idHojaDeVida` int(11) NOT NULL,
  PRIMARY KEY (`idAcuerdo`),
  KEY `fk_Acuerdo_HojaDeVida1_idx` (`HojaDeVida_idHojaDeVida`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `acuerdo`
--

INSERT INTO `acuerdo` (`idAcuerdo`, `acepto`, `firma`, `fecha`, `ciudad`, `HojaDeVida_idHojaDeVida`) VALUES
(1, 1, 'FirmaEjemplo1', '2024-08-29', 'Bogotá', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cargo`
--

DROP TABLE IF EXISTS `cargo`;
CREATE TABLE IF NOT EXISTS `cargo` (
  `idCargo` int(11) NOT NULL AUTO_INCREMENT,
  `tipoCargo` varchar(45) NOT NULL,
  PRIMARY KEY (`idCargo`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `cargo`
--

INSERT INTO `cargo` (`idCargo`, `tipoCargo`) VALUES
(1, 'Administrador de Sistemas'),
(2, 'Analista Financiero'),
(3, 'Especialista en Reclutamiento'),
(4, 'Coordinador de Marketing Digital'),
(5, 'Ejecutivo de Ventas'),
(6, 'Gerente de Operaciones'),
(7, 'Asistente Administrativo'),
(8, 'Técnico de Soporte'),
(9, 'Ingeniero de Producto'),
(10, 'Contador General');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `correspondencia`
--

DROP TABLE IF EXISTS `correspondencia`;
CREATE TABLE IF NOT EXISTS `correspondencia` (
  `idCorrrespondencia` int(11) NOT NULL AUTO_INCREMENT,
  `direccion` varchar(45) NOT NULL,
  `PersonaNatural_idPersonaNatural` int(11) NOT NULL,
  `Pais_idPais` int(11) NOT NULL,
  `Departamento_idDepartamento` int(11) NOT NULL,
  `Municipio_idMunicipio` int(11) NOT NULL,
  PRIMARY KEY (`idCorrrespondencia`),
  KEY `fk_Corrrespondencia_PersonaNatural1_idx` (`PersonaNatural_idPersonaNatural`),
  KEY `fk_Corrrespondencia_Pais1_idx` (`Pais_idPais`),
  KEY `fk_Corrrespondencia_Departamento1_idx` (`Departamento_idDepartamento`),
  KEY `fk_Corrrespondencia_Municipio1_idx` (`Municipio_idMunicipio`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `correspondencia`
--

INSERT INTO `correspondencia` (`idCorrrespondencia`, `direccion`, `PersonaNatural_idPersonaNatural`, `Pais_idPais`, `Departamento_idDepartamento`, `Municipio_idMunicipio`) VALUES
(1, 'Calle 123 #45-67', 1, 1, 1, 1),
(2, 'Carrera 12B #13B-44', 2, 1, 1, 1),
(3, 'Calle 130 # 4', 3, 1, 5, 5),
(4, 'Carrera 7 # 32-45', 4, 1, 2, 2),
(5, 'Avenida Ciudad de Cali # 54-23', 5, 1, 1, 1),
(6, 'Calle 11 # 8-90', 6, 1, 4, 4);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `departamento`
--

DROP TABLE IF EXISTS `departamento`;
CREATE TABLE IF NOT EXISTS `departamento` (
  `idDepartamento` int(11) NOT NULL AUTO_INCREMENT,
  `nombreDepartamento` varchar(45) NOT NULL,
  `Pais_idPais` int(11) NOT NULL,
  PRIMARY KEY (`idDepartamento`),
  KEY `fk_Departamento_Pais1_idx` (`Pais_idPais`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `departamento`
--

INSERT INTO `departamento` (`idDepartamento`, `nombreDepartamento`, `Pais_idPais`) VALUES
(1, 'Antioquia', 1),
(2, 'Cundinamarca', 1),
(3, 'Valle del Cauca', 1),
(4, 'Santander', 1),
(5, 'Atlántico', 1),
(6, 'Jalisco', 3),
(7, 'Nuevo León', 3),
(8, 'Ciudad de México', 3),
(9, 'Puebla', 3),
(10, 'Yucatán', 3),
(11, 'Buenos Aires', 5),
(12, 'Córdoba', 5),
(13, 'Santa Fe', 5),
(14, 'Mendoza', 5),
(15, 'Tucumán', 5),
(16, 'São Paulo', 4),
(17, 'Río de Janeiro', 4),
(18, 'Minas Gerais', 4),
(19, 'Bahia', 4),
(20, 'Paraná', 4),
(21, 'Lima', 2),
(22, 'Cusco', 2),
(23, 'Arequipa', 2),
(24, 'Piura', 2),
(25, 'La Libertad', 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `dependencia`
--

DROP TABLE IF EXISTS `dependencia`;
CREATE TABLE IF NOT EXISTS `dependencia` (
  `iddependencias` int(11) NOT NULL,
  `nombreDependencia` varchar(45) NOT NULL,
  PRIMARY KEY (`iddependencias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `dependencia`
--

INSERT INTO `dependencia` (`iddependencias`, `nombreDependencia`) VALUES
(1, 'IT'),
(2, 'Contabilidad'),
(3, 'Recursos Humanos'),
(4, 'Marketing'),
(5, 'Ventas'),
(6, 'Operaciones'),
(7, 'Administración'),
(8, 'Soporte Técnico'),
(9, 'Desarrollo de Producto'),
(10, 'Finanzas');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `distrito`
--

DROP TABLE IF EXISTS `distrito`;
CREATE TABLE IF NOT EXISTS `distrito` (
  `idDistrito` int(11) NOT NULL AUTO_INCREMENT,
  `nombreDistrito` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`idDistrito`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `distrito`
--

INSERT INTO `distrito` (`idDistrito`, `nombreDistrito`) VALUES
(1, 'Distrito 1'),
(2, 'Distrito 2'),
(3, 'Distrito 3');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `educacionbasica`
--

DROP TABLE IF EXISTS `educacionbasica`;
CREATE TABLE IF NOT EXISTS `educacionbasica` (
  `idEducacionBasica` int(11) NOT NULL AUTO_INCREMENT,
  `tituloObtenido` varchar(45) NOT NULL,
  `fecha` date NOT NULL,
  `Grado_idGrado` int(11) NOT NULL,
  `PersonaNatural_idPersonaNatural` int(11) NOT NULL,
  PRIMARY KEY (`idEducacionBasica`),
  KEY `fk_EducacionBasica_Grado1_idx` (`Grado_idGrado`),
  KEY `fk_EducacionBasica_PersonaNatural1_idx` (`PersonaNatural_idPersonaNatural`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `educacionbasica`
--

INSERT INTO `educacionbasica` (`idEducacionBasica`, `tituloObtenido`, `fecha`, `Grado_idGrado`, `PersonaNatural_idPersonaNatural`) VALUES
(1, 'Bachillerato', '2008-06-15', 11, 1),
(2, 'Bachillerato', '2009-11-30', 11, 2),
(3, 'Preparatoria', '2020-12-04', 11, 3),
(4, 'Bachiller', '2018-12-10', 11, 4),
(5, 'Bachiller', '2017-12-07', 11, 5),
(6, 'Bachiller', '2015-11-27', 11, 6);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `educacionsuperior`
--

DROP TABLE IF EXISTS `educacionsuperior`;
CREATE TABLE IF NOT EXISTS `educacionsuperior` (
  `idEducacionSuperior` int(11) NOT NULL AUTO_INCREMENT,
  `tituloProfesional` varchar(45) NOT NULL,
  `esGraduado` tinyint(4) NOT NULL,
  `fechaTerminacion` date DEFAULT NULL,
  `nTarjeta` varchar(45) DEFAULT NULL,
  `NumeroSemestre_idNumeroSemestre` int(11) NOT NULL,
  `ModalidadAcademica_idModalidadAcademica` int(11) NOT NULL,
  `PersonaNatural_idPersonaNatural` int(11) NOT NULL,
  PRIMARY KEY (`idEducacionSuperior`),
  KEY `fk_EducacionSuperior_NumeroSemestre1_idx` (`NumeroSemestre_idNumeroSemestre`),
  KEY `fk_EducacionSuperior_ModalidadAcademica2_idx` (`ModalidadAcademica_idModalidadAcademica`),
  KEY `fk_EducacionSuperior_PersonaNatural1_idx` (`PersonaNatural_idPersonaNatural`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `educacionsuperior`
--

INSERT INTO `educacionsuperior` (`idEducacionSuperior`, `tituloProfesional`, `esGraduado`, `fechaTerminacion`, `nTarjeta`, `NumeroSemestre_idNumeroSemestre`, `ModalidadAcademica_idModalidadAcademica`, `PersonaNatural_idPersonaNatural`) VALUES
(1, 'Ingeniero sistemas', 1, '2020-06-30', 'TP001', 10, 4, 1),
(2, 'Redes y servidores', 1, '2022-03-10', 'CP002', 4, 2, 1),
(3, 'Ingeniería de Sistemas', 1, '2016-01-13', 'IS003', 10, 4, 3),
(4, 'Licenciatura en Física', 1, '2013-06-27', 'LF001', 10, 4, 4),
(5, 'Ciencias Ambientales', 1, '2014-03-20', 'CA001', 10, 4, 5),
(6, 'Contaduría Pública', 1, '2015-12-30', 'CP001', 10, 4, 6),
(7, 'Especialización en Ingeniería de Sistemas', 1, '2018-05-15', 'ESIS001', 4, 2, 3),
(8, 'Especialización en Física Aplicada', 1, '2017-11-23', 'ESFA001', 4, 2, 4),
(9, 'Especialización en Gestión Ambiental', 1, '2018-09-05', 'ESGA001', 4, 2, 5),
(10, 'Especialización en Auditoría Financiera', 1, '2019-03-12', 'ESAF001', 4, 2, 6),
(11, 'Maestría en Ingeniería de Sistemas', 1, '2021-07-22', 'MIS001', 4, 5, 3),
(12, 'Maestría en Ciencias Ambientales', 1, '2022-11-18', 'MCA001', 4, 5, 5),
(13, 'Maestría en Contabilidad y Finanzas', 1, '2021-09-30', 'MCF001', 4, 5, 6),
(14, 'Doctorado en Ciencias Ambientales', 1, '2024-01-15', 'DCA001', 4, 6, 5),
(15, 'Doctorado en Contabilidad', 1, '2023-12-20', 'DC002', 4, 6, 6);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `experiencialaboral`
--

DROP TABLE IF EXISTS `experiencialaboral`;
CREATE TABLE IF NOT EXISTS `experiencialaboral` (
  `idExperienciaLaboral` int(11) NOT NULL AUTO_INCREMENT,
  `nombreEmpresa` varchar(45) DEFAULT NULL,
  `sector` char(2) DEFAULT NULL,
  `email` varchar(45) DEFAULT NULL,
  `direccionEmpresa` varchar(45) DEFAULT NULL,
  `fechaIngreso` date NOT NULL,
  `fechaRetiro` date DEFAULT NULL,
  `esVigente` tinyint(4) NOT NULL,
  `PersonaNatural_idPersonaNatural` int(11) NOT NULL,
  `Pais_idPais` int(11) NOT NULL,
  `Departamento_idDepartamento` int(11) NOT NULL,
  `Municipio_idMunicipio` int(11) NOT NULL,
  `Cargo_idCargo` int(11) NOT NULL,
  `dependencia_iddependencias` int(11) NOT NULL,
  PRIMARY KEY (`idExperienciaLaboral`),
  KEY `fk_ExperienciaLaboral_PersonaNatural1_idx` (`PersonaNatural_idPersonaNatural`),
  KEY `fk_ExperienciaLaboral_Pais1_idx` (`Pais_idPais`),
  KEY `fk_ExperienciaLaboral_Departamento1_idx` (`Departamento_idDepartamento`),
  KEY `fk_ExperienciaLaboral_Municipio1_idx` (`Municipio_idMunicipio`),
  KEY `fk_ExperienciaLaboral_Cargo1_idx` (`Cargo_idCargo`),
  KEY `fk_ExperienciaLaboral_dependencia1_idx` (`dependencia_iddependencias`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `experiencialaboral`
--

INSERT INTO `experiencialaboral` (`idExperienciaLaboral`, `nombreEmpresa`, `sector`, `email`, `direccionEmpresa`, `fechaIngreso`, `fechaRetiro`, `esVigente`, `PersonaNatural_idPersonaNatural`, `Pais_idPais`, `Departamento_idDepartamento`, `Municipio_idMunicipio`, `Cargo_idCargo`, `dependencia_iddependencias`) VALUES
(1, 'Innovate Solutions', 'PU', 'contacto@innovate.com', 'Calle 101 #30-45', '2020-02-10', '2023-08-15', 0, 1, 1, 1, 1, 1, 8),
(2, 'Global Marketing', 'PR', 'info@globalmk.com', 'Avenida 56 #20-30', '2018-05-01', '2021-12-31', 0, 1, 1, 1, 1, 8, 8),
(11, 'TechNova Solutions', 'PU', 'technova@gmail.com', 'Avenida 123', '2020-01-15', '2021-02-10', 0, 2, 1, 2, 2, 4, 4),
(12, 'FinanceHub Inc.', 'PR', 'financehub@gmail.com', 'Calle 456', '2019-05-10', '2022-01-20', 0, 2, 1, 1, 1, 2, 2),
(13, 'GreenEarth Corp.', 'PR', 'greenearth@gmail.com', 'Avenida 789', '2021-03-22', '2024-12-31', 1, 3, 3, 7, 7, 2, 2),
(14, 'EduPlus Academy', 'PR', 'eduplus@gmail.com', 'Carrera 11', '2018-07-05', '2020-08-30', 0, 3, 3, 8, 8, 10, 10),
(15, 'HealthCare Co.', 'PU', 'healthcare@gmail.com', 'Calle 321', '2020-02-15', '2024-12-31', 1, 4, 4, 21, 21, 1, 1),
(16, 'Makers Inc.', 'PU', 'makers@gmail.com', 'Avenida 654', '2017-10-01', '2019-09-15', 0, 4, 3, 3, 3, 9, 9),
(17, 'ConnectNow Ltd.', 'PR', 'connectnow@gmail.com', 'Carrera 21', '2022-06-01', '2024-12-31', 1, 5, 1, 2, 2, 8, 8),
(18, 'TechVentures', 'PU', 'techventures@gmail.com', 'Avenida 987', '2016-04-12', '2018-11-18', 0, 5, 1, 2, 2, 3, 3);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `grado`
--

DROP TABLE IF EXISTS `grado`;
CREATE TABLE IF NOT EXISTS `grado` (
  `idGrado` int(11) NOT NULL AUTO_INCREMENT,
  `nivelGrado` varchar(45) NOT NULL,
  PRIMARY KEY (`idGrado`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `grado`
--

INSERT INTO `grado` (`idGrado`, `nivelGrado`) VALUES
(1, 'Primaro'),
(2, 'Segundo'),
(3, 'Tercero'),
(4, 'Cuarto'),
(5, 'Quinto'),
(6, 'Sexto'),
(7, 'Septimo'),
(8, 'Octavo'),
(9, 'Noveno'),
(10, 'Decimo'),
(11, 'Decimo primero');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `hojadevida`
--

DROP TABLE IF EXISTS `hojadevida`;
CREATE TABLE IF NOT EXISTS `hojadevida` (
  `idHojaDeVida` int(11) NOT NULL AUTO_INCREMENT,
  `PersonaNatural_idPersonaNatural` int(11) NOT NULL,
  PRIMARY KEY (`idHojaDeVida`),
  KEY `fk_Comprobante_PersonaNatural1_idx` (`PersonaNatural_idPersonaNatural`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `hojadevida`
--

INSERT INTO `hojadevida` (`idHojaDeVida`, `PersonaNatural_idPersonaNatural`) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `idioma`
--

DROP TABLE IF EXISTS `idioma`;
CREATE TABLE IF NOT EXISTS `idioma` (
  `idIdioma` int(11) NOT NULL AUTO_INCREMENT,
  `nombreIdioma` varchar(45) NOT NULL,
  PRIMARY KEY (`idIdioma`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `idioma`
--

INSERT INTO `idioma` (`idIdioma`, `nombreIdioma`) VALUES
(1, 'Inglés'),
(2, 'Aleman'),
(3, 'Francés');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `idiomapersona`
--

DROP TABLE IF EXISTS `idiomapersona`;
CREATE TABLE IF NOT EXISTS `idiomapersona` (
  `idIdiomaPersona` int(11) NOT NULL AUTO_INCREMENT,
  `Idioma_idIdioma` int(11) NOT NULL,
  `Nivel_idHabla` int(11) NOT NULL,
  `Nivel_idEscribe` int(11) NOT NULL,
  `Nivel_idLee` int(11) NOT NULL,
  `PersonaNatural_idPersonaNatural` int(11) NOT NULL,
  PRIMARY KEY (`idIdiomaPersona`),
  KEY `fk_IdiomaPersona_Idioma1_idx` (`Idioma_idIdioma`),
  KEY `fk_IdiomaPersona_Nivel1_idx` (`Nivel_idHabla`),
  KEY `fk_IdiomaPersona_Nivel2_idx` (`Nivel_idEscribe`),
  KEY `fk_IdiomaPersona_Nivel3_idx` (`Nivel_idLee`),
  KEY `fk_IdiomaPersona_PersonaNatural1_idx` (`PersonaNatural_idPersonaNatural`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `idiomapersona`
--

INSERT INTO `idiomapersona` (`idIdiomaPersona`, `Idioma_idIdioma`, `Nivel_idHabla`, `Nivel_idEscribe`, `Nivel_idLee`, `PersonaNatural_idPersonaNatural`) VALUES
(1, 1, 2, 2, 2, 1),
(2, 1, 2, 2, 2, 2),
(3, 1, 2, 2, 3, 1),
(4, 2, 2, 2, 2, 1),
(5, 1, 3, 3, 3, 2),
(6, 3, 2, 2, 3, 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `libretamilitar`
--

DROP TABLE IF EXISTS `libretamilitar`;
CREATE TABLE IF NOT EXISTS `libretamilitar` (
  `idLibretaMilitar` int(11) NOT NULL AUTO_INCREMENT,
  `clase` varchar(45) NOT NULL,
  `numeroLibreta` varchar(45) NOT NULL,
  `Distrito_idDistrito` int(11) NOT NULL,
  PRIMARY KEY (`idLibretaMilitar`),
  KEY `fk_LibretaMilitar_Distrito1_idx` (`Distrito_idDistrito`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `libretamilitar`
--

INSERT INTO `libretamilitar` (`idLibretaMilitar`, `clase`, `numeroLibreta`, `Distrito_idDistrito`) VALUES
(1, 'Primera', 'LM001', 1),
(2, 'Segunda', 'LM002', 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `modalidadacademica`
--

DROP TABLE IF EXISTS `modalidadacademica`;
CREATE TABLE IF NOT EXISTS `modalidadacademica` (
  `idModalidadAcademica` int(11) NOT NULL AUTO_INCREMENT,
  `nombreModalidad` varchar(45) NOT NULL,
  PRIMARY KEY (`idModalidadAcademica`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `modalidadacademica`
--

INSERT INTO `modalidadacademica` (`idModalidadAcademica`, `nombreModalidad`) VALUES
(1, 'TC'),
(2, 'ES'),
(3, 'TE'),
(4, 'UN'),
(5, 'MG'),
(6, 'DOC'),
(7, 'TL');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `municipio`
--

DROP TABLE IF EXISTS `municipio`;
CREATE TABLE IF NOT EXISTS `municipio` (
  `idMunicipio` int(11) NOT NULL AUTO_INCREMENT,
  `nombreMunicipio` varchar(45) NOT NULL,
  `Departamento_idDepartamento` int(11) NOT NULL,
  PRIMARY KEY (`idMunicipio`),
  KEY `fk_Municipio_Departamento1_idx` (`Departamento_idDepartamento`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `municipio`
--

INSERT INTO `municipio` (`idMunicipio`, `nombreMunicipio`, `Departamento_idDepartamento`) VALUES
(1, 'Medellín', 1),
(2, 'Bogotá ', 2),
(3, 'Cali', 3),
(4, 'Bucaramanga ', 4),
(5, 'Barranquilla ', 5),
(6, 'Guadalajara ', 6),
(7, 'Monterrey ', 7),
(8, 'Coyoacán ', 8),
(9, 'Puebla ', 9),
(10, 'Mérida ', 10),
(11, 'La Plata', 11),
(12, 'Córdoba ', 12),
(13, 'Rosario ', 13),
(14, 'Mendoza ', 14),
(15, 'San Miguel de Tucumán', 15),
(16, 'São Paulo', 16),
(17, 'Río de Janeiro', 17),
(18, 'Belo Horizonte', 18),
(19, 'Salvador ', 19),
(20, 'Curitiba ', 20),
(21, 'Lima ', 21),
(22, 'Cusco ', 22),
(23, 'Arequipa ', 23),
(24, 'Piura ', 24),
(25, 'Trujillo ', 25);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `nivel`
--

DROP TABLE IF EXISTS `nivel`;
CREATE TABLE IF NOT EXISTS `nivel` (
  `idNivel` int(11) NOT NULL AUTO_INCREMENT,
  `nivel` varchar(3) NOT NULL,
  PRIMARY KEY (`idNivel`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `nivel`
--

INSERT INTO `nivel` (`idNivel`, `nivel`) VALUES
(1, 'R'),
(2, 'B'),
(3, 'MB');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `numerosemestre`
--

DROP TABLE IF EXISTS `numerosemestre`;
CREATE TABLE IF NOT EXISTS `numerosemestre` (
  `idNumeroSemestre` int(11) NOT NULL AUTO_INCREMENT,
  `numeroSemestre` varchar(2) NOT NULL,
  PRIMARY KEY (`idNumeroSemestre`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `numerosemestre`
--

INSERT INTO `numerosemestre` (`idNumeroSemestre`, `numeroSemestre`) VALUES
(1, '1'),
(2, '2'),
(3, '3'),
(4, '4'),
(5, '5'),
(6, '6'),
(7, '7'),
(8, '8'),
(9, '9'),
(10, '10');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `observaciones`
--

DROP TABLE IF EXISTS `observaciones`;
CREATE TABLE IF NOT EXISTS `observaciones` (
  `idObservaciones` int(11) NOT NULL AUTO_INCREMENT,
  `observacion` mediumblob NOT NULL,
  `ciudad` varchar(45) NOT NULL,
  `fecha` date NOT NULL,
  `firma` varchar(34) NOT NULL,
  `HojaDeVida_idHojaDeVida` int(11) NOT NULL,
  PRIMARY KEY (`idObservaciones`),
  KEY `fk_Observaciones_HojaDeVida1_idx` (`HojaDeVida_idHojaDeVida`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `observaciones`
--

INSERT INTO `observaciones` (`idObservaciones`, `observacion`, `ciudad`, `fecha`, `firma`, `HojaDeVida_idHojaDeVida`) VALUES
(1, 0x4f6273657276616369c3b36e20736f627265206c6120657870657269656e636961206c61626f72616c20656e20496e6e6f7661746520536f6c7574696f6e732e, 'Bogotá D.C.', '2024-08-29', 'FirmaEjemplo1', 1),
(2, '', 'Bogotá D.C.', '2024-07-02', 'FirmaEjemplo2', 2),
(3, '', 'Bogotá D.C.', '2024-06-12', 'FirmaEjemplo3', 3),
(4, '', 'Bogotá D.C.', '2024-03-21', 'FirmaEjemplo4', 4),
(5, '', 'Bogotá D.C.', '2024-07-23', 'FirmaEjemplo5', 5),
(6, '', 'Bogotá D.C.', '2024-04-08', 'FirmaEjemplo6', 6);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pais`
--

DROP TABLE IF EXISTS `pais`;
CREATE TABLE IF NOT EXISTS `pais` (
  `idPais` int(11) NOT NULL AUTO_INCREMENT,
  `nombrePais` varchar(45) NOT NULL,
  PRIMARY KEY (`idPais`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `pais`
--

INSERT INTO `pais` (`idPais`, `nombrePais`) VALUES
(1, 'Colombia'),
(2, 'Perú'),
(3, 'México'),
(4, 'Brasil'),
(5, 'Argentina');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `personanatural`
--

DROP TABLE IF EXISTS `personanatural`;
CREATE TABLE IF NOT EXISTS `personanatural` (
  `idPersonaNatural` int(11) NOT NULL AUTO_INCREMENT,
  `primerApellido` varchar(45) NOT NULL,
  `segundoApellido` varchar(45) NOT NULL,
  `nombres` varchar(45) NOT NULL,
  `numeroIdentificacion` varchar(45) NOT NULL,
  `sexo` tinyint(4) NOT NULL,
  `nacionalidad` varchar(45) NOT NULL,
  `fechaNacimiento` date NOT NULL,
  `email` varchar(45) NOT NULL,
  `telefono` varchar(45) NOT NULL,
  `Pais_idPais` int(11) NOT NULL,
  `Departamento_idDepartamento` int(11) NOT NULL,
  `Municipio_idMunicipio` int(11) NOT NULL,
  `TipoDocumento_idTipoDocumento` int(11) NOT NULL,
  `LibretaMilitar_idLibretaMilitar` int(11) DEFAULT NULL,
  PRIMARY KEY (`idPersonaNatural`),
  KEY `fk_PersonaNatural_Pais1_idx` (`Pais_idPais`),
  KEY `fk_PersonaNatural_Departamento1_idx` (`Departamento_idDepartamento`),
  KEY `fk_PersonaNatural_Municipio1_idx` (`Municipio_idMunicipio`),
  KEY `fk_PersonaNatural_TipoDocumento1_idx` (`TipoDocumento_idTipoDocumento`),
  KEY `fk_PersonaNatural_LibretaMilitar1_idx` (`LibretaMilitar_idLibretaMilitar`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `personanatural`
--

INSERT INTO `personanatural` (`idPersonaNatural`, `primerApellido`, `segundoApellido`, `nombres`, `numeroIdentificacion`, `sexo`, `nacionalidad`, `fechaNacimiento`, `email`, `telefono`, `Pais_idPais`, `Departamento_idDepartamento`, `Municipio_idMunicipio`, `TipoDocumento_idTipoDocumento`, `LibretaMilitar_idLibretaMilitar`) VALUES
(1, 'Pérez', 'González', 'Juan', '123456789', 1, 'Colombiano', '1990-01-01', 'juanpg@correo.com', '3001234567', 1, 2, 2, 1, 1),
(2, 'Rodríguez', 'Martínez', 'María', '987654321', 2, 'Colombiana', '1992-02-02', 'mariarm@correo.com', '3001234567', 1, 1, 1, 1, NULL),
(3, 'García', 'Martínez', 'Juan Carlos', '1234567890', 1, 'Mexicano', '1985-03-15', 'juan.garcia@email.com', '3001234567', 3, 8, 8, 3, NULL),
(4, 'Pérez', 'Lopez', 'Ana María', '0987654321', 2, 'Peruana', '1990-07-22', 'ana.perez@email.com', '3009876543', 2, 21, 21, 3, NULL),
(5, 'Rodríguez', 'Fernández', 'Luis Alberto', '1122334455', 1, 'Colombiano', '1988-11-09', 'luis.rodriguez@email.com', '3001122334', 1, 5, 5, 1, 2),
(6, 'Ramírez', 'Córdoba', 'María Fernanda', '2233445566', 2, 'Colombiana', '1992-02-18', 'maria.ramirez@email.com', '3005566778', 1, 4, 4, 1, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tiempoexperiencia`
--

DROP TABLE IF EXISTS `tiempoexperiencia`;
CREATE TABLE IF NOT EXISTS `tiempoexperiencia` (
  `idTiempoExperiencia` int(11) NOT NULL AUTO_INCREMENT,
  `años` int(11) NOT NULL,
  `meses` int(11) NOT NULL,
  `tipoServidor_idtipoServidor` int(11) NOT NULL,
  `PersonaNatural_idPersonaNatural` int(11) NOT NULL,
  PRIMARY KEY (`idTiempoExperiencia`),
  KEY `fk_TiempoExperiencia_tipoServidor1_idx` (`tipoServidor_idtipoServidor`),
  KEY `fk_TiempoExperiencia_PersonaNatural1_idx` (`PersonaNatural_idPersonaNatural`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `tiempoexperiencia`
--

INSERT INTO `tiempoexperiencia` (`idTiempoExperiencia`, `años`, `meses`, `tipoServidor_idtipoServidor`, `PersonaNatural_idPersonaNatural`) VALUES
(1, 3, 6, 1, 1),
(2, 3, 7, 2, 1),
(3, 4, 10, 1, 4),
(6, 1, 0, 1, 2),
(7, 2, 8, 2, 2),
(8, 3, 9, 2, 3),
(9, 2, 6, 2, 5),
(10, 2, 7, 1, 5);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipodocumento`
--

DROP TABLE IF EXISTS `tipodocumento`;
CREATE TABLE IF NOT EXISTS `tipodocumento` (
  `idTipoDocumento` int(11) NOT NULL AUTO_INCREMENT,
  `tipoDocumento` varchar(5) NOT NULL,
  PRIMARY KEY (`idTipoDocumento`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `tipodocumento`
--

INSERT INTO `tipodocumento` (`idTipoDocumento`, `tipoDocumento`) VALUES
(1, 'CC'),
(2, 'TI'),
(3, 'CE'),
(4, 'PAS');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tiposector`
--

DROP TABLE IF EXISTS `tiposector`;
CREATE TABLE IF NOT EXISTS `tiposector` (
  `idtipoSector` int(11) NOT NULL AUTO_INCREMENT,
  `nombreTipoSector` varchar(45) NOT NULL,
  PRIMARY KEY (`idtipoSector`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Volcado de datos para la tabla `tiposector`
--

INSERT INTO `tiposector` (`idtipoSector`, `nombreTipoSector`) VALUES
(1, 'SERVIDOR PÚBLICO'),
(2, 'EMPLEADO DEL SECTOR PRIVADO'),
(3, 'TRABAJADOR INDEPENDIENTE');

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `acuerdo`
--
ALTER TABLE `acuerdo`
  ADD CONSTRAINT `fk_Acuerdo_HojaDeVida1` FOREIGN KEY (`HojaDeVida_idHojaDeVida`) REFERENCES `hojadevida` (`idHojaDeVida`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `correspondencia`
--
ALTER TABLE `correspondencia`
  ADD CONSTRAINT `fk_Corrrespondencia_Departamento1` FOREIGN KEY (`Departamento_idDepartamento`) REFERENCES `departamento` (`idDepartamento`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_Corrrespondencia_Municipio1` FOREIGN KEY (`Municipio_idMunicipio`) REFERENCES `municipio` (`idMunicipio`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_Corrrespondencia_Pais1` FOREIGN KEY (`Pais_idPais`) REFERENCES `pais` (`idPais`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_Corrrespondencia_PersonaNatural1` FOREIGN KEY (`PersonaNatural_idPersonaNatural`) REFERENCES `personanatural` (`idPersonaNatural`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `departamento`
--
ALTER TABLE `departamento`
  ADD CONSTRAINT `fk_Departamento_Pais1` FOREIGN KEY (`Pais_idPais`) REFERENCES `pais` (`idPais`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `educacionbasica`
--
ALTER TABLE `educacionbasica`
  ADD CONSTRAINT `fk_EducacionBasica_Grado1` FOREIGN KEY (`Grado_idGrado`) REFERENCES `grado` (`idGrado`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_EducacionBasica_PersonaNatural1` FOREIGN KEY (`PersonaNatural_idPersonaNatural`) REFERENCES `personanatural` (`idPersonaNatural`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `educacionsuperior`
--
ALTER TABLE `educacionsuperior`
  ADD CONSTRAINT `fk_EducacionSuperior_ModalidadAcademica2` FOREIGN KEY (`ModalidadAcademica_idModalidadAcademica`) REFERENCES `modalidadacademica` (`idModalidadAcademica`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_EducacionSuperior_NumeroSemestre1` FOREIGN KEY (`NumeroSemestre_idNumeroSemestre`) REFERENCES `numerosemestre` (`idNumeroSemestre`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_EducacionSuperior_PersonaNatural1` FOREIGN KEY (`PersonaNatural_idPersonaNatural`) REFERENCES `personanatural` (`idPersonaNatural`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `experiencialaboral`
--
ALTER TABLE `experiencialaboral`
  ADD CONSTRAINT `fk_ExperienciaLaboral_Cargo1` FOREIGN KEY (`Cargo_idCargo`) REFERENCES `cargo` (`idCargo`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_ExperienciaLaboral_Departamento1` FOREIGN KEY (`Departamento_idDepartamento`) REFERENCES `departamento` (`idDepartamento`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_ExperienciaLaboral_Municipio1` FOREIGN KEY (`Municipio_idMunicipio`) REFERENCES `municipio` (`idMunicipio`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_ExperienciaLaboral_Pais1` FOREIGN KEY (`Pais_idPais`) REFERENCES `pais` (`idPais`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_ExperienciaLaboral_PersonaNatural1` FOREIGN KEY (`PersonaNatural_idPersonaNatural`) REFERENCES `personanatural` (`idPersonaNatural`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_ExperienciaLaboral_dependencia1` FOREIGN KEY (`dependencia_iddependencias`) REFERENCES `dependencia` (`iddependencias`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `hojadevida`
--
ALTER TABLE `hojadevida`
  ADD CONSTRAINT `fk_Comprobante_PersonaNatural1` FOREIGN KEY (`PersonaNatural_idPersonaNatural`) REFERENCES `personanatural` (`idPersonaNatural`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `idiomapersona`
--
ALTER TABLE `idiomapersona`
  ADD CONSTRAINT `fk_IdiomaPersona_Idioma1` FOREIGN KEY (`Idioma_idIdioma`) REFERENCES `idioma` (`idIdioma`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_IdiomaPersona_Nivel1` FOREIGN KEY (`Nivel_idHabla`) REFERENCES `nivel` (`idNivel`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_IdiomaPersona_Nivel2` FOREIGN KEY (`Nivel_idEscribe`) REFERENCES `nivel` (`idNivel`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_IdiomaPersona_Nivel3` FOREIGN KEY (`Nivel_idLee`) REFERENCES `nivel` (`idNivel`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_IdiomaPersona_PersonaNatural1` FOREIGN KEY (`PersonaNatural_idPersonaNatural`) REFERENCES `personanatural` (`idPersonaNatural`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `libretamilitar`
--
ALTER TABLE `libretamilitar`
  ADD CONSTRAINT `fk_LibretaMilitar_Distrito1` FOREIGN KEY (`Distrito_idDistrito`) REFERENCES `distrito` (`idDistrito`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `municipio`
--
ALTER TABLE `municipio`
  ADD CONSTRAINT `fk_Municipio_Departamento1` FOREIGN KEY (`Departamento_idDepartamento`) REFERENCES `departamento` (`idDepartamento`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `observaciones`
--
ALTER TABLE `observaciones`
  ADD CONSTRAINT `fk_Observaciones_HojaDeVida1` FOREIGN KEY (`HojaDeVida_idHojaDeVida`) REFERENCES `hojadevida` (`idHojaDeVida`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `personanatural`
--
ALTER TABLE `personanatural`
  ADD CONSTRAINT `fk_PersonaNatural_Departamento1` FOREIGN KEY (`Departamento_idDepartamento`) REFERENCES `departamento` (`idDepartamento`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_PersonaNatural_LibretaMilitar1` FOREIGN KEY (`LibretaMilitar_idLibretaMilitar`) REFERENCES `libretamilitar` (`idLibretaMilitar`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_PersonaNatural_Municipio1` FOREIGN KEY (`Municipio_idMunicipio`) REFERENCES `municipio` (`idMunicipio`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_PersonaNatural_Pais1` FOREIGN KEY (`Pais_idPais`) REFERENCES `pais` (`idPais`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_PersonaNatural_TipoDocumento1` FOREIGN KEY (`TipoDocumento_idTipoDocumento`) REFERENCES `tipodocumento` (`idTipoDocumento`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla `tiempoexperiencia`
--
ALTER TABLE `tiempoexperiencia`
  ADD CONSTRAINT `fk_TiempoExperiencia_PersonaNatural1` FOREIGN KEY (`PersonaNatural_idPersonaNatural`) REFERENCES `personanatural` (`idPersonaNatural`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `fk_TiempoExperiencia_tipoServidor1` FOREIGN KEY (`tipoServidor_idtipoServidor`) REFERENCES `tiposector` (`idtipoSector`) ON DELETE NO ACTION ON UPDATE NO ACTION;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
