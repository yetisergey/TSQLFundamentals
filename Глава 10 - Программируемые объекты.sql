---------------------------------------------------------------------
-- Microsoft SQL Server 2012: Основы T-SQL
-- Глава 10 - Программируемые объекты
-- © Ицик Бен-Ган
---------------------------------------------------------------------

SET NOCOUNT ON;
USE TSQL2012;

---------------------------------------------------------------------
-- Переменные
---------------------------------------------------------------------

-- Объявите и инициализируйте переменную
DECLARE @i AS INT;
SET @i = 10;
GO

-- Объявите и инициализируйте переменную в одном выражении
DECLARE @i AS INT = 10;
GO

-- Сохраните результат выполнения вложенного запроса в переменную
DECLARE @empname AS NVARCHAR(31);

SET @empname = (SELECT firstname + N' ' + lastname
                FROM HR.Employees
                WHERE empid = 3);

SELECT @empname AS empname;
GO

-- Использование команды SET для последовательного присваивания значений
DECLARE @firstname AS NVARCHAR(10), @lastname AS NVARCHAR(20);

SET @firstname = (SELECT firstname
                  FROM HR.Employees
                  WHERE empid = 3);
SET @lastname = (SELECT lastname
                  FROM HR.Employees
                  WHERE empid = 3);

SELECT @firstname AS firstname, @lastname AS lastname;
GO

-- Использование команды  SELECT для одновременного присваивания
-- нескольких значений
DECLARE @firstname AS NVARCHAR(10), @lastname AS NVARCHAR(20);

SELECT
  @firstname = firstname,
  @lastname  = lastname
FROM HR.Employees
WHERE empid = 3;

SELECT @firstname AS firstname, @lastname AS lastname;
GO

-- Команда SELECT не завершается ошибкой при получении нескольких строк
DECLARE @empname AS NVARCHAR(31);

SELECT @empname = firstname + N' ' + lastname
FROM HR.Employees
WHERE mgrid = 2;

SELECT @empname AS empname;
GO

-- Команда SET не завершается ошибкой при получении нескольких строк
DECLARE @empname AS NVARCHAR(31);

SET @empname = (SELECT firstname + N' ' + lastname
                FROM HR.Employees
                WHERE mgrid = 2);

SELECT @empname AS empname;
GO

---------------------------------------------------------------------
-- Пакеты
---------------------------------------------------------------------

-- Анализ пакетов

-- Корректный пакет
PRINT 'Первый пакет';
USE TSQL2012;
GO
-- Некорректный пакет
PRINT 'Второй пакет';
SELECT custid FROM Sales.Customers;
SELECT orderid FOM Sales.Orders;
GO
-- Корректный пакет
PRINT 'Третий пакет';
SELECT empid FROM HR.Employees;

-- Пакеты и переменные

DECLARE @i AS INT = 10;
-- Выполняется успешно
PRINT @i;
GO

-- Завершается ошибкой
PRINT @i;
GO

-- Команды, которые не могут находиться в одном пакете с другими командами

IF OBJECT_ID('Sales.MyView', 'V') IS NOT NULL DROP VIEW Sales.MyView;

CREATE VIEW Sales.MyView
AS

SELECT YEAR(orderdate) AS orderyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY YEAR(orderdate);
GO

-- Разрешение имен в пакетах

-- Создайте таблицу T1 с одним столбцом
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;
CREATE TABLE dbo.T1(col1 INT);
GO

-- Следующий код завершится ошибкой
ALTER TABLE dbo.T1 ADD col2 INT;
SELECT col1, col2 FROM dbo.T1;
GO

-- Следующий код выполнится успешно
ALTER TABLE dbo.T1 ADD col2 INT;
GO
SELECT col1, col2 FROM dbo.T1;
GO

-- Параметр GO n

-- Создайте таблицу T1 со столбцом identity
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;
CREATE TABLE dbo.T1(col1 INT IDENTITY CONSTRAINT PK_T1 PRIMARY KEY);
GO

-- Отключите вывод команды INSERT
SET NOCOUNT ON;
GO

-- Выполните пакет 100 раз
INSERT INTO dbo.T1 DEFAULT VALUES;
GO 100

SELECT * FROM dbo.T1;

---------------------------------------------------------------------
-- Управление потоком выполнения
---------------------------------------------------------------------

