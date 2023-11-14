USE Northwind
GO

--1.-  En la tabla suppliers se agregó el campo TotalPiezas (es continuación del ejercicio de 1 de SP), realizar un trigger que actualice automáticamente dicho campo.
CREATE TRIGGER tr_EJERCICIO ON [Order Details]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Actualizar TotalPiezas para proveedores afectados por la operación
    UPDATE S
    SET TotalPiezas = (
        SELECT ISNULL(SUM(QUANTITY), 0)
        FROM [vw_orderdetails] OD
        WHERE OD.[ID Proveedor] = S.SupplierID)
    FROM Suppliers S
    WHERE S.SupplierID IN (
        SELECT DISTINCT SupplierID
        FROM INSERTED
        UNION
        SELECT DISTINCT SupplierID
        FROM DELETED)
END
GO

/*
	3.- Es necesario llevar el registro Historico de los precios de los 
	productos, es necesario conocer la fecha y hora cuando se realiza la 
	actualización, el nuevo valor del precio, el inicio de sesión que 
	está realizando el cambio.
*/

DROP TABLE [Historical Products]
GO

CREATE TABLE [Historical Products] (
	ProductID INT NOT NULL,
	OldPrice MONEY,
	NewPrice MONEY,
	NewDateTime DATE,
	ChangeUser NVARCHAR(50)
)
GO

ALTER TABLE [Historical Products] ADD CONSTRAINT FK_HProducts_ProductID
FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
GO

DROP TRIGGER TR_registroHistorico
GO

CREATE TRIGGER TR_registroHistorico ON Products
AFTER UPDATE
AS
BEGIN
	DECLARE @PRODUCTID INT
	DECLARE @OLDPRICE MONEY
	DECLARE @NEWPRICE MONEY
	DECLARE @SESION VARCHAR(50)

	SET @SESION = SUSER_SNAME()

	SELECT 
		@PRODUCTID = I.ProductID,
		@OLDPRICE = D.UnitPrice,
		@NEWPRICE = I.Unitprice
	FROM Inserted I
	INNER JOIN Deleted D ON I.ProductID = D.ProductID

	INSERT INTO [Historical Products] (ProductID, OldPrice, NewPrice, NewDateTime, ChangeUser)
	VALUES (@PRODUCTID, @OLDPRICE, @NEWPRICE, GETDATE(), @SESION)

	UPDATE Products
	SET UnitPrice = @NEWPRICE
	WHERE @PRODUCTID = ProductID
END
GO

-- ACTUALIZACION DEL PRECIO
UPDATE Products
SET UnitPrice = 35
WHERE ProductID = 1
GO

SELECT * FROM Products
WHERE ProductID = 1
GO

SELECT * FROM [Historical Products]
GO

DELETE FROM [Historical Products]


/*
	4.- Utilizando trigger, validar que solo se vendan ordenes de lunes a viernes.
*/
CREATE TRIGGER TR_ventaOrdenes ON Orders
FOR INSERT AS
DECLARE @Fecha INT

SELECT @Fecha = DATEPART(DW, OrderDate) FROM inserted

IF @Fecha = 1 OR @Fecha = 7 BEGIN
	ROLLBACK TRANSACTION
	RAISERROR('No se puede vender esos dias, solo entre semana', 16, 1)
END
GO

/*
	5.- Validar que no se vendan mas de 20 ordenes por empleado en una semana.
*/
CREATE TRIGGER TR_ventasPorEmpleado ON Orders
AFTER INSERT
AS
BEGIN
    DECLARE @EMPLEADOID INT
    DECLARE @TOTALORDENES INT
	DECLARE @INICIOSEMANA DATE
    DECLARE @FINSEMANA DATE

	SET @INICIOSEMANA = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0)
	SET @FINSEMANA = DATEADD(DAY, 6, @INICIOSEMANA)

    SELECT 
        @EMPLEADOID = EmployeeID,
        @TOTALORDENES = COUNT(OrderID)
    FROM INSERTED
	WHERE OrderDate BETWEEN @INICIOSEMANA AND @FINSEMANA
    GROUP BY EmployeeID

    IF @TOTALORDENES > 20
    BEGIN
        ROLLBACK TRAN
        RAISERROR('Se ha excedido el límite de 20 órdenes por empleado en una semana.', 16, 1)
    END
