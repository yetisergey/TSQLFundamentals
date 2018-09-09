--1
SELECT
  o.orderid
 ,o.orderdate
 ,o.custid
 ,o.empid
FROM Sales.Orders o
WHERE o.orderdate = (SELECT
    MAX(o1.orderdate)
  FROM Sales.Orders o1)

--2
SELECT
  custid
 ,orderid
 ,orderdate
 ,empid
FROM Sales.Orders
WHERE custid IN (SELECT TOP (1)
    O.custid
  FROM Sales.Orders AS O
  GROUP BY O.custid
  ORDER BY COUNT(*) DESC);

--3
SELECT
  e.empid
 ,e.firstname
 ,e.lastname
FROM HR.Employees e
WHERE e.empid NOT IN (SELECT
    o1.empid
  FROM Sales.Orders o1
  WHERE o1.orderdate > '20080501')

--4
SELECT DISTINCT
  c.country
FROM Sales.Customers c
WHERE c.country NOT IN (SELECT DISTINCT
    e.country
  FROM HR.Employees e)

--5
SELECT
  o.custid
 ,o.orderid
 ,o.orderdate
 ,o.empid
FROM Sales.Orders o
WHERE o.orderdate = (SELECT
    MAX(o1.orderdate)
  FROM Sales.Orders o1
  WHERE o1.custid = o.custid)

--6
SELECT
  c.custid
 ,c.companyname
FROM Sales.Customers c
WHERE EXISTS (SELECT
    *
  FROM Sales.Orders o
  WHERE o.custid = c.custid
  AND YEAR(o.orderdate) = 2007)
AND NOT EXISTS (SELECT
    *
  FROM Sales.Orders o
  WHERE o.custid = c.custid
  AND YEAR(o.orderdate) = 2008)

--7
SELECT
  c.custid
 ,c.companyname
FROM Sales.Customers c
WHERE EXISTS (SELECT
    *
  FROM Sales.Orders o
  JOIN Sales.OrderDetails od
    ON o.orderid = od.orderid
  WHERE c.custid = o.custid
  AND od.productid = 12)

--8
SELECT
  custid
 ,ordermonth
 ,qty
 ,(SELECT
      SUM(O2.qty)
    FROM Sales.CustOrders AS O2
    WHERE O2.custid = O1.custid
    AND O2.ordermonth <= O1.ordermonth)
  AS runqty
FROM Sales.CustOrders AS O1