-- Инструкция IF ... ELSE
IF YEAR(SYSDATETIME()) <> YEAR(DATEADD(day, 1, SYSDATETIME()))
  PRINT 'Сегодня последний день в году.';
ELSE
  PRINT 'Сегодня не последний день в году.';
GO

-- IF ELSE IF
IF YEAR(SYSDATETIME()) <> YEAR(DATEADD(day, 1, SYSDATETIME()))
  PRINT 'Сегодня последний день в году.';
ELSE
  IF MONTH(SYSDATETIME()) <> MONTH(DATEADD(day, 1, SYSDATETIME()))
    PRINT 'Сегодня последний день месяца, но не последний день в году.';
  ELSE
    PRINT 'Сегодня не последний день месяца.';
GO

-- Блок команд
IF DAY(SYSDATETIME()) = 1
  BEGIN
    PRINT 'Сегодня первый день месяца.';
    PRINT 'Запускаем процесс первый-день-месяца.';
    /* ... здесь должен быть код процесса ... */
    PRINT 'Завершаем процесс первый-день-месяца.';
  END
ELSE
  BEGIN
    PRINT 'Today is not the first day of the month.';
    PRINT 'Запускаем процесс не-первый-день-месяца.';
    /* ... здесь должен быть код процесса ... */
    PRINT 'Завершаем процесс не-первый-день-месяца.';
  END
GO

-- Инструкция  WHILE
DECLARE @i AS INT = 1;
WHILE @i <= 10
BEGIN
  PRINT @i;
  SET @i = @i + 1;
END;
GO

-- Команда BREAK
DECLARE @i AS INT = 1;
WHILE @i <= 10
BEGIN
  IF @i = 6 BREAK;
  PRINT @i;
  SET @i = @i + 1;
END;
GO

-- Команда CONTINUE
DECLARE @i AS INT = 0;
WHILE @i < 10
BEGIN
  SET @i = @i + 1;
  IF @i = 6 CONTINUE;
  PRINT @i;
END;
GO

-- Пример использования инструкций IF и WHILE
SET NOCOUNT ON;
IF OBJECT_ID('dbo.Numbers', 'U') IS NOT NULL DROP TABLE dbo.Numbers;
CREATE TABLE dbo.Numbers(n INT NOT NULL PRIMARY KEY);
GO

DECLARE @i AS INT = 1;
WHILE @i <= 1000
BEGIN
  INSERT INTO dbo.Numbers(n) VALUES(@i);
  SET @i = @i + 1;
END
GO

---------------------------------------------------------------------
-- Курсоры
---------------------------------------------------------------------

-- Пример: текущие агрегаты
SET NOCOUNT ON;

DECLARE @Result TABLE
(
  custid     INT,
  ordermonth DATETIME,
  qty        INT, 
  runqty     INT,
  PRIMARY KEY(custid, ordermonth)
);

DECLARE
  @custid     AS INT,
  @prvcustid  AS INT,
  @ordermonth DATETIME,
  @qty        AS INT,
  @runqty     AS INT;

DECLARE C CURSOR FAST_FORWARD /* только прямое чтение */ FOR
  SELECT custid, ordermonth, qty
  FROM Sales.CustOrders
  ORDER BY custid, ordermonth;

OPEN C;

FETCH NEXT FROM C INTO @custid, @ordermonth, @qty;

SELECT @prvcustid = @custid, @runqty = 0;

WHILE @@FETCH_STATUS = 0
BEGIN
  IF @custid <> @prvcustid
    SELECT @prvcustid = @custid, @runqty = 0;

  SET @runqty = @runqty + @qty;

  INSERT INTO @Result VALUES(@custid, @ordermonth, @qty, @runqty);
  
  FETCH NEXT FROM C INTO @custid, @ordermonth, @qty;
END

CLOSE C;

DEALLOCATE C;

SELECT 
  custid,
  CONVERT(VARCHAR(7), ordermonth, 121) AS ordermonth,
  qty,
  runqty
FROM @Result
ORDER BY custid, ordermonth;
GO

-- Примечание: SQL Server 2012 поддерживает улучшенные оконные функции,
-- которые позволяют вычислять текущие агрегаты более эффективно
SELECT custid, ordermonth, qty,
  SUM(qty) OVER(PARTITION BY custid
                ORDER BY ordermonth
                ROWS UNBOUNDED PRECEDING) AS runqty
FROM Sales.CustOrders
ORDER BY custid, ordermonth;

