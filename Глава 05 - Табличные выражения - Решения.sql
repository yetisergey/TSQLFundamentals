---------------------------------------------------------------------
-- Microsoft SQL Server 2012: Основы T-SQL
-- Глава 05 - Табличные выражения
-- Решения
-- © Ицик Бен-Ган
---------------------------------------------------------------------

-- 1-1
-- Напишите запрос, который возвращает максимальное значение
-- столбца orderdate для каждого сотрудника.
-- Используемые таблицы: Sales.Orders 

-- Ожидаемый результат
empid       maxorderdate
----------- -----------------------
3           2008-04-30 00:00:00.000
6           2008-04-23 00:00:00.000
9           2008-04-29 00:00:00.000
7           2008-05-06 00:00:00.000
1           2008-05-06 00:00:00.000
4           2008-05-06 00:00:00.000
2           2008-05-05 00:00:00.000
5           2008-04-22 00:00:00.000
8           2008-05-06 00:00:00.000

(9 row(s) affected)

-- Решение
USE TSQL2012;

SELECT empid, MAX(orderdate) AS maxorderdate
FROM Sales.Orders
GROUP BY empid;

-- 1-2
-- Выразите запрос, приведенный в предыдущем упражнении, в виде производной
-- таблицы. Выполните соединение полученного результата с таблицей Orders,
-- чтобы вернуть для каждого сотрудника заказ с последней датой.
-- Используемые таблицы: Sales.Orders

-- Ожидаемый результат:
empid       orderdate               orderid     custid
----------- ----------------------- ----------- -----------
9           2008-04-29 00:00:00.000 11058       6
8           2008-05-06 00:00:00.000 11075       68
7           2008-05-06 00:00:00.000 11074       73
6           2008-04-23 00:00:00.000 11045       10
5           2008-04-22 00:00:00.000 11043       74
4           2008-05-06 00:00:00.000 11076       9
3           2008-04-30 00:00:00.000 11063       37
2           2008-05-05 00:00:00.000 11073       58
2           2008-05-05 00:00:00.000 11070       44
1           2008-05-06 00:00:00.000 11077       65

(10 row(s) affected)

-- Решение
SELECT O.empid, O.orderdate, O.orderid, O.custid
FROM Sales.Orders AS O
  JOIN (SELECT empid, MAX(orderdate) AS maxorderdate
        FROM Sales.Orders
        GROUP BY empid) AS D
    ON O.empid = D.empid
    AND O.orderdate = D.maxorderdate;

-- 2-1
-- Напишите запрос, который вычисляет номер строки для каждого заказа,
-- выполняя предварительную сортировку по столбцам orderdate и orderid.
-- Используемые таблицы: Sales.Orders

-- Ожидаемый результат:
orderid     orderdate               custid      empid       rownum
----------- ----------------------- ----------- ----------- -------
10248       2006-07-04 00:00:00.000 85          5           1
10249       2006-07-05 00:00:00.000 79          6           2
10250       2006-07-08 00:00:00.000 34          4           3
10251       2006-07-08 00:00:00.000 84          3           4
10252       2006-07-09 00:00:00.000 76          4           5
10253       2006-07-10 00:00:00.000 34          3           6
10254       2006-07-11 00:00:00.000 14          5           7
10255       2006-07-12 00:00:00.000 68          9           8
10256       2006-07-15 00:00:00.000 88          3           9
10257       2006-07-16 00:00:00.000 35          4           10
...

(830 row(s) affected)

-- Решение
SELECT orderid, orderdate, custid, empid,
  ROW_NUMBER() OVER(ORDER BY orderdate, orderid) AS rownum
FROM Sales.Orders;

-- 2-2
-- Напишите запрос, который возвращает строки с 11 по 20 с учетом сортировки
-- по столбцам orderdate и orderid. Используйте обобщенное табличное выражение,
-- чтобы инкапсулировать код из предыдущего упражнения.
-- Используемые таблицы: Sales.Orders

-- Ожидаемый результат:
orderid     orderdate               custid      empid       rownum
----------- ----------------------- ----------- ----------- -------
10258       2006-07-17 00:00:00.000 20          1           11
10259       2006-07-18 00:00:00.000 13          4           12
10260       2006-07-19 00:00:00.000 56          4           13
10261       2006-07-19 00:00:00.000 61          4           14
10262       2006-07-22 00:00:00.000 65          8           15
10263       2006-07-23 00:00:00.000 20          9           16
10264       2006-07-24 00:00:00.000 24          6           17
10265       2006-07-25 00:00:00.000 7           2           18
10266       2006-07-26 00:00:00.000 87          3           19
10267       2006-07-29 00:00:00.000 25          4           20

(10 row(s) affected)

-- Решение
WITH OrdersRN AS
(
  SELECT orderid, orderdate, custid, empid,
    ROW_NUMBER() OVER(ORDER BY orderdate, orderid) AS rownum
  FROM Sales.Orders
)
SELECT * FROM OrdersRN WHERE rownum BETWEEN 11 AND 20;

-- 3 (углубленное, по желанию)
-- Напишите запрос, который возвращает управленческую цепочку, связанную с
-- Зоей Долгопятовой (сотрудник под номером 9). Используйте рекурсивное ОТВ.
-- Используемые таблицы: HR.Employees

-- Ожидаемый результат:
empid       mgrid       firstname  lastname
----------- ----------- ---------- ---------------
9           5           Зоя        Долгопятова
5           2           Свен       Бак
2           1           Дон        Функ
1           NULL        Сара       Дэвис

(4 row(s) affected)

