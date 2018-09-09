--1-1
SELECT
  e.empid
 ,e.firstname
 ,e.lastname
 ,n.n
FROM HR.Employees AS e
    ,dbo.Nums AS n
WHERE n.n <= 5

--1-2
SELECT
  e.empid
 ,dates.orderdate
FROM HR.Employees AS e
    ,(SELECT
         DATEADD(DAY, n - 1, '20090612') AS orderdate
       FROM dbo.Nums
       WHERE n <= DATEDIFF(DAY, '20090612', '20090617')) AS dates
ORDER BY e.empid

--2
SELECT
  C.custid
 ,COUNT(DISTINCT o.orderid)
 ,SUM(OD.qty) AS totalqty
FROM Sales.Customers AS C
LEFT JOIN Sales.Orders AS O
  ON C.custid = O.custid
LEFT JOIN Sales.OrderDetails AS OD
  ON O.orderid = OD.orderid
WHERE c.country = 'США'
AND o.orderid IS NOT NULL
GROUP BY c.custid

--3
SELECT
  c.custid
 ,c.companyname
 ,o.orderid
 ,o.orderdate
FROM Sales.Customers c
LEFT JOIN Sales.Orders o
  ON o.custid = c.custid

--4
SELECT
  c.custid
 ,c.companyname
 ,o.orderid
 ,o.orderdate
FROM Sales.Customers c
LEFT JOIN Sales.Orders o
  ON o.custid = c.custid
WHERE o.orderid IS NULL

--5
SELECT
  c.custid
 ,c.companyname
 ,o.orderid
 ,o.orderdate
FROM Sales.Customers c
LEFT JOIN Sales.Orders o
  ON o.custid = c.custid
WHERE o.orderdate = '20070212'

--6
SELECT
  c.custid
 ,c.companyname
 ,o.orderid
 ,o.orderdate
FROM Sales.Customers c
LEFT JOIN Sales.Orders AS o
  ON o.custid = c.custid
    AND o.orderdate = '20070212';

--7
SELECT
  c.custid
 ,c.companyname
 ,CASE o.orderdate
    WHEN '20070212' THEN 'Да'
    ELSE 'Нет'
  END
  AS HasOrderOn20070212
FROM Sales.Customers c
LEFT JOIN Sales.Orders AS o
  ON o.custid = c.custid
    AND o.orderdate = '20070212';