---------------------------------------------------------------------
-- Временные таблицы
---------------------------------------------------------------------

-- Локальные временные таблицы

IF OBJECT_ID('tempdb.dbo.#MyOrderTotalsByYear') IS NOT NULL
  DROP TABLE dbo.#MyOrderTotalsByYear;
GO

CREATE TABLE #MyOrderTotalsByYear
(
  orderyear INT NOT NULL PRIMARY KEY,
  qty       INT NOT NULL
);

INSERT INTO #MyOrderTotalsByYear(orderyear, qty)
  SELECT
    YEAR(O.orderdate) AS orderyear,
    SUM(OD.qty) AS qty
  FROM Sales.Orders AS O
    JOIN Sales.OrderDetails AS OD
      ON OD.orderid = O.orderid
  GROUP BY YEAR(orderdate);

SELECT Cur.orderyear, Cur.qty AS curyearqty, Prv.qty AS prvyearqty
FROM dbo.#MyOrderTotalsByYear AS Cur
  LEFT OUTER JOIN dbo.#MyOrderTotalsByYear AS Prv
    ON Cur.orderyear = Prv.orderyear + 1;
GO

-- Попытайтесь обратиться к таблице из другой сессии
SELECT orderyear, qty FROM dbo.#MyOrderTotalsByYear;

-- Выполните очистку в исходной сессии
IF OBJECT_ID('tempdb.dbo.#MyOrderTotalsByYear') IS NOT NULL
  DROP TABLE dbo.#MyOrderTotalsByYear;

-- Глобальные временные таблицы
CREATE TABLE dbo.##Globals
(
  id  sysname     NOT NULL PRIMARY KEY,
  val SQL_VARIANT NOT NULL
);

-- Запустите этот код в любой сессии
INSERT INTO dbo.##Globals(id, val) VALUES(N'i', CAST(10 AS INT));

-- Запустите этот код в любой сессии
SELECT val FROM dbo.##Globals WHERE id = N'i';

-- Запустите этот код в любой сессии
DROP TABLE dbo.##Globals;
GO

-- Табличные переменные
DECLARE @MyOrderTotalsByYear TABLE
(
  orderyear INT NOT NULL PRIMARY KEY,
  qty       INT NOT NULL
);

INSERT INTO @MyOrderTotalsByYear(orderyear, qty)
  SELECT
    YEAR(O.orderdate) AS orderyear,
    SUM(OD.qty) AS qty
  FROM Sales.Orders AS O
    JOIN Sales.OrderDetails AS OD
      ON OD.orderid = O.orderid
  GROUP BY YEAR(orderdate);

SELECT Cur.orderyear, Cur.qty AS curyearqty, Prv.qty AS prvyearqty
FROM @MyOrderTotalsByYear AS Cur
  LEFT OUTER JOIN @MyOrderTotalsByYear AS Prv
    ON Cur.orderyear = Prv.orderyear + 1;
GO

-- с использованием функции LAG
DECLARE @MyOrderTotalsByYear TABLE
(
  orderyear INT NOT NULL PRIMARY KEY,
  qty       INT NOT NULL
);

INSERT INTO @MyOrderTotalsByYear(orderyear, qty)
  SELECT
    YEAR(O.orderdate) AS orderyear,
    SUM(OD.qty) AS qty
  FROM Sales.Orders AS O
    JOIN Sales.OrderDetails AS OD
      ON OD.orderid = O.orderid
  GROUP BY YEAR(orderdate);

SELECT orderyear, qty AS curyearqty,
  LAG(qty) OVER(ORDER BY orderyear) AS prvyearqty
FROM @MyOrderTotalsByYear;
GO

-- Табличные типы
IF TYPE_ID('dbo.OrderTotalsByYear') IS NOT NULL
  DROP TYPE dbo.OrderTotalsByYear;

CREATE TYPE dbo.OrderTotalsByYear AS TABLE
(
  orderyear INT NOT NULL PRIMARY KEY,
  qty       INT NOT NULL
);
GO

-- Использование табличного типа
DECLARE @MyOrderTotalsByYear AS dbo.OrderTotalsByYear;

INSERT INTO @MyOrderTotalsByYear(orderyear, qty)
  SELECT
    YEAR(O.orderdate) AS orderyear,
    SUM(OD.qty) AS qty
  FROM Sales.Orders AS O
    JOIN Sales.OrderDetails AS OD
      ON OD.orderid = O.orderid
  GROUP BY YEAR(orderdate);

