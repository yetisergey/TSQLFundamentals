---------------------------------------------------------------------
-- Microsoft SQL Server 2012: Основы T-SQL
-- Глава 07 - Продвинутые запросы
-- Решения
-- © Ицик Бен-Ган
---------------------------------------------------------------------

-- Все примеры подразумевают обращение к таблице dbo.Orders,
-- которую вы создали и заполнили с помощью кода, представленного в листинге 7.1.

-- 1
-- Напишите запрос к таблице dbo.Orders, который вычисляет для каждого
-- клиентcкого заказа значения функций RANK и DENSE_RANK, с
-- секционированием по столбцу custid и сортировкой по qty. 

-- Ожидаемый результат:
custid orderid     qty         rnk                  drnk
------ ----------- ----------- -------------------- --------------------
A      30001       10          1                    1
A      40005       10          1                    1
A      10001       12          3                    2
A      40001       40          4                    3
B      20001       12          1                    1
B      30003       15          2                    2
B      10005       20          3                    3
C      10006       14          1                    1
C      20002       20          2                    2
C      30004       22          3                    3
D      30007       30          1                    1

-- Решение
SELECT custid, orderid, qty,
  RANK() OVER(PARTITION BY custid ORDER BY qty) AS rnk,
  DENSE_RANK() OVER(PARTITION BY custid ORDER BY qty) AS drnk
FROM dbo.Orders;

-- 2
-- Напишите запрос к таблице dbo.Orders, который вычисляет для каждой
-- строки разницу между количеством товара в текущем и предыдущем,
-- а также в текущем и следующем заказах.

-- Ожидаемый результат:
custid orderid     qty         diffprev    diffnext
------ ----------- ----------- ----------- -----------
A      30001       10          NULL        -2
A      10001       12          2           -28
A      40001       40          28          30
A      40005       10          -30         NULL
B      10005       20          NULL        8
B      20001       12          -8          -3
B      30003       15          3           NULL
C      30004       22          NULL        8
C      10006       14          -8          -6
C      20002       20          6           NULL
D      30007       30          NULL        NULL

-- Решение
SELECT custid, orderid, qty,
  qty - LAG(qty) OVER(PARTITION BY custid
                      ORDER BY orderdate, orderid) AS diffprev,
  qty - LEAD(qty) OVER(PARTITION BY custid
                       ORDER BY orderdate, orderid) AS diffnext
FROM dbo.Orders;

-- 3
-- Напишите запрос к таблице dbo.Orders, который возвращает строку для
-- каждого сотрудника, столбец для каждого года, в котором выполнялись
-- заказы, и количество заказов в каждом году и по каждому сотруднику.

-- Ожидаемый результат:
empid       cnt2007     cnt2008     cnt2009
----------- ----------- ----------- -----------
1           1           1           1
2           1           2           1
3           2           0           2

-- Решение

-- С помощью стандартных средств
USE TSQL2012;

SELECT empid,
  COUNT(CASE WHEN orderyear = 2007 THEN orderyear END) AS cnt2007,
  COUNT(CASE WHEN orderyear = 2008 THEN orderyear END) AS cnt2008,
  COUNT(CASE WHEN orderyear = 2009 THEN orderyear END) AS cnt2009  
FROM (SELECT empid, YEAR(orderdate) AS orderyear
      FROM dbo.Orders) AS D
GROUP BY empid;

-- С помощью встроенного оператора PIVOT 
SELECT empid, [2007] AS cnt2007, [2008] AS cnt2008, [2009] AS cnt2009
FROM (SELECT empid, YEAR(orderdate) AS orderyear
      FROM dbo.Orders) AS D
  PIVOT(COUNT(orderyear)
        FOR orderyear IN([2007], [2008], [2009])) AS P;

-- 4
-- Запустите следующий код, чтобы создать и заполнить таблицу EmpYearOrders:
USE TSQL2012;

IF OBJECT_ID('dbo.EmpYearOrders', 'U') IS NOT NULL DROP TABLE dbo.EmpYearOrders;

CREATE TABLE dbo.EmpYearOrders
(
  empid INT NOT NULL
    CONSTRAINT PK_EmpYearOrders PRIMARY KEY,
  cnt2007 INT NULL,
  cnt2008 INT NULL,
  cnt2009 INT NULL
);

