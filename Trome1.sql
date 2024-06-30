iF DB_ID('BDTrome') IS NOT NULL
BEGIN
    DROP DATABASE BDTrome;
END
GO

-- Creamos la base de datos BDTrome
CREATE DATABASE BDTrome;
GO

-- Usamos la base de datos BDTrome
USE BDTrome;
GO

-- Creación de la tabla TUsuario (Usuario y Contraseña encriptada)
IF OBJECT_ID('dbo.TUsuario', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TUsuario (
        CodUsuario VARCHAR(50) PRIMARY KEY,
        Contrasena VARBINARY(8000) NOT NULL
    );
END
GO

-- Creación de la tabla TCliente
IF OBJECT_ID('dbo.TCliente', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TCliente (
        IdCliente INT PRIMARY KEY IDENTITY(1,1),
        Nombre VARCHAR(100) NOT NULL,
        Direccion VARCHAR(200) NOT NULL,
        Telefono VARCHAR(20) NOT NULL,
        CodUsuario VARCHAR(50) NOT NULL,
        Contrasena VARCHAR(50) NOT NULL,
        FOREIGN KEY (CodUsuario) REFERENCES dbo.TUsuario(CodUsuario)
    );
END
GO

-- Creación de la tabla TServicio
IF OBJECT_ID('dbo.TServicio', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TServicio (
        IdServicio INT PRIMARY KEY IDENTITY(1,1),
        Descripcion VARCHAR(200) NOT NULL,
        TarifaBase DECIMAL(10, 2) NOT NULL
    );
END
GO

-- Creación de la tabla TVehiculo
IF OBJECT_ID('dbo.TVehiculo', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TVehiculo (
        IdVehiculo INT PRIMARY KEY IDENTITY(1,1),
        Marca VARCHAR(100) NOT NULL,
        Modelo VARCHAR(100) NOT NULL,
        Placa VARCHAR(20) NOT NULL,
        CapacidadCarga DECIMAL(10, 2) NOT NULL
    );
END
GO

-- Creación de la tabla TEnvio
IF OBJECT_ID('dbo.TEnvio', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TEnvio (
        IdEnvio INT PRIMARY KEY IDENTITY(1,1),
        IdCliente INT NOT NULL,
        IdServicio INT NOT NULL,
        FechaEnvio DATE NOT NULL,
        FechaRecojo DATE NOT NULL,
        Peso DECIMAL(10, 2) NOT NULL,
        Volumen DECIMAL(10, 2) NOT NULL,
        TipoDocumento CHAR(1) CHECK (TipoDocumento IN ('B', 'F')) NOT NULL,
        TarifaBase DECIMAL(10, 2) NOT NULL,
        MontoPago AS (TarifaBase + (Peso * 0.5) + (Volumen * 0.3)) PERSISTED,
        EstadoEnvio VARCHAR(50) NOT NULL CHECK (EstadoEnvio IN ('Pendiente', 'Llegado', 'Cancelado')),
        FOREIGN KEY (IdCliente) REFERENCES dbo.TCliente(IdCliente),
        FOREIGN KEY (IdServicio) REFERENCES dbo.TServicio(IdServicio)
    );
END
GO

-- Creación de la tabla TColaborador
IF OBJECT_ID('dbo.TColaborador', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TColaborador (
        IdColaborador INT PRIMARY KEY IDENTITY(1,1),
        Nombre VARCHAR(100) NOT NULL,
        Cargo VARCHAR(100) NOT NULL,
        Telefono VARCHAR(20) NOT NULL,
        CodUsuario VARCHAR(50) NOT NULL,
        Contrasena VARCHAR(50) NOT NULL,
        IdVehiculo INT,
        FOREIGN KEY (IdVehiculo) REFERENCES dbo.TVehiculo(IdVehiculo),
        FOREIGN KEY (CodUsuario) REFERENCES dbo.TUsuario(CodUsuario)
    );
END
GO

-- Creación de la tabla ColaboradorEnvio (relación muchos a muchos)
IF OBJECT_ID('dbo.ColaboradorEnvio', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ColaboradorEnvio (
        IdColaborador INT,
        IdEnvio INT,
        PRIMARY KEY (IdColaborador, IdEnvio),
        FOREIGN KEY (IdColaborador) REFERENCES dbo.TColaborador(IdColaborador),
        FOREIGN KEY (IdEnvio) REFERENCES dbo.TEnvio(IdEnvio)
    );
END
GO

IF OBJECT_ID('dbo.CarritoCompras', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.CarritoCompras (
        IdCarrito INT PRIMARY KEY IDENTITY(1,1),
        IdCliente INT NOT NULL,
        IdServicio INT NOT NULL,
        Cantidad INT NOT NULL,
        Subtotal DECIMAL(10, 2) NULL,
        IGV AS (Subtotal * 0.18) PERSISTED,
        Total AS (Subtotal * 1.18) PERSISTED,
        FOREIGN KEY (IdCliente) REFERENCES dbo.TCliente(IdCliente),
        FOREIGN KEY (IdServicio) REFERENCES dbo.TServicio(IdServicio)
    );
END
GO

-- Trigger para calcular Subtotal en CarritoCompras
IF OBJECT_ID('tr_CarritoCompras_Insert', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER tr_CarritoCompras_Insert;
END
GO

CREATE TRIGGER tr_CarritoCompras_Insert
ON dbo.CarritoCompras
AFTER INSERT
AS
BEGIN
    UPDATE C
    SET C.Subtotal = I.Cantidad * S.TarifaBase
    FROM dbo.CarritoCompras AS C
    INNER JOIN inserted AS I ON C.IdCarrito = I.IdCarrito
    INNER JOIN dbo.TServicio AS S ON I.IdServicio = S.IdServicio;
END
GO

--- Inserción de datos de prueba

-- Inserción de usuarios TColaborador
INSERT INTO dbo.TUsuario VALUES 
('admin', ENCRYPTBYPASSPHRASE('miFraseDeContraseña', '1234')),
('juan.perez@example.com', ENCRYPTBYPASSPHRASE('miFraseDeContraseña', '1234')),
('maria.lopez@example.com', ENCRYPTBYPASSPHRASE('miFraseDeContraseña', '1234')),
('pedro.ramirez@example.com', ENCRYPTBYPASSPHRASE('miFraseDeContraseña', '1234'));

-- Inserción de usuarios TCliente 
INSERT INTO dbo.TUsuario VALUES 
('cliente1@example.com', ENCRYPTBYPASSPHRASE('miFraseDeContraseña', '1234')),
('cliente2@example.com', ENCRYPTBYPASSPHRASE('miFraseDeContraseña', '1234')),
('cliente3@example.com', ENCRYPTBYPASSPHRASE('miFraseDeContraseña', '1234'));

-- Inserción de datos de clientes
INSERT INTO dbo.TCliente (Nombre, Direccion, Telefono, CodUsuario, Contrasena) VALUES 
('Cliente 1', 'Direccion Cliente 1', '123456789', 'cliente1@example.com', '123'),
('Cliente 2', 'Direccion Cliente 2', '987654321', 'cliente2@example.com', '123'),
('Cliente 3', 'Direccion Cliente 3', '555444333', 'cliente3@example.com', '123');
GO

-- Inserción de datos de servicios
INSERT INTO dbo.TServicio (Descripcion, TarifaBase) VALUES 
('Mudanza', 500.00),
('Paquetes', 100.00),
('Sobres', 50.00),
('Encomiendas', 200.00),
('Carga pesada', 1000.00);
GO

-- Inserción de datos de vehículos
INSERT INTO dbo.TVehiculo (Marca, Modelo, Placa, CapacidadCarga) VALUES 
('Toyota', 'Hilux', 'ABC123', 1500.00),
('Ford', 'Transit', 'XYZ789', 2000.00),
('Chevrolet', 'N300', 'DEF456', 1000.00);
GO

-- Inserción de datos de envíos
INSERT INTO dbo.TEnvio (IdCliente, IdServicio, FechaEnvio, FechaRecojo, Peso, Volumen, TipoDocumento, TarifaBase, EstadoEnvio) VALUES 
(1, 1, '2024-06-17', '2024-06-18', 12.3, 18.5, 'B', 500.00, 'Pendiente'),
(2, 3, '2024-06-16', '2024-06-17', 7.8, 10.2, 'F', 50.00, 'Pendiente'),
(3, 2, '2024-06-15', '2024-06-16', 6.5, 9.8, 'B', 100.00, 'Pendiente');
GO

-- Inserción de datos en la tabla TColaborador
INSERT INTO dbo.TColaborador (Nombre, Cargo, Telefono, CodUsuario, Contrasena, IdVehiculo) VALUES 
('Juan Perez', 'Gerente de Logistica', '123456789', 'juan.perez@example.com', '123', 1),
('Maria Lopez', 'Coordinadora de Transporte', '987654321', 'maria.lopez@example.com', '123', 2),
('Pedro Ramirez', 'Conductor', '555444333', 'pedro.ramirez@example.com', '123', 3);
GO

-- Inserción de datos en la tabla ColaboradorEnvio
INSERT INTO dbo.ColaboradorEnvio (IdColaborador, IdEnvio) VALUES 
(1, 1),
(2, 2),
(3, 3);
GO

-- Inserción de datos en la tabla CarritoCompras
INSERT INTO dbo.CarritoCompras (IdCliente, IdServicio, Cantidad) VALUES 
(1, 1, 2), 
(2, 2, 3), 
(3, 3, 1);
GO

-- Verificar las tablas
SELECT * FROM dbo.TEnvio;
SELECT * FROM dbo.TVehiculo;
SELECT * FROM dbo.TServicio;
SELECT * FROM dbo.TCliente;
SELECT * FROM dbo.TColaborador;
SELECT * FROM dbo.ColaboradorEnvio;
SELECT * FROM dbo.TUsuario;
SELECT * FROM dbo.CarritoCompras;
GO

IF OBJECT_ID('spLogin') IS NOT NULL
BEGIN
    DROP PROCEDURE spLogin;
END
GO

CREATE PROCEDURE spLogin
    @CodUsuario VARCHAR(50),
    @Contrasena VARCHAR(50)
AS
BEGIN
    DECLARE @ContrasenaEncriptada VARBINARY(8000);
    DECLARE @ContrasenaDesencriptada VARCHAR(50);

    -- Obtener la contraseña encriptada de la base de datos
    SELECT @ContrasenaEncriptada = Contrasena
    FROM dbo.TUsuario
    WHERE CodUsuario = @CodUsuario;

    -- Desencriptar la contraseña almacenada
    SET @ContrasenaDesencriptada = CONVERT(VARCHAR(50), DECRYPTBYPASSPHRASE('miFraseDeContraseña', @ContrasenaEncriptada));

    -- Comparar la contraseña desencriptada con la contraseña proporcionada
    IF @ContrasenaDesencriptada = @Contrasena
    BEGIN
        -- Determinar el tipo de usuario
        IF @CodUsuario = 'admin'
        BEGIN
            SELECT CodError = 0, Mensaje = 'Administrador';
        END
        ELSE IF EXISTS (SELECT CodUsuario FROM dbo.TColaborador WHERE CodUsuario = @CodUsuario)
        BEGIN
            SELECT CodError = 0, Mensaje = 'Colaborador';
        END
        ELSE IF EXISTS (SELECT CodUsuario FROM dbo.TCliente WHERE CodUsuario = @CodUsuario)
        BEGIN
            SELECT CodError = 0, Mensaje = 'Cliente';
        END
        ELSE
        BEGIN
            SELECT CodError = 1, Mensaje = 'Error: Usuario no tiene privilegio de cliente ni colaborador, consulte al administrador';
        END
    END
    ELSE
    BEGIN
        SELECT CodError = 1, Mensaje = 'Error: Usuario y/o contraseña incorrectos';
    END
END
GO


if OBJECT_ID('spCambiarContrasenaColaborador') is not null
    drop proc spCambiarContrasenaColaborador
go
create proc spCambiarContrasenaColaborador
@CodUsuario varchar(50),
@ContrasenaActual varchar(50),
@NuevaContrasena varchar(50)
as
begin
    if exists (select CodUsuario from TUsuario where CodUsuario = @CodUsuario and CONVERT(varchar(50), DECRYPTBYPASSPHRASE('miFraseDeContraseña', Contrasena)) = @ContrasenaActual)
    begin
        update TUsuario
        set Contrasena = ENCRYPTBYPASSPHRASE('miFraseDeContraseña', @NuevaContrasena)
        where CodUsuario = @CodUsuario
        select 'Contraseña actualizada exitosamente' as Mensaje
    end
    else
    begin
        select 'Error: Contraseña actual incorrecta' as Mensaje
    end
end
