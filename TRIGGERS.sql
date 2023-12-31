--TRIGGER, DISPARADORES, GATILLOS
/*SON PROCEDIMIENTOS ALMACENADOS ESPECIALES QUE SE EJECUTAN SOLAMENTE CUANDO SE INSERTAN, ACTUALIZAN O ELIMINAN
REGISTROS EN UNA TABLA.
DENTRO DE UN TRIGGER SE PUEDE REALIZAR:
1.-DECLARAR VARIABLES 
2.-USAR CURSORES
3.-MODIFICAR DATOS DE OTRAS TABLAS
4.-DESHACER LA TRANSACCION EXPLICITA CON ROLLBACK TRAN.*/

--CREACION 
CREATE TRIGGER NOMBRE_TRIGGER
ON NOMBRE_TABLA
[WITH ENCRYPTION]
FOR{[DELETE][,][INSERT][,][UPDATE]}
AS
SENTENCIA_SQL
GO

--MODIFICACION 
ALTER TRIGGER NOMBRE_TRIGGER
ON NOMBRE_TABLA
FOR{[DELETE][,][INSERT][,][UPDATE]}
AS
SENTENCIA_SQL
GO

--ELIMINACION 
DROP TRIGGER NOMBRE_TRIGGER
GO
--TABLAS VIRTUALES QUE SE GENERAN 
/*INSTRUCCION INSERT:
Se genera la tabla INSERTED y contiene el nuevo registro que se esta insertando.

INSTRUCCION DELETE:
se genera la tabla DELETED y contiene el registro que se esta eliminando.

INSTRUCCION UPDATE:
Se genera la tabla DELETED con los nuevos datos actualizados 
tambien se genera la tabla DELETED con los viejors datos que se sobreescribieron.*/

--ejemplo: crear un trigger de insercion en la tabla materiales 
CREATE TABLE Materiales(Clave int primary key, nombre char(50),precio numeric(12,2))
go
create trigger TR_Materiales_Ins
on Materiales for insert as
	select 'se ejecuto el trigger al insertar'
	select* from inserted
go
--EJECUCION 
DELETE Materiales WHERE Clave=55
DELETE Materiales WHERE Clave=68
DELETE Materiales WHERE Clave BETWEEN 70 AND 75
GO
--EJEMPLO_ CREAR UN TROGGER DE ACTUALIZACION EN LA TABLA MATERIALES 
CREATE TRIGGER TR_MATERIALES_UPD
ON MATERIALES FOR UPDATE AS
	SELECT 'SE EJECUTO EL TRIGGER AL ACTUALIZAR'
	SELECT *FROM inserted --CONTIENE EL NUEVO VALOR
	SELECT *FROM deleted --CONTIENE EL VIEJO VALOR
GO
--EJECUCION
UPDATE Materiales SET NOMBRE='CEPILLO', PRECIO=12 WHERE Clave=28
GO

--ELIMINACION
DROP TRIGGER TR_MATERIALES_UPD
GO

--VALIDAR QUE REALMENTE SE EJECUTA UN ROLLBACK TRAN (DESHACER UNA TRANSACCION)

--VALIDAR QUE AL ACTUALIZAR EL PRECIO UN MATERIAL NO SEA COJ UN PRECIO MENOR
CREATE TRIGGER TR_MATERIALES_UP
ON MATERIALES FOR UPDATE AS
DECLARE @PRECIOVIEJO NUMERIC(12,2), @PRECIONUEVO NUMERIC(12,2)

SELECT @PRECIONUEVO = PRECIO FROM inserted
SELECT @PRECIONUEVO = PRECIO FROM deleted

IF @PRECIONUEVO < @PRECIOVIEJO
BEGIN
	ROLLBACK TRAN
	RAISERROR('ERROR AL ACTUALIZAR EL PRECIO, PRECIO NUEVO ES MENOR', 16,1)