SELECT orderyear, qty FROM @MyOrderTotalsByYear;
GO

---------------------------------------------------------------------
-- Динамические возможности языка SQL
---------------------------------------------------------------------

-- Команда EXEC 

-- Простой пример использования команды EXEC
DECLARE @sql AS VARCHAR(100);
SET @sql = 'PRINT ''Это сообщение было напечатано динамическим SQL-пакетом.'';';
EXEC(@sql);
GO

-- Хранимая процедура sp_executesql

-- Простой пример использования sp_executesql
DECLARE @sql AS NVARCHAR(100);

SET @sql = N'SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE orderid = @orderid;';

EXEC sys.sp_executesql
  @stmt = @sql,
  @params = N'@orderid AS INT',
  @orderid = 10248;
GO

---------------------------------------------------------------------
-- Динамическое использование оператора PIVOT (углубленный, по желанию)
---------------------------------------------------------------------

-- Статическое разворачивание
SELECT *
FROM (SELECT shipperid, YEAR(orderdate) AS orderyear, freight
      FROM Sales.Orders) AS D
  PIVOT(SUM(freight) FOR orderyear IN([2006],[2007],[2008])) AS P;

-- Динамическое разворачивание
DECLARE
  @sql       AS NVARCHAR(1000),
  @orderyear AS INT,
  @first     AS INT;

DECLARE C CURSOR FAST_FORWARD FOR
  SELECT DISTINCT(YEAR(orderdate)) AS orderyear
  FROM Sales.Orders
  ORDER BY orderyear;

SET @first = 1;