END
GO

/*
	6.- Validar que el campo firstname en la tabla employees solamente tenga nombres que inicien con vocal.
*/
CREATE TRIGGER tr_EJERCICIO6  ON Employees
FOR INSERT AS

DECLARE @NomEMpleado VARCHAR(25)
SELECT @NomEMpleado=FirstName FROM inserted 

    IF @NomEMpleado NOT LIKE '[aeiou]%'
        BEGIN
            ROLLBACK TRAN
            RAISERROR('SOLO SE ACEPTAN NOMBRES QUE EMPIECEN CON VOCAL',16,1) 
        END
GO
--validar
INSERT INTO Employees(LastName, FirstName)
VALUES ('Rosales','Pedro')
GO 


/*
	7.- validar que el importe de venta de cada orden no sea mayor a $10,000.
*/
CREATE TRIGGER TR_importeVenta ON [Order Details]
FOR INSERT
AS
BEGIN
	DECLARE @IDVENTA INT
	DECLARE @IMPORTE MONEY

	SELECT 
		@IDVENTA = OrderID,
		@IMPORTE = SUM(UnitPrice * Quantity)
	FROM [Order Details]
	WHERE OrderID = @IDVENTA
	GROUP BY OrderID

	IF @IMPORTE > 10000
	BEGIN
		ROLLBACK TRAN
		RAISERROR('El importe de Venta no puede ser mayor a $10,000', 16, 1)
	END
END
GO

--8.- Validar que solo se pueda actualizar una sola vez el nombre del cliente.

ALTER TABLE Customers ADD CONTADOR INT
UPDATE Customers SET CONTADOR = 0
ALTER TABLE Customers ADD CONSTRAINT DF_CUST_CONTADOR DEFAULT(0) FOR CONTADOR
GO

CREATE TRIGGER tr_EJERCICIO8
ON Customers
FOR UPDATE
AS
DECLARE @ClientesID nchar(5), @Contador INT

SELECT  @ClientesID = CustomerID, @Contador = ISNULL(@Contador,0) FROM inserted

IF UPDATE (CompanyName)
BEGIN
    IF @Contador>0
    BEGIN 
        ROLLBACK TRAN
        RAISERROR('NO SE PUEDE ACTUALIZAR MAS DE UNA VEZ EL NOMBRE',16,1)
    END
    ELSE
        UPDATE Customers SET CONTADOR = @CONTADOR + 1 WHERE CustomerID= @ClientesID
END
GO

/*
	9.- Validar que no se puedan eliminar categorías que tengan una clave impar.
*/
CREATE TRIGGER TR_eliminarCategorias ON Categories
FOR DELETE
AS
BEGIN
	DECLARE @IDCATEGORIA INT

	SELECT @IDCATEGORIA = CategoryID
	FROM Categories
	WHERE CategoryID = @IDCATEGORIA

	IF @IDCATEGORIA % 2 = 1
	ROLLBACK TRAN
	RAISERROR('No se Pueden Eliminar Categorias con Clave Impar', 16, 1)
END
GO

/*
	10.- Validar que no se puedan insertar ordenes que se realicen en domingo.
*/
CREATE TRIGGER TR_ordenesDomigno ON Orders
FOR INSERT
AS
BEGIN
	DECLARE @IDORDEN INT
	DECLARE @DIA DATE

	SELECT 
		@IDORDEN = OrderID, 
		@DIA = DATEPART(DAY, OrderDate)
	FROM Orders
	WHERE OrderID = @IDORDEN
	
	IF @DIA = 1
	BEGIN
		ROLLBACK TRAN
		RAISERROR('No se Puede Insertar Ordenes el Domingo', 16, 1)
	END
END
GO

EXEC sp_help Customers