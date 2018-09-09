---------------------------------------------------------------------
-- Microsoft SQL Server 2012: Основы T-SQL
-- Глава 04 - Вложенные запросы
-- © Ицик Бен-Ган
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Автономные вложенные запросы
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Скалярные вложенные запросы
---------------------------------------------------------------------

-- Заказы с максимальным идентификатором
USE TSQL2012;

DECLARE @maxid AS INT = (SELECT MAX(orderid)
                         FROM Sales.Orders);

SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderid = @maxid;
GO

SELECT orderid, orderdate, empid, custid
FROM Sales.Orders
WHERE orderid = (SELECT MAX(O.orderid)
                 FROM Sales.Orders AS O);

-- Скалярный вложенный запрос, который должен вернуть одно значение
SELECT orderid
FROM Sales.Orders
WHERE empid = 
  (SELECT E.empid
   FROM HR.Employees AS E
   WHERE E.lastname LIKE N'Б%');

SELECT orderid
FROM Sales.Orders
WHERE empid = 
  (SELECT E.empid
   FROM HR.Employees AS E
   WHERE E.lastname LIKE N'А%');

SELECT orderid
FROM Sales.Orders
WHERE empid = 
  (SELECT E.empid
   FROM HR.Employees AS E
   WHERE E.lastname LIKE N'Д%');

---------------------------------------------------------------------
-- Вложенные запросы с множественными значениями
---------------------------------------------------------------------

SELECT orderid
FROM Sales.Orders
WHERE empid IN
  (SELECT E.empid
   FROM HR.Employees AS E
   WHERE E.lastname LIKE N'А%');

SELECT O.orderid
FROM HR.Employees AS E
  JOIN Sales.Orders AS O
    ON E.empid = O.empid
WHERE E.lastname LIKE N'А%';

-- Заказы, размещенные американскими клиентами
SELECT custid, orderid, orderdate, empid
FROM Sales.Orders
WHERE custid IN
  (SELECT C.custid
   FROM Sales.Customers AS C
   WHERE C.country = N'США');

-- Клиенты, которые не размещали заказов
SELECT custid, companyname
FROM Sales.Customers
WHERE custid NOT IN
  (SELECT O.custid
   FROM Sales.Orders AS O);

-- Пропущенные идентификаторы заказов
USE TSQL2012;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
CREATE TABLE dbo.Orders(orderid INT NOT NULL CONSTRAINT PK_Orders PRIMARY KEY);

INSERT INTO dbo.Orders(orderid)
  SELECT orderid
  FROM Sales.Orders
  WHERE orderid % 2 = 0;

SELECT n
FROM dbo.Nums
WHERE n BETWEEN (SELECT MIN(O.orderid) FROM dbo.Orders AS O)
            AND (SELECT MAX(O.orderid) FROM dbo.Orders AS O)
  AND n NOT IN (SELECT O.orderid FROM dbo.Orders AS O);

-- Очистка
DROP TABLE dbo.Orders;

---------------------------------------------------------------------
-- Коррелирующие вложенные запросы
---------------------------------------------------------------------

-- Заказы с мкасимальным идентификатором для кажлого клиента
-- Листинг 4.1: Коррелирующие вложенные запросы
USE TSQL2012;

SELECT custid, orderid, orderdate, empid
FROM Sales.Orders AS O1
WHERE orderid =
  (SELECT MAX(O2.orderid)
   FROM Sales.Orders AS O2
   WHERE O2.custid = O1.custid);

SELECT MAX(O2.orderid)
FROM Sales.Orders AS O2
WHERE O2.custid = 85;

-- Доля заказов в общей стоимости заказанных товаров для каждого клиента
SELECT orderid, custid, val,
  CAST(100. * val / (SELECT SUM(O2.val)
                     FROM Sales.OrderValues AS O2
                     WHERE O2.custid = O1.custid)
       AS NUMERIC(5,2)) AS pct
FROM Sales.OrderValues AS O1
ORDER BY custid, orderid;

---------------------------------------------------------------------
-- Предикат EXISTS
---------------------------------------------------------------------

-- Испанские клиенты, которые размещали заказы
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE country = N'Испания'
  AND EXISTS
    (SELECT * FROM Sales.Orders AS O
     WHERE O.custid = C.custid);

-- Испанские клиенты, которые не размещали заказов
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE country = N'Испания'
  AND NOT EXISTS
    (SELECT * FROM Sales.Orders AS O
     WHERE O.custid = C.custid);

