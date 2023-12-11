--Validar que no se pueda actualizar e insertar employees y customers los domingos
USE Northwind2
GO
CREATE TRIGGER TR_EX1
ON EMPLOYEES FOR UPDATE,INSERT AS
	IF DATEPART(DW, GETDATE())= 1
		BEGIN 
			ROLLBACK TRAN
			RAISERROR('NO SE PUEDEN HACER INSERCIONES O ACTUALIZACIONES LOS DOMINGOS',16,1)
		END
GO

--validar que en una ciudad no vivan mas de 5 clientes
CREATE TRIGGER TR_EX2
ON Customers
FOR INSERT, UPDATE AS
BEGIN
    DECLARE @MaxClientes INT = 5;

    IF (SELECT COUNT(CustomerID)
        FROM Customers
        WHERE City IN (SELECT City FROM Inserted)) > @MaxClientes

    BEGIN
        ROLLBACK TRAN
        RAISERROR ('No se permite tener más de 5 clientes en una ciudad.', 16, 1)
    END
END
go

--validar que un proveedor no tenga mas de 20 productos asignados
CREATE TRIGGER TR_EX3
ON Products for insert, update AS
BEGIN
    DECLARE @MaxProductos INT = 20;

    IF (SELECT COUNT(ProductID)
        FROM Products
        WHERE SupplierID IN (SELECT SupplierID FROM Inserted)) > @MaxProductos
    BEGIN
        ROLLBACK TRAN
        RAISERROR ('No se permite asignar más de 20 productos a un proveedor.', 16, 1)
    END
END
GO

--validar que solo se pueda actualizar un solo campo a la vez en la tabla siguiente 
CREATE DATABASE EX
GO
USE EX
GO
CREATE TABLE CLIENTES(
	CLAVE INT NOT NULL,
	NOMBRE VARCHAR(25),
	DOMICILIO VARCHAR (50),
	TELEFONO VARCHAR (10),
	CORREO VARCHAR(253))
	GO

CREATE TRIGGER TR_EXAMEN3
ON CLIENTES FOR UPDATE AS
BEGIN
	DECLARE @CONTADOR INT = 0
	IF UPDATE(CLAVE)
	SELECT @CONTADOR = @CONTADOR+1
	IF UPDATE(DOMICILIO)
	SELECT @CONTADOR = @CONTADOR+1
	IF UPDATE(TELEFONO)
	SELECT @CONTADOR = @CONTADOR+1
	IF UPDATE(CORREO)
	SELECT @CONTADOR = @CONTADOR+1

	IF @CONTADOR>1
	BEGIN
		ROLLBACK TRAN
		RAISERROR('SOLAMENTE SE PUEDE ACTUALIZAR UN CAMPO A LA VEZ',16,1)
	END
END
GO
