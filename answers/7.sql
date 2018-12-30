--1
SELECT
  o.orderid
 ,o.custid
 ,o.qty
 ,RANK() OVER (PARTITION BY o.custid ORDER BY o.qty) AS rnk
 ,DENSE_RANK() OVER (PARTITION BY o.custid ORDER BY o.qty) AS drnk
FROM Orders o

--2
SELECT
  o.orderid
 ,o.custid
 ,o.qty
 ,o.qty - LAG(o.qty) OVER (PARTITION BY o.custid ORDER BY o.orderdate, o.custid) AS diffprev
 ,o.qty - LEAD(o.qty) OVER (PARTITION BY o.custid ORDER BY o.orderdate, o.custid) AS diffnext
FROM Orders o

--3
SELECT
  empid
 ,[2007]
 ,[2008]
 ,[2009]
FROM (SELECT
    empid
   ,YEAR(orderdate) AS orderyear
  FROM Orders) AS o
PIVOT (COUNT(orderyear) FOR orderyear IN ([2007], [2008], [2009])) AS p

--4
SELECT empid, qty
  FROM (SELECT * dbo.EmpYearOrders) AS e
  UNPIVOT(qty FOR COUNT(empid) IN (cnt2007, cnt2008, cnt2009)) AS U;

--5
SELECT
  GROUPING_ID(empid, custid, YEAR(orderdate)) AS groupingset
 ,empid
 ,custid
 ,YEAR(orderdate) orderyear
 ,SUM(qty) AS sumqty
FROM dbo.Orders
GROUP BY GROUPING SETS
((empid, custid, YEAR(orderdate)),
(empid, YEAR(orderdate)),
(custid, YEAR(orderdate)))