---------------------------------------------------------------------
-- Примеры сложных вложенных запросов
-- (углубленные, по желанию)
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Возвращение предыдущих или следующих значений
---------------------------------------------------------------------
SELECT orderid, orderdate, empid, custid,
  (SELECT MAX(O2.orderid)
   FROM Sales.Orders AS O2
   WHERE O2.orderid < O1.orderid) AS prevorderid
FROM Sales.Orders AS O1;

SELECT orderid, orderdate, empid, custid,
  (SELECT MIN(O2.orderid)
   FROM Sales.Orders AS O2
   WHERE O2.orderid > O1.orderid) AS nextorderid
FROM Sales.Orders AS O1;

---------------------------------------------------------------------
-- Текущие агрегаты
---------------------------------------------------------------------

SELECT orderyear, qty
FROM Sales.OrderTotalsByYear;

SELECT orderyear, qty,
  (SELECT SUM(O2.qty)
   FROM Sales.OrderTotalsByYear AS O2
   WHERE O2.orderyear <= O1.orderyear) AS runqty
FROM Sales.OrderTotalsByYear AS O1
ORDER BY orderyear;

---------------------------------------------------------------------
-- Проблемы, связанные с вложенными запросами
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Проблема с отметками NULL
---------------------------------------------------------------------

-- Клиенты, не делали заказов

-- Использование предиката NOT IN
SELECT custid, companyname
FROM Sales.Customers
WHERE custid NOT IN(SELECT O.custid
                    FROM Sales.Orders AS O);

-- Добавление в таблицу Orders строки со значением NULL в столбце custid
INSERT INTO Sales.Orders
  (custid, empid, orderdate, requireddate, shippeddate, shipperid,
   freight, shipname, shipaddress, shipcity, shipregion,
   shippostalcode, shipcountry)
  VALUES(NULL, 1, '20090212', '20090212',
         '20090212', 1, 123.00, N'abc', N'abc', N'abc',
         N'abc', N'abc', N'abc');

-- Следующий код возвращает пустой набор
SELECT custid, companyname
FROM Sales.Customers
WHERE custid NOT IN(SELECT O.custid
                    FROM Sales.Orders AS O);

-- Исключение отметок NULL
SELECT custid, companyname
FROM Sales.Customers
WHERE custid NOT IN(SELECT O.custid 
                    FROM Sales.Orders AS O
                    WHERE O.custid IS NOT NULL);

-- Использование предиката NOT EXISTS
SELECT custid, companyname
FROM Sales.Customers AS C
WHERE NOT EXISTS
  (SELECT * 
   FROM Sales.Orders AS O
   WHERE O.custid = C.custid);

-- Очистка
DELETE FROM Sales.Orders WHERE custid IS NULL;

---------------------------------------------------------------------
-- Ошибки подстановки имен столбцов во вложенных запросах
---------------------------------------------------------------------

-- Создание и заполнение таблицы Sales.MyShippers
IF OBJECT_ID('Sales.MyShippers', 'U') IS NOT NULL
  DROP TABLE Sales.MyShippers;

CREATE TABLE Sales.MyShippers
(
  shipper_id  INT          NOT NULL,
  companyname NVARCHAR(40) NOT NULL,
  phone       NVARCHAR(24) NOT NULL,
  CONSTRAINT PK_MyShippers PRIMARY KEY(shipper_id)
);

INSERT INTO Sales.MyShippers(shipper_id, companyname, phone)
  VALUES(1, N'Поставщик GVSUA', N'(503) 555-0137'),
	      (2, N'Поставщик ETYNR', N'(425) 555-0136'),
				(3, N'Поставщик ZHISN', N'(415) 555-0138');

-- Поставщики, отправлявшие товар клиенту №43

-- Ошибка
SELECT shipper_id, companyname
FROM Sales.MyShippers
WHERE shipper_id IN
  (SELECT shipper_id
   FROM Sales.Orders
   WHERE custid = 43);

-- Безопасный способ использования псевдонимов, ошибка определена
SELECT shipper_id, companyname
FROM Sales.MyShippers
WHERE shipper_id IN
  (SELECT O.shipper_id
   FROM Sales.Orders AS O
   WHERE O.custid = 43);

-- Ошибка исправлена
SELECT shipper_id, companyname
FROM Sales.MyShippers
WHERE shipper_id IN
  (SELECT O.shipperid
   FROM Sales.Orders AS O
   WHERE O.custid = 43);

-- Очистка
IF OBJECT_ID('Sales.MyShippers', 'U') IS NOT NULL
  DROP TABLE Sales.MyShippers;
