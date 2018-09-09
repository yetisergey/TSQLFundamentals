--1
SELECT
  orderid
 ,orderdate
 ,custid
 ,empid
FROM Sales.Orders
WHERE orderdate >= '20070601'
AND orderdate <= '20070630'

--2
SELECT
  orderid
 ,orderdate
 ,custid
 ,empid
FROM Sales.Orders
WHERE orderdate = EOMONTH(orderdate)

--3
SELECT
  empid
 ,firstname
 ,lastname
FROM HR.Employees
WHERE LEN(lastname) - LEN(REPLACE(lastname, 'о', '')) > 1

--4
SELECT
  orderid
 ,SUM(unitprice * qty) AS totalvalue
FROM Sales.OrderDetails
GROUP BY orderid
HAVING SUM(unitprice * qty) > 10000

--5
SELECT TOP 3
  o.shipcountry
 ,AVG(o.freight) AS avgfreight
 ,YEAR(o.orderdate)
FROM Sales.Orders o
GROUP BY o.shipcountry
        ,YEAR(o.orderdate)
HAVING YEAR(o.orderdate) = 2007
ORDER BY avgfreight DESC

--6

SELECT
  custid
 ,orderdate
 ,orderid
 ,RowNum = ROW_NUMBER() OVER (ORDER BY custid)
FROM Sales.Orders

--7
SELECT
  empid
 ,firstname
 ,lastname
 ,titleofcourtesy
 ,CASE
    WHEN titleofcourtesy = 'мисс' OR
      titleofcourtesy = 'миссис' THEN 'женщина'
    WHEN titleofcourtesy = 'мистер' THEN 'мужчина'
    ELSE 'неизвестно'
  END
FROM HR.Employees

--8
SELECT
  custid
 ,region
FROM Sales.Customers
ORDER BY CASE
  WHEN region IS NULL THEN 1
  ELSE 0
END, region;