-- Решение
WITH EmpsCTE AS
(
  SELECT empid, mgrid, firstname, lastname
  FROM HR.Employees
  WHERE empid = 9
  
  UNION ALL
  
  SELECT P.empid, P.mgrid, P.firstname, P.lastname
  FROM EmpsCTE AS C
    JOIN HR.Employees AS P
      ON C.mgrid = P.empid
)
SELECT empid, mgrid, firstname, lastname
FROM EmpsCTE;

-- 4-1
-- Напишите представление, которое возвращает общий объем заказанной
-- продукции для каждого сотрудника, разбитый по годам.
-- Используемые таблицы: Sales.Orders и Sales.OrderDetails

-- Ожидаемый результат при выполнении запроса
-- SELECT * FROM  Sales.VEmpOrders ORDER BY empid, orderyear
empid       orderyear   qty
----------- ----------- -----------
1           2006        1620
1           2007        3877
1           2008        2315
2           2006        1085
2           2007        2604
2           2008        2366
3           2006        940
3           2007        4436
3           2008        2476
4           2006        2212
4           2007        5273
4           2008        2313
5           2006        778
5           2007        1471
5           2008        787
6           2006        963
6           2007        1738
6           2008        826
7           2006        485
7           2007        2292
7           2008        1877
8           2006        923
8           2007        2843
8           2008        2147
9           2006        575
9           2007        955
9           2008        1140

(27 row(s) affected)

-- Решение
USE TSQL2012;
IF OBJECT_ID('Sales.VEmpOrders') IS NOT NULL
  DROP VIEW Sales.VEmpOrders;
GO
CREATE VIEW  Sales.VEmpOrders
AS

SELECT
  empid,
  YEAR(orderdate) AS orderyear,
  SUM(qty) AS qty
FROM Sales.Orders AS O
  JOIN Sales.OrderDetails AS OD
    ON O.orderid = OD.orderid
GROUP BY
  empid,
  YEAR(orderdate);
GO

-- 4-2 (углубленное, по желанию)
-- Напишите запрос к представлению Sales.VEmpOrders, который возвращает
-- общее текущее количество заказанных товаров для каждого сотрудника,
-- с разбиением по годам.
-- Используемые таблицы: представление Sales.VEmpOrders

-- Ожидаемый результат:
empid       orderyear   qty         runqty
----------- ----------- ----------- -----------
1           2006        1620        1620
1           2007        3877        5497
1           2008        2315        7812
2           2006        1085        1085
2           2007        2604        3689
2           2008        2366        6055
3           2006        940         940
3           2007        4436        5376
3           2008        2476        7852
4           2006        2212        2212
4           2007        5273        7485
4           2008        2313        9798
5           2006        778         778
5           2007        1471        2249
5           2008        787         3036
6           2006        963         963
6           2007        1738        2701
6           2008        826         3527
7           2006        485         485
7           2007        2292        2777
7           2008        1877        4654
8           2006        923         923
8           2007        2843        3766
8           2008        2147        5913
9           2006        575         575
9           2007        955         1530
9           2008        1140        2670

(27 row(s) affected)

-- Решение
SELECT empid, orderyear, qty,
  (SELECT SUM(qty)
   FROM  Sales.VEmpOrders AS V2
   WHERE V2.empid = V1.empid
     AND V2.orderyear <= V1.orderyear) AS runqty
FROM  Sales.VEmpOrders AS V1
ORDER BY empid, orderyear;

-- 5-1
-- Создайте встроенную функцию, которая в качестве аргументов принимает
-- идентификатор поставщика (@supid AS INT) и произвольное число товаров
-- (@n AS INT). Функция должна возвращать @n самых дорогих товаров,
-- предоставленных заданным поставщиком.
-- Используемые таблицы: Production.Products

-- Ожидаемый результат при выполнении следующего запроса:
-- SELECT * FROM Production.TopProducts(5, 2)

productid   productname                    unitprice
----------- ------------------------------ -------------
12          Продукт OSFNS                  38,00
11          Продукт QMVUN                  21,00

(2 row(s) affected)

-- Решение
USE TSQL2012;
IF OBJECT_ID('Production.TopProducts') IS NOT NULL
  DROP FUNCTION Production.TopProducts;
GO
CREATE FUNCTION Production.TopProducts
  (@supid AS INT, @n AS INT)
  RETURNS TABLE
AS
RETURN
  SELECT TOP (@n) productid, productname, unitprice
  FROM Production.Products
  WHERE supplierid = @supid
  ORDER BY unitprice DESC;

  /*
  -- in SQL Server 2012
  SELECT productid, productname, unitprice
  FROM Production.Products
  WHERE supplierid = @supid
  ORDER BY unitprice DESC
  OFFSET 0 ROWS FETCH FIRST @n ROWS ONLY;
  */
GO

-- 5-2
-- С помощью оператора CROSS APPLY и функции, созданной вами в упражнении 5-1,
-- получите для каждого поставщика список из двух самых дорогих товаров.

-- Ожидаемый результат 
supplierid companyname       productid productname      unitprice
---------- ----------------  --------- --------------   ----------
8          Поставщик BWGYE   20        Продукт QHFFP    81,00
8          Поставщик BWGYE   68        Продукт TBTBL    12,50
20         Поставщик CIYNM   43        Продукт ZZZHR    46,00
20         Поставщик CIYNM   44        Продукт VJIEO    19,45
23         Поставщик ELCRN   49        Продукт FPYPN    20,00
23         Поставщик ELCRN   76        Продукт JYGFE    18,00
5          Поставщик EQPNC   12        Продукт OSFNS    38,00
5          Поставщик EQPNC   11        Продукт QMVUN    21,00
...

(55 row(s) affected)

-- Решение
SELECT S.supplierid, S.companyname, P.productid, P.productname, P.unitprice
FROM Production.Suppliers AS S
  CROSS APPLY Production.TopProducts(S.supplierid, 2) AS P;
