--1-1
SELECT o.empid, MAX(o.orderdate) as orderdate
FROM Sales.Orders as o
group by empid

--1-2
SELECT o2.empid, o2.orderdate, o2.orderid, o2.custid FROM 
(SELECT empid, MAX(orderdate) as orderdate
FROM Sales.Orders
group by empid)	as o
join Sales.Orders o2
on o.empid = o2.empid
and o.orderdate = o2.orderdate

--2-1
SELECT
 o.orderid,
 o.orderdate,
 o.custid,
 o.empid,
 ROW_NUMBER() over ( order by o.orderid, o.orderdate) rownum
FROM Sales.Orders AS o

--2-2
SELECT
*
FROM
(SELECT
	 o.orderid,
	 o.orderdate,
	 o.custid,
	 o.empid,
	 ROW_NUMBER() over ( order by o.orderid, o.orderdate) rownum
	FROM Sales.Orders AS o) AS T
WHERE T.rownum >= 11 AND T.rownum <= 20

--3
with foo(empid, mgrid, firstname, lastname) as (
	select empid, mgrid, firstname, lastname
	from HR.Employees
	where empid = 9
union all
	select  e.empid, e.mgrid, e.firstname, e.lastname
	from foo f
	join HR.Employees e
	on f.mgrid = e.empid
)
select * from foo

--4-1
SELECT o.empid, o.orderyear, SUM(od.qty) FROM Sales.OrderDetails od
JOIN (SELECT empid, YEAR(orderdate) as orderyear, orderid  FROM Sales.Orders) o
ON od.orderid = o.orderid
GROUP BY o.empid, o.orderyear
order by empid, orderyear

--4-2
WITH Orders AS
(
	SELECT
	 o.empid,
	 o.orderyear,
	 SUM(od.qty) qty
	FROM Sales.OrderDetails od
		JOIN (SELECT empid, YEAR(orderdate) as orderyear, orderid FROM Sales.Orders) o
		ON od.orderid = o.orderid
	GROUP BY o.empid, o.orderyear
)
SELECT empid, orderyear, qty,
	(SELECT SUM(qty)
		FROM Orders AS V2
		WHERE V2.empid = V1.empid
		AND V2.orderyear <= V1.orderyear) AS runqty
FROM Orders AS V1
ORDER BY empid, orderyear;

--5-1
IF OBJECT_ID('Production.TopProducts') IS NOT NULL
	DROP FUNCTION Production.TopProducts;

CREATE FUNCTION Production.TopProducts (@supid AS INT, @n AS INT) RETURNS Table AS
RETURN
	SELECT TOP(@n) productid, productname, unitprice
	FROM Production.Products p
	WHERE @supid = p.supplierid 
	ORDER BY p.unitprice DESC
GO

SELECT * FROM Production.TopProducts(5, 2);

--5-2
WITH Suppliers AS (
	SELECT s.supplierid, s.companyname
	FROM Production.Suppliers s)
SELECT * FROM Suppliers s
CROSS APPLY
Production.TopProducts(s.supplierid, 2);