---------------------------------------------------------------------
-- Microsoft SQL Server 2012: Основы T-SQL
-- Глава 09 - Транзакции и параллелизм
-- © Ицик Бен-Ган
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Транзакции
---------------------------------------------------------------------

-- Пример транзакции
USE TSQL2012;

-- Начните новую транзакцию
BEGIN TRAN;

  -- Объявите переменную
  DECLARE @neworderid AS INT;

  -- Добавьте новый заказ в таблицу Sales.Orders
  INSERT INTO Sales.Orders
      (custid, empid, orderdate, requireddate, shippeddate, 
       shipperid, freight, shipname, shipaddress, shipcity,
       shippostalcode, shipcountry)
    VALUES
      (85, 5, '20090212', '20090301', '20090216',
       3, 32.38, N'Ship to 85-B', N'6789 rue de l''Abbaye', N'Reims',
       N'10345', N'France');

  -- Сохраните идентификатор нового заказа в переменной
  SET @neworderid = SCOPE_IDENTITY();

  -- Верните идентификатор нового заказа
  SELECT @neworderid AS neworderid;

  -- Добавьте составляющие нового заказа в таблицу Sales.OrderDetails
  INSERT INTO Sales.OrderDetails(orderid, productid, unitprice, qty, discount)
    VALUES(@neworderid, 11, 14.00, 12, 0.000),
          (@neworderid, 42, 9.80, 10, 0.000),
          (@neworderid, 72, 34.80, 5, 0.000);

-- Подтвердите транзакцию
COMMIT TRAN;

-- Очистите БД
DELETE FROM Sales.OrderDetails
WHERE orderid > 11077;

DELETE FROM Sales.Orders
WHERE orderid > 11077;

---------------------------------------------------------------------
-- Блокировки и блокирование
---------------------------------------------------------------------

-- Убедитесь в том, что все новые соединения
-- направлены к базе данных TSQL2012
USE TSQL2012;

-- Соединение 1
BEGIN TRAN;

  UPDATE Production.Products
    SET unitprice += 1.00
  WHERE productid = 2;

-- Соединение 2
SELECT productid, unitprice
FROM Production.Products -- WITH (READCOMMITTEDLOCK)
WHERE productid = 2;

-- Заметьте: в SQL Azure параметр базы данных READ_COMMITTED_SNAPSHOT
-- включен по умолчанию; его нельзя выключить. Для использования уровня
-- изоляции READ_COMMITTED используйте табличное указание READCOMMITTEDLOCK

-- Соединение 3

-- Информация о блокировке

SELECT -- используйте *, чтобы вывести все доступные атрибуты
  request_session_id            AS spid,
  resource_type                 AS restype,
  resource_database_id          AS dbid,
  DB_NAME(resource_database_id) AS dbname,
  resource_description          AS res,
  resource_associated_entity_id AS resid,
  request_mode                  AS mode,
  request_status                AS status
FROM sys.dm_tran_locks;

-- Информация о соединении
SELECT -- используйте *, чтобы вывести все доступные атрибуты
  session_id AS spid,
  connect_time,
  last_read,
  last_write,
  most_recent_sql_handle
FROM sys.dm_exec_connections
WHERE session_id IN(52, 53);

-- Код на языке SQL
SELECT session_id, text 
FROM sys.dm_exec_connections
  CROSS APPLY sys.dm_exec_sql_text(most_recent_sql_handle) AS ST 
WHERE session_id IN(52, 53);

-- Информация о сессии
SELECT -- используйте *, чтобы вывести все доступные атрибуты
  session_id AS spid,
  login_time,
  host_name,
  program_name,
  login_name,
  nt_user_name,
  last_request_start_time,
  last_request_end_time
FROM sys.dm_exec_sessions
WHERE session_id IN(52, 53);

-- Блокирование
SELECT -- используйте *, чтобы вывести все доступные атрибуты
  session_id AS spid,
  blocking_session_id,
  command,
  sql_handle,
  database_id,
  wait_type,
  wait_time,
  wait_resource
FROM sys.dm_exec_requests
WHERE blocking_session_id > 0;

-- Соединение 2
-- Остановите транзакцию, укажите параметр LOCK_TIMEOUT, повторите попытку
SET LOCK_TIMEOUT 5000;

SELECT productid, unitprice
FROM Production.Products -- WITH (READCOMMITTEDLOCK)
WHERE productid = 2;

-- Уберите время ожидания
SET LOCK_TIMEOUT -1;

SELECT productid, unitprice
FROM Production.Products -- WITH (READCOMMITTEDLOCK)
WHERE productid = 2;

-- Соединение 3
KILL 52;

---------------------------------------------------------------------
-- Уровни изоляции
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Уроверь изоляции READ UNCOMMITTED
---------------------------------------------------------------------

-- Соединение 1
BEGIN TRAN;

  UPDATE Production.Products
    SET unitprice += 1.00
  WHERE productid = 2;

  SELECT productid, unitprice
  FROM Production.Products
  WHERE productid = 2;

-- Соединение 2
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT productid, unitprice
FROM Production.Products
WHERE productid = 2;

-- Соединение 1
ROLLBACK TRAN;

---------------------------------------------------------------------
-- Уроверь изоляции READ COMMITTED
---------------------------------------------------------------------

-- Соединение 1
BEGIN TRAN;

  UPDATE Production.Products
    SET unitprice += 1.00
  WHERE productid = 2;

  SELECT productid, unitprice
  FROM Production.Products
  WHERE productid = 2;

-- Соединение 2
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT productid, unitprice
FROM Production.Products -- WITH (READCOMMITTEDLOCK)
WHERE productid = 2;

-- Соединение 1
COMMIT TRAN;

-- Очистите БД
UPDATE Production.Products
  SET unitprice = 19.00
WHERE productid = 2;

---------------------------------------------------------------------
-- Уроверь изоляции REPEATABLE READ
---------------------------------------------------------------------

-- Соединение 1
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

BEGIN TRAN;

  SELECT productid, unitprice
  FROM Production.Products
  WHERE productid = 2;

-- Соединение 2
UPDATE Production.Products
  SET unitprice += 1.00
WHERE productid = 2;

-- Соединение 1
  SELECT productid, unitprice
  FROM Production.Products
  WHERE productid = 2;

COMMIT TRAN;

-- Очистите БД
UPDATE Production.Products
  SET unitprice = 19.00
WHERE productid = 2;

---------------------------------------------------------------------
-- Уроверь изоляции SERIALIZABLE
---------------------------------------------------------------------

-- Соединение 1
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

BEGIN TRAN

  SELECT productid, productname, categoryid, unitprice
  FROM Production.Products
  WHERE categoryid = 1;

-- Соединение 2
INSERT INTO Production.Products
    (productname, supplierid, categoryid,
     unitprice, discontinued)
  VALUES('Продукт ABCDE', 1, 1, 20.00, 0);

-- Соединение 1
  SELECT productid, productname, categoryid, unitprice
  FROM Production.Products
  WHERE categoryid = 1;

COMMIT TRAN;

-- Очистите БД
DELETE FROM Production.Products
WHERE productid > 77;

-- Выполните этот код во всех соединениях:
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

---------------------------------------------------------------------
-- Уровни изоляции, основанные на управлении версиями строк
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Уроверь изоляции SNAPSHOT
---------------------------------------------------------------------

-- Включение уровня изоляции SNAPSHOT на уровне базы данных
-- в SQL Azure он включен по умолчанию
ALTER DATABASE TSQL2012 SET ALLOW_SNAPSHOT_ISOLATION ON;

-- Соединение 1
BEGIN TRAN;

  UPDATE Production.Products
    SET unitprice += 1.00
  WHERE productid = 2;

  SELECT productid, unitprice
  FROM Production.Products
  WHERE productid = 2;

-- Соединение 2
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

BEGIN TRAN;

  SELECT productid, unitprice
  FROM Production.Products
  WHERE productid = 2;

-- Соединение 1

COMMIT TRAN;

-- Соединение 2

  SELECT productid, unitprice
  FROM Production.Products
  WHERE productid = 2;

