---------------------------------------------------------------------
-- Microsoft SQL Server 2012: Основы T-SQL
-- Глава 08 - Изменение данных
-- Упражнения
-- © Ицик Бен-Ган
---------------------------------------------------------------------

-- 1
-- Запустите следующий код, чтобы создать в базе данных
-- TSQL2012 таблицу dbo.Customers.
USE TSQL2012;

IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;

CREATE TABLE dbo.Customers
(
  custid      INT          NOT NULL PRIMARY KEY,
  companyname NVARCHAR(40) NOT NULL,
  country     NVARCHAR(15) NOT NULL,
  region      NVARCHAR(15) NULL,
  city        NVARCHAR(15) NOT NULL  
);
GO

-- 1-1
-- Добавьте в таблицу dbo.Customers строку со следующими значениями:
-- custid: 100
-- companyname: Рога и копыта
-- country: США
-- region: WA
-- city: Редмонд

-- 1-2
-- Выберите из таблицы Sales.Customers записи о всех клиентах,
-- которые размещали заказы, и скопируйте их в таблицу dbo.Customers.

-- 1-3
-- С помощью команды SELECT INTO создайте таблицу dbo.Orders и заполните ее
-- заказами из таблицы Sales.Orders, которые были размещены в 2006-2008 годах. 

-- 2
-- Удалите из таблицы dbo.Orders заказы, размещенные до августа 2006 года.
-- Используйте инструкцию OUTPUT, чтобы вернуть атрибуты orderid и orderdate,
-- принадлежащие удаленным строкам.

-- Ожидаемый результат:
orderid     orderdate
----------- -----------------------
10248       2006-07-04 00:00:00.000
10249       2006-07-05 00:00:00.000
10250       2006-07-08 00:00:00.000
10251       2006-07-08 00:00:00.000
10252       2006-07-09 00:00:00.000
10253       2006-07-10 00:00:00.000
10254       2006-07-11 00:00:00.000
10255       2006-07-12 00:00:00.000
10256       2006-07-15 00:00:00.000
10257       2006-07-16 00:00:00.000
10258       2006-07-17 00:00:00.000
10259       2006-07-18 00:00:00.000
10260       2006-07-19 00:00:00.000
10261       2006-07-19 00:00:00.000
10262       2006-07-22 00:00:00.000
10263       2006-07-23 00:00:00.000
10264       2006-07-24 00:00:00.000
10265       2006-07-25 00:00:00.000
10266       2006-07-26 00:00:00.000
10267       2006-07-29 00:00:00.000
10268       2006-07-30 00:00:00.000
10269       2006-07-31 00:00:00.000

(22 row(s) affected)

-- 3
-- Удалите из таблицы dbo.Orders заказы, размещенные бразильскими клиентами.

-- 4
-- Выполните запрос к таблице dbo.Customers, представленный ниже. Обратите
-- внимание, что некоторые строки содержат NULL в столбце region.
SELECT * FROM dbo.Customers;

-- Вывод:
custid      companyname   country         region          city
----------- ------------- --------------- --------------- ------------
1           Клиент NRZBB  Германия        NULL            Берлин
2           Клиент MLTDN  Мексика         NULL            Мехико
3           Клиент KBUDE  Мексика         NULL            Мехико
4           Клиент HFBZG  Великобритания  NULL            Лондон
5           Клиент HGVLZ  Швеция          NULL            Лулео
6           Клиент XHXJV  Германия        NULL            Мангейм
7           Клиент QXVLA  Франция         NULL            Страсбург
8           Клиент QUHWH  Испания         NULL            Мадрид
9           Клиент RTXGC  Франция         NULL            Марсель
10          Клиент EEALV  Канада          BC              Тсаввассен
...

(90 row(s) affected)

-- Обновите таблицу dbo.Customers, заменяя отметки NULL значениями
-- '<None>'. Используйте инструкцию OUTPUT, чтобы вывести содержимое
-- столбцов custid, oldregion и newregion.

-- Ожидаемый результат:
custid      oldregion       newregion
----------- --------------- ---------------
1           NULL            <None>
2           NULL            <None>
3           NULL            <None>
4           NULL            <None>
5           NULL            <None>
6           NULL            <None>
7           NULL            <None>
8           NULL            <None>
9           NULL            <None>
11          NULL            <None>
12          NULL            <None>
13          NULL            <None>
14          NULL            <None>
16          NULL            <None>
17          NULL            <None>
18          NULL            <None>
19          NULL            <None>
20          NULL            <None>
23          NULL            <None>
24          NULL            <None>
25          NULL            <None>
26          NULL            <None>
27          NULL            <None>
28          NULL            <None>
29          NULL            <None>
30          NULL            <None>
39          NULL            <None>
40          NULL            <None>
41          NULL            <None>
44          NULL            <None>
49          NULL            <None>
50          NULL            <None>
52          NULL            <None>
53          NULL            <None>
54          NULL            <None>
56          NULL            <None>
58          NULL            <None>
59          NULL            <None>
60          NULL            <None>
63          NULL            <None>
64          NULL            <None>
66          NULL            <None>
68          NULL            <None>
69          NULL            <None>
70          NULL            <None>
72          NULL            <None>
73          NULL            <None>
74          NULL            <None>
76          NULL            <None>
79          NULL            <None>
80          NULL            <None>
83          NULL            <None>
84          NULL            <None>
85          NULL            <None>
86          NULL            <None>
87          NULL            <None>
90          NULL            <None>
91          NULL            <None>

(58 row(s) affected)

-- 5
-- Обновите в таблице dbo.Orders все заказы, которые были размещены
-- клиентами из Великобритании; присвойте их атрибутам shipcountry, shipregion
-- и shipcity значения country, region и city, взятые из таблицы dbo.Customers.

-- очистка
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers ;