END
GO
SELECT*FROM Materiales WHERE Clave =40
--NO DEJA 
UPDATE MATERIALES SET PRECIO = 20 WHERE CLAVE=40
GO
--SI DEJA 
UPDATE MATERIALES SET precio = 28 WHERE CLAVE = 40
GO

--No permitir que se eliminen registros en la tabla materiales 
CREATE TRIGGER TR_MATERIALES_DELETE
ON MATERIALES FOR DELETED AS

	ROLLBACK TRAN
	RAISERROR('POR EL MOMENTO NO SE PUEDE ELIMINAR REGISTROS', 16, 1)
GO

--VALIDA QUE NO SE MODIFIQUE UN CAMPO DENTRO DE UN TRIGGER
IF UPDATE(NOMBRE_COLUMNA) AND | OR UPDATE(NOMBRE_COLUMNA)
BEGIN
	SENTENCIAS_SELECT
END
ELSE
BEGIN 
	SENTENCIAS_SELECT
END
GO

--VALIDAR QUE EL NOMBRE DE LOS MATERIALES NO SE ACTUALICE 
CREATE TRIGGER(TR_MATERIALES_INS3)
ON MATERIALES FOR UPDATE AS

IF UPDATE(NOMBRE)
BEGIN
	ROLLBACK TRAN
	RAISERROR('NO SE PUEDE ACTUALIZAR EL NOMBRE DEL MATERIAL',16,1)
END

--NO SE PUEDE ACTUALIZAR EL NOMBRE 
UPDATE Materiales SET nombre='QUESO CAB' WHERE Clave=46
UPDATE Materiales SET nombre='QUESO CAP', PRECIO=200 WHERE CLAVE = 46
GO

--SI SE ACTUALIZA EL PRECIO 
UPDATE Materiales SET precio=6 WHERE CLAVE =46
GO
SELECT*FROM Materiales WHERE CLAVE= 46
GO

--ELIMINAMOS PRIMERO EL TRIGGER ANTERIOR 
DROP TRIGGER TR_MATERIALES_INS3
DROP TRIGGER TR_MATERIALES_UPD --NO PERMITE ACTUALIZACIONES MASIVAS
GO
--AGREGAMOS EL CAMPO CONTADOR PARA LLEVAR EL NUMERO DE ACTULIZACIONES 
ALTER TABLE MATERIALES ADD CONTADOR INT
UPDATE Materiales SET CONTADOR = 0
ALTER TABLE MATERIALES ADD CONSTRAINT DF_MAT_CONTADOR DEFAULT(0) FOR CONTADOR
GO

CREATE TRIGGER TR_MATERIALES_CONTA
ON MATERIALES FOR UPDATE AS 
DECLARE @CLAVE INT, @CONTA INT

SELECT @CLAVE = CLAVE, @CONTA = ISNULL(CONTADOR,0) FROM inserted

IF UPDATE (NOMBRE)
BEGIN
	IF @CONTA>0
	BEGIN 
		ROLLBACK TRAN
		RAISERROR('NO SE PUEDE ACTUALIZAR MAS DE UNA VEZ EL NOMBRE',16,1)
	END
	ELSE
	UPDATE Materiales SET CONTADOR=@CONTADOR + 1 WHERE CLAVE=@CLAVE
END
GO

INSERT Materiales(Clave, nombre, precio) VALUES(100,'BOLSA',181)
SELECT *FROM Materiales WHERE CLAVE=100

--ACTUALIZAMOS EL PRECIO Y VERIFICAMOS QUE EL CAMPO CONTA NO AUMENTA 
UPDATE Materiales SET precio=PRECIO+2 WHERE CLAVE =100
--SI SE PUEDE 
--UPDATE Materiales SET nombre = 'BOLSA NEGRA' WHERE

/*TAREA HACER EL EJERCICIO 1 DE LA TAREA DE PROCEDIMIETOS PERO CON TRIGGERS*/