SET @sql = N'SELECT *
FROM (SELECT shipperid, YEAR(orderdate) AS orderyear, freight
      FROM Sales.Orders) AS D
  PIVOT(SUM(freight) FOR orderyear IN(';

OPEN C;

FETCH NEXT FROM C INTO @orderyear;

WHILE @@fetch_status = 0
BEGIN
  IF @first = 0
    SET @sql = @sql + N','
  ELSE
    SET @first = 0;

  SET @sql = @sql + QUOTENAME(@orderyear);

  FETCH NEXT FROM C INTO @orderyear;
END

CLOSE C;

DEALLOCATE C;

SET @sql = @sql + N')) AS P;';

EXEC sys.sp_executesql @stmt = @sql;
GO

---------------------------------------------------------------------
-- Процедуры
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Пользовательские функции
---------------------------------------------------------------------

IF OBJECT_ID('dbo.GetAge') IS NOT NULL DROP FUNCTION dbo.GetAge;
GO

CREATE FUNCTION dbo.GetAge
(
  @birthdate AS DATE,
  @eventdate AS DATE
)
RETURNS INT
AS
BEGIN
  RETURN
    DATEDIFF(year, @birthdate, @eventdate)
    - CASE WHEN 100 * MONTH(@eventdate) + DAY(@eventdate)
              < 100 * MONTH(@birthdate) + DAY(@birthdate)
           THEN 1 ELSE 0
      END;
END;
GO

-- Проверочная функция
SELECT
  empid, firstname, lastname, birthdate,
  dbo.GetAge(birthdate, SYSDATETIME()) AS age
FROM HR.Employees;

---------------------------------------------------------------------
-- Хранимые процедуры
---------------------------------------------------------------------

-- Использование хранимой процедуры
IF OBJECT_ID('Sales.GetCustomerOrders', 'P') IS NOT NULL
  DROP PROC Sales.GetCustomerOrders;
GO

CREATE PROC Sales.GetCustomerOrders
  @custid   AS INT,
  @fromdate AS DATETIME = '19000101',
  @todate   AS DATETIME = '99991231',
  @numrows  AS INT OUTPUT
AS
SET NOCOUNT ON;

SELECT orderid, custid, empid, orderdate
FROM Sales.Orders
WHERE custid = @custid
  AND orderdate >= @fromdate
  AND orderdate < @todate;

SET @numrows = @@rowcount;
GO

DECLARE @rc AS INT;

EXEC Sales.GetCustomerOrders
  @custid   = 1, -- Попробуйте также подставить значение 100
  @fromdate = '20070101',
  @todate   = '20080101',
  @numrows  = @rc OUTPUT;

SELECT @rc AS numrows;
GO

---------------------------------------------------------------------
-- Триггеры
---------------------------------------------------------------------

-- Пример DML-триггера для аудита таблицы
IF OBJECT_ID('dbo.T1_Audit', 'U') IS NOT NULL DROP TABLE dbo.T1_Audit;
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;

CREATE TABLE dbo.T1
(
  keycol  INT         NOT NULL PRIMARY KEY,
  datacol VARCHAR(10) NOT NULL
);

CREATE TABLE dbo.T1_Audit
(
  audit_lsn  INT         NOT NULL IDENTITY PRIMARY KEY,
  dt         DATETIME    NOT NULL DEFAULT(SYSDATETIME()),
  login_name sysname     NOT NULL DEFAULT(ORIGINAL_LOGIN()),
  keycol     INT         NOT NULL,
  datacol    VARCHAR(10) NOT NULL
);
GO

CREATE TRIGGER trg_T1_insert_audit ON dbo.T1 AFTER INSERT
AS
SET NOCOUNT ON;

INSERT INTO dbo.T1_Audit(keycol, datacol)
  SELECT keycol, datacol FROM inserted;
GO

INSERT INTO dbo.T1(keycol, datacol) VALUES(10, 'a');
INSERT INTO dbo.T1(keycol, datacol) VALUES(30, 'x');
INSERT INTO dbo.T1(keycol, datacol) VALUES(20, 'g');

SELECT audit_lsn, dt, login_name, keycol, datacol
FROM dbo.T1_Audit;
GO

-- очистка
IF OBJECT_ID('dbo.T1_Audit', 'U') IS NOT NULL DROP TABLE dbo.T1_Audit;
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;

-- Пример DDL-триггера для аудита таблицы

-- Скрипт для создания таблицы AuditDDLEvents и триггера trg_audit_ddl_events
IF OBJECT_ID('dbo.AuditDDLEvents', 'U') IS NOT NULL
  DROP TABLE dbo.AuditDDLEvents;

CREATE TABLE dbo.AuditDDLEvents
(
  audit_lsn        INT      NOT NULL IDENTITY,
  posttime         DATETIME NOT NULL,
  eventtype        sysname  NOT NULL,
  loginname        sysname  NOT NULL,
  schemaname       sysname  NOT NULL,
  objectname       sysname  NOT NULL,
  targetobjectname sysname  NULL,
  eventdata        XML      NOT NULL,
  CONSTRAINT PK_AuditDDLEvents PRIMARY KEY(audit_lsn)
);
GO

CREATE TRIGGER trg_audit_ddl_events
  ON DATABASE FOR DDL_DATABASE_LEVEL_EVENTS
AS
SET NOCOUNT ON;

DECLARE @eventdata AS XML = EVENTDATA();

INSERT INTO dbo.AuditDDLEvents(
  posttime, eventtype, loginname, schemaname, 
  objectname, targetobjectname, eventdata)
  VALUES(
    @eventdata.value('(/EVENT_INSTANCE/PostTime)[1]',         'VARCHAR(23)'),
    @eventdata.value('(/EVENT_INSTANCE/EventType)[1]',        'sysname'),
    @eventdata.value('(/EVENT_INSTANCE/LoginName)[1]',        'sysname'),
    @eventdata.value('(/EVENT_INSTANCE/SchemaName)[1]',       'sysname'),
    @eventdata.value('(/EVENT_INSTANCE/ObjectName)[1]',       'sysname'),
    @eventdata.value('(/EVENT_INSTANCE/TargetObjectName)[1]', 'sysname'),
    @eventdata);
GO

-- Проверочный триггер trg_audit_ddl_events
CREATE TABLE dbo.T1(col1 INT NOT NULL PRIMARY KEY);
ALTER TABLE dbo.T1 ADD col2 INT NULL;
ALTER TABLE dbo.T1 ALTER COLUMN col2 INT NOT NULL;
CREATE NONCLUSTERED INDEX idx1 ON dbo.T1(col2);
GO

SELECT * FROM dbo.AuditDDLEvents;
GO

-- очистка
DROP TRIGGER trg_audit_ddl_events ON DATABASE;
DROP TABLE dbo.AuditDDLEvents;
GO

---------------------------------------------------------------------
-- Обработка ошибок
---------------------------------------------------------------------

-- Простой пример
BEGIN TRY
  PRINT 10/2;
  PRINT 'Нет ошибок';
END TRY
BEGIN CATCH
  PRINT 'Ошибка';
END CATCH;
GO

BEGIN TRY
  PRINT 10/0;
  PRINT 'Нет ошибок';
END TRY
BEGIN CATCH
  PRINT 'Ошибка';
END CATCH;
GO

-- Скрипт для создания в текущей БД таблицы Employees
IF OBJECT_ID('dbo.Employees') IS NOT NULL DROP TABLE dbo.Employees;
CREATE TABLE dbo.Employees
(
  empid   INT         NOT NULL,
  empname VARCHAR(25) NOT NULL,
  mgrid   INT         NULL,
  CONSTRAINT PK_Employees PRIMARY KEY(empid),
  CONSTRAINT CHK_Employees_empid CHECK(empid > 0),
  CONSTRAINT FK_Employees_Employees
    FOREIGN KEY(mgrid) REFERENCES dbo.Employees(empid)
);
GO

-- Подробный пример
BEGIN TRY

  INSERT INTO dbo.Employees(empid, empname, mgrid)
    VALUES(1, 'Emp1', NULL);
  -- Попробуйте присвоить empid значения 0, 'A', NULL

END TRY
BEGIN CATCH

  IF ERROR_NUMBER() = 2627
  BEGIN
    PRINT ' Обрабатываем нарушения первичного ключа...';
  END
  ELSE IF ERROR_NUMBER() = 547
  BEGIN
    PRINT ' Обрабатываем нарушения ограничений CHECK/FK...';
  END
  ELSE IF ERROR_NUMBER() = 515
  BEGIN
    PRINT ' Обрабатываем нарушение ограничения NOT NULL...';
  END
  ELSE IF ERROR_NUMBER() = 245
  BEGIN
    PRINT ' Обрабатываем ошибку приведения типов...';
  END
  ELSE
  BEGIN
    PRINT ' Генерируем ошибку еще раз...';
    THROW; -- SQL Server 2012 only
  END

  PRINT ' Номер : '     + CAST(ERROR_NUMBER() AS VARCHAR(10));
  PRINT ' Сообщение : ' + ERROR_MESSAGE();
  PRINT ' Степень важности: '
    + CAST(ERROR_SEVERITY() AS VARCHAR(10));
  PRINT ' Состояние : ' + CAST(ERROR_STATE() AS VARCHAR(10));
  PRINT ' Строка : '    + CAST(ERROR_LINE() AS VARCHAR(10));
  PRINT ' Процедура : ' + COALESCE(ERROR_PROCEDURE(), 'За пределами процедуры');

 
END CATCH;
GO

-- Инкапсуляция кода для его повторного использования
IF OBJECT_ID('dbo.ErrInsertHandler', 'P') IS NOT NULL
  DROP PROC dbo.ErrInsertHandler;
GO

CREATE PROC dbo.ErrInsertHandler
AS
SET NOCOUNT ON;

IF ERROR_NUMBER() = 2627
BEGIN
  PRINT ' Обрабатываем нарушения первичного ключа...';
END
ELSE IF ERROR_NUMBER() = 547
BEGIN
  PRINT ' Обрабатываем нарушения ограничений CHECK/FK...';
END
ELSE IF ERROR_NUMBER() = 515
BEGIN
  PRINT ' Обрабатываем нарушение ограничения NOT NULL...';
END
ELSE IF ERROR_NUMBER() = 245
BEGIN
  PRINT ' Обрабатываем ошибку приведения типов...';
END

PRINT ' Номер : '     + CAST(ERROR_NUMBER() AS VARCHAR(10));
PRINT ' Сообщение : ' + ERROR_MESSAGE();
PRINT ' Степень важности: '
  + CAST(ERROR_SEVERITY() AS VARCHAR(10));
PRINT ' Состояние : ' + CAST(ERROR_STATE() AS VARCHAR(10));
PRINT ' Строка : '    + CAST(ERROR_LINE() AS VARCHAR(10));
PRINT ' Процедура : ' + COALESCE(ERROR_PROCEDURE(), 'За пределами процедуры');
GO

-- Вызов процедуры в блоке CATCH
BEGIN TRY

  INSERT INTO dbo.Employees(empid, empname, mgrid)
    VALUES(1, 'Emp1', NULL);

END TRY
BEGIN CATCH

  IF ERROR_NUMBER() IN (2627, 547, 515, 245)
    EXEC dbo.ErrInsertHandler;
  ELSE
    THROW; -- только в SQL Server 2012
  
END CATCH;