COMMIT TRAN;

-- Соединение 2
BEGIN TRAN

  SELECT productid, unitprice
  FROM Production.Products
  WHERE productid = 2;

COMMIT TRAN;

-- Очистите БД
UPDATE Production.Products
  SET unitprice = 19.00
WHERE productid = 2;

---------------------------------------------------------------------
-- Обнаружение конфликтов
---------------------------------------------------------------------

-- Соединение 1, шаг 1
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

BEGIN TRAN;

  SELECT productid, unitprice
  FROM Production.Products
  WHERE productid = 2;

-- Соединение 1, шаг 2
  UPDATE Production.Products
    SET unitprice = 20.00
  WHERE productid = 2;
  
COMMIT TRAN;

-- Очистите БД
UPDATE Production.Products
  SET unitprice = 19.00
WHERE productid = 2;

-- Соединение 1, шаг 1
BEGIN TRAN;

  SELECT productid, unitprice
  FROM Production.Products
  WHERE productid = 2;

-- Соединение 2, шаг 1
UPDATE Production.Products
  SET unitprice = 25.00
WHERE productid = 2;

-- Соединение 1, шаг 2
  UPDATE Production.Products
    SET unitprice = 20.00
  WHERE productid = 2;

-- Очистите БД
UPDATE Production.Products
  SET unitprice = 19.00
WHERE productid = 2;

-- Закройте все соединения

---------------------------------------------------------------------
-- Уроверь изоляции READ COMMITTED SNAPSHOT
---------------------------------------------------------------------

-- Включение уровня изоляции READ_COMMITTED_SNAPSHOT на уровне базы данных
-- в SQL Azure он включен по умолчанию
ALTER DATABASE TSQL2012 SET READ_COMMITTED_SNAPSHOT ON; 

-- Соединение 1
USE TSQL2012;

BEGIN TRAN;

  UPDATE Production.Products
    SET unitprice += 1.00
  WHERE productid = 2;

  SELECT productid, unitprice
  FROM Production.Products
  WHERE productid = 2;

-- Соединение 2
BEGIN TRAN;

  SELECT productid, unitprice
  FROM Production.Products
  WHERE productid = 2;

-- Соединение 1

COMMIT TRAN;

-- Соединение 2

  SELECT productid, unitprice
  FROM Production.Products
  WHERE productid = 2;

COMMIT TRAN;

-- Очистите БД
UPDATE Production.Products
  SET unitprice = 19.00
WHERE productid = 2;

-- Закройте все соединения

-- Верните режим, который используется по умолчанию
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Верните стандартные параметры базы данных
ALTER DATABASE TSQL2012 SET ALLOW_SNAPSHOT_ISOLATION OFF;
ALTER DATABASE TSQL2012 SET READ_COMMITTED_SNAPSHOT OFF;

---------------------------------------------------------------------
-- Взаимное блокирование
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Простой пример взаимного блокирования
---------------------------------------------------------------------

-- Соединение 1
USE TSQL2012;

BEGIN TRAN;

  UPDATE Production.Products
    SET unitprice += 1.00
  WHERE productid = 2;

-- Соединение 2
BEGIN TRAN;

  UPDATE Sales.OrderDetails
    SET unitprice += 1.00
  WHERE productid = 2;

-- Соединение 1

  SELECT orderid, productid, unitprice
  FROM Sales.OrderDetails -- WITH (READCOMMITTEDLOCK)
  WHERE productid = 2;

COMMIT TRAN;

-- Соединение 2

  SELECT productid, unitprice
  FROM Production.Products -- WITH (READCOMMITTEDLOCK)
  WHERE productid = 2;

COMMIT TRAN;

-- Очистите БД
UPDATE Production.Products
  SET unitprice = 19.00
WHERE productid = 2;

UPDATE Sales.OrderDetails
  SET unitprice = 19.00
WHERE productid = 2
  AND orderid >= 10500;

UPDATE Sales.OrderDetails
  SET unitprice = 15.20
WHERE productid = 2
  AND orderid < 10500;