INSERT INTO dbo.EmpYearOrders(empid, cnt2007, cnt2008, cnt2009)
  SELECT empid, [2007] AS cnt2007, [2008] AS cnt2008, [2009] AS cnt2009
  FROM (SELECT empid, YEAR(orderdate) AS orderyear
        FROM dbo.Orders) AS D
    PIVOT(COUNT(orderyear)
          FOR orderyear IN([2007], [2008], [2009])) AS P;

SELECT * FROM dbo.EmpYearOrders;

-- Вывод:
empid       cnt2007     cnt2008     cnt2009
----------- ----------- ----------- -----------
1           1           1           1
2           1           2           1
3           2           0           2

-- Напишите запрос к таблице EmpYearOrders, который отменяет разворачивание
-- данных и возвращает строку с количеством заказов для каждого сотрудника
-- и за каждый год. Исключите из результата строки, в которых количество
-- заказов равно 0 (в данном случае это актуально для сотрудника под номером
-- 3, который не обработал ни одного заказа в 2008 году).

-- Ожидаемый результат:
empid       orderyear   numorders
----------- ----------- -----------
1           2007        1
1           2008        1
1           2009        1
2           2007        1
2           2008        2
2           2009        1
3           2007        2
3           2009        2

-- Решение

-- С помощью стандартных средств
SELECT *
FROM (SELECT empid, orderyear,
        CASE orderyear
          WHEN 2007 THEN cnt2007
          WHEN 2008 THEN cnt2008
          WHEN 2009 THEN cnt2009
        END AS numorders
      FROM dbo.EmpYearOrders
        CROSS JOIN (VALUES(2007),(2008),(2009)) AS Years (orderyear)) AS D
WHERE numorders <> 0;

SELECT *
FROM (SELECT empid, orderyear,
        CASE orderyear
          WHEN 2007 THEN cnt2007
          WHEN 2008 THEN cnt2008
          WHEN 2009 THEN cnt2009
        END AS numorders
      FROM dbo.EmpYearOrders
        CROSS JOIN (SELECT 2007 AS orderyear
                    UNION ALL SELECT 2008
                    UNION ALL SELECT 2009) AS Years) AS D
WHERE numorders <> 0;

-- С помощью встроенного оператора UNPIVOT 
SELECT empid, CAST(RIGHT(orderyear, 4) AS INT) AS orderyear, numorders
FROM dbo.EmpYearOrders
  UNPIVOT(numorders FOR orderyear IN(cnt2007, cnt2008, cnt2009)) AS U
WHERE numorders <> 0;

-- 5
-- Напишите запрос к таблице dbo.Orders, который возвращает общее количество
-- заказанного товара для каждого из следующих наборов:
-- (employee, customer, and order year)
-- (employee and order year)
-- (customer and order year)
-- В результат должен попасть столбец, однозначно идентифицирующий
-- группирующий набор, с которым связана текущая строка.

-- Ожидаемый результат:
groupingset empid       custid orderyear   sumqty
----------- ----------- ------ ----------- -----------
0           2           A      2007        12
0           3           A      2007        10
4           NULL        A      2007        22
0           2           A      2008        40
4           NULL        A      2008        40
0           3           A      2009        10
4           NULL        A      2009        10
0           1           B      2007        20
4           NULL        B      2007        20
0           2           B      2008        12
4           NULL        B      2008        12
0           2           B      2009        15
4           NULL        B      2009        15
0           3           C      2007        22
4           NULL        C      2007        22
0           1           C      2008        14
4           NULL        C      2008        14
0           1           C      2009        20
4           NULL        C      2009        20
0           3           D      2009        30
4           NULL        D      2009        30
2           1           NULL   2007        20
2           2           NULL   2007        12
2           3           NULL   2007        32
2           1           NULL   2008        14
2           2           NULL   2008        52
2           1           NULL   2009        20
2           2           NULL   2009        15
2           3           NULL   2009        40

(29 row(s) affected)

-- Решение
SELECT
  GROUPING_ID(empid, custid, YEAR(Orderdate)) AS groupingset,
  empid, custid, YEAR(Orderdate) AS orderyear, SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY
  GROUPING SETS
  (
    (empid, custid, YEAR(orderdate)),
    (empid, YEAR(orderdate)),
    (custid, YEAR(orderdate))
  );