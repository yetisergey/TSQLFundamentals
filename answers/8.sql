USE TSQL2012;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
CREATE TABLE dbo.Customers
(
	custid INT NOT NULL PRIMARY KEY,
	companyname NVARCHAR(40) NOT NULL,
	country NVARCHAR(15) NOT NULL,
	region NVARCHAR(15) NULL,
	city NVARCHAR(15) NOT NULL
);

--1-1
insert into dbo.Customers 
(
	custid,
	companyname, 
	country, 
	region,
	city
)
values
(
	100,
	'Рога и копыта',
	'США',
	'WA',
	'Редмонд'
)


--1-2
insert into dbo.Customers
(custid,
	companyname, 
	country, 
	region,
	city)
select custid,
	companyname, 
	country, 
	region,
	city from Sales.Customers

select * from dbo.Customers

--1-3
select * into dbo.Orders2
	from Sales.Orders
select * from dbo.Orders2

--2
delete from dbo.Orders2
output deleted.orderid, deleted.orderdate
where YEAR(dbo.Orders2.orderdate) >= 2006 and year(dbo.Orders2.orderdate) <= 2008

--3
delete from dbo.Orders2
where shipcountry like 'Бразилия';

--4
with cte as (
select custid, region from dbo.Customers
) 
update cte set cte.region = '<None>'
output deleted.custid, deleted.region, inserted.region

--5
merge into dbo.Orders2 AS o2
using dbo.Customers as c
	on c.custid = o2.custid and o2.shipcountry like 'Великобритания'
when matched then
	update set shipcountry = c.country, o2.shipregion = c.region, o2.shipcity = c.city;

select * from dbo.orders2

IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Orders2', 'U') IS NOT NULL DROP TABLE dbo.Orders2;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;