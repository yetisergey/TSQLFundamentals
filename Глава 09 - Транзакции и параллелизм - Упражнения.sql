---------------------------------------------------------------------
-- Microsoft SQL Server 2012: Основы T-SQL
-- Глава 09 - Транзакции и параллелизм
-- Упражнения
-- © Ицик Бен-Ган
---------------------------------------------------------------------

-- Чтобы все примеры работали в контексте базы данных TSQL2012,
-- выполните следующий код:

USE TSQL2012;

---------------------------------------------------------------------
-- 1 Блокирование
---------------------------------------------------------------------

-- 1-1
-- Откройте три соединения
-- (назовем их Соединение 1, Соединение 2 и Соединение 3).
-- Запустите в первом из них следующий код, чтобы обновить строки
-- в таблице Sales.OrderDetails:

BEGIN TRAN;

  UPDATE Sales.OrderDetails
    SET discount = 0.05
  WHERE orderid = 10249;

-- 1-2
-- Обратитесь  к таблице Sales.OrderDetails в контексте Соединения 2;
-- вы будете заблокированы:

SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails -- WITH (READCOMMITTEDLOCK)
WHERE orderid = 10249;

-- 1-3
-- Запустите в рамках Соединения 3 код, представленный ниже;
-- отследите блокировки и идентификаторы процессов, вовлеченных
-- в цепочку блокирования:

SELECT -- используйте *, чтобы вывести все доступные атрибуты
  request_session_id            AS spid,
  resource_type                 AS restype,
  resource_database_id          AS dbid,
  resource_description          AS res,
  resource_associated_entity_id AS resid,
  request_mode                  AS mode,
  request_status                AS status
FROM sys.dm_tran_locks;

-- 1-4
-- Поменяйте идентификаторы процессов 52 и 53 на те, которые вы обнаружили
-- в цепочке блокирования в предыдущем упражнении. Запустите следующий код,
-- чтобы получить информацию о соединении, сессии и блокировках, связанных с
-- процессом, который участвует в цепочке блокирования.

-- Информация о соединении
SELECT -- используйте *, чтобы вывести все доступные атрибуты
  session_id AS spid,
  connect_time,
  last_read,
  last_write,
  most_recent_sql_handle
FROM sys.dm_exec_connections
WHERE session_id IN(52, 53);

-- Информация о сессии
SELECT -- используйте *, чтобы вывести все доступные атрибуты
  session_id AS spid,
  login_time,
  host_name,
  program_name,
  login_name,
  nt_user_name,
  last_request_start_time,
  last_request_end_time
FROM sys.dm_exec_sessions
WHERE session_id IN(52, 53);

-- Информация о блокировках
SELECT -- используйте *, чтобы вывести все доступные атрибуты
  session_id AS spid,
  blocking_session_id,
  command,
  sql_handle,
  database_id,
  wait_type,
  wait_time,
  wait_resource
FROM sys.dm_exec_requests
WHERE blocking_session_id > 0;

-- 1-5
-- Запустите следующий код, чтобы получить исходный текст соединений
-- (на языке SQL), вовлеченных в цепочку блокирования:

-- код на языке SQL
SELECT session_id, text 
FROM sys.dm_exec_connections
  CROSS APPLY sys.dm_exec_sql_text(most_recent_sql_handle) AS ST 
WHERE session_id IN(52, 53);

-- 1-6
-- Запустите внутри Соединения 1 следующий код, чтобы откатить транзакцию:
ROLLBACK TRAN;

-- Тем временем команда SELECT, запущенная в рамках Соединения 2,
-- вернула из таблицы OrderDetails две строки, содержимое которых не менялось.
-- Закройте все соединения. 

---------------------------------------------------------------------
-- 2 Уровни изоляции
---------------------------------------------------------------------

---------------------------------------------------------------------
-- 2-1 В этом упражнении вы поработаете с уровнем изоляции READ UNCOMMITTED.
---------------------------------------------------------------------

-- 2-1а
-- Откройте два новых соединения (назовем их Соединение 1 и Соединение 2).

-- 2-1б
-- Запустите в контексте первого соединения код, представленный ниже,
-- чтобы обновить и затем извлечь содержимое таблицы Sales.OrderDetails:

BEGIN TRAN;

  UPDATE Sales.OrderDetails
    SET discount += 0.05
  WHERE orderid = 10249;

  SELECT orderid, productid, unitprice, qty, discount
  FROM Sales.OrderDetails
  WHERE orderid = 10249;

-- 2-1в
-- Перейдите к Соединению 2, установите уровень изоляции READ UNCOMMITTED
-- и выполните запрос к таблице Sales.OrderDetails:

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;

-- Как видите, что вы получили измененную, неподтвержденную версию строк.

-- 2-1г
-- Запустите в рамках Соединения 1 следующий код, чтобы откатить транзакцию:

ROLLBACK TRAN;

---------------------------------------------------------------------
-- 2-2 Уровень изоляции READ COMMITTED
---------------------------------------------------------------------

-- 2-2а
-- Запустите в рамках Соединения 1 код, представленный ниже, чтобы
-- обновить и запросить содержимое таблицы Sales.OrderDetails:

BEGIN TRAN;

  UPDATE Sales.OrderDetails
    SET discount += 0.05
  WHERE orderid = 10249;

  SELECT orderid, productid, unitprice, qty, discount
  FROM Sales.OrderDetails
  WHERE orderid = 10249;

-- 2-2б
-- Запустите в контексте Соединения 2 следующий код,
-- который устанавливает уровень изоляции READ COMMITTED и
-- выполняет запрос к таблице Sales.OrderDetails:

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails -- WITH (READCOMMITTEDLOCK)
WHERE orderid = 10249;

-- Обратите внимание, что ваша транзакция заблокирована.

-- 2-2в
-- Подтвердите транзакцию внутри Соединения 1:

COMMIT TRAN;

-- 2-2г
-- Перейдите к Соединению 2. Как видите, вы получили измененную,
-- подтвержденную версию строк.

-- 2-2д
-- Верните таблицу в исходное состояние с помощью следующего кода.
UPDATE Sales.OrderDetails
  SET discount = 0.00
WHERE orderid = 10249;

---------------------------------------------------------------------
-- 2-3 Уровень изоляции REPEATABLE READ
---------------------------------------------------------------------

-- 2-3а
-- Запустите в контексте Соединения 1 следующий код,
-- который устанавливает уровень изоляции REPEATABLE READ
-- и выполняет запрос к таблице Sales.OrderDetails:

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

BEGIN TRAN;

  SELECT orderid, productid, unitprice, qty, discount
  FROM Sales.OrderDetails
  WHERE orderid = 10249;

-- Вы получите две строки со значением 0,00 в столбце discount.

-- 2-3б
-- Запустите в рамках Соединения 2 код, представленный ниже.
-- Обратите внимание, что транзакция заблокирована:

UPDATE Sales.OrderDetails
  SET discount += 0.05
WHERE orderid = 10249;

-- 2-3в
-- Теперь снова прочитайте данные в контексте Соединения 1
-- и подтвердите транзакцию:

  SELECT orderid, productid, unitprice, qty, discount
  FROM Sales.OrderDetails
  WHERE orderid = 10249;
  
COMMIT TRAN;

-- Вы опять получите две строки со значением 0,00 в столбце discount, что
-- будет свидетельствовать о повторяющемся чтении. Если бы ваш код работал
-- на более низком уровне изоляции (таком как READ UNCOMMITTED или
-- READ COMMITTED), команда UPDATE не была бы заблокирована,
-- и вы бы получили неповторяющееся чтение.

-- 2-3г
-- Перейдите к Соединению 2. Как видите, обновление завершено.

-- 2-3д
-- Верните таблицу в исходное состояние с помощью следующего кода.
UPDATE Sales.OrderDetails
  SET discount = 0.00
WHERE orderid = 10249;

---------------------------------------------------------------------
-- 2-4 Уровень изоляции SERIALIZABLE
---------------------------------------------------------------------

-- 2-4а
-- Перейдите к Соединению 1, установите уровень изоляции SERIALIZABLE
-- и выполните запрос к таблице Sales.OrderDetails:

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

BEGIN TRAN;

  SELECT orderid, productid, unitprice, qty, discount
  FROM Sales.OrderDetails
  WHERE orderid = 10249;

-- 2-4б
-- Переключитесь на Соединения 2. Попытайтесь добавить в таблицу
-- Sales.OrderDetails строку с тем же идентификатором заказа,
-- который был получен в предыдущем запросе. Вы должны заметить,
-- что соединение заблокировано:

INSERT INTO Sales.OrderDetails
    (orderid, productid, unitprice, qty, discount)
  VALUES(10249, 2, 19.00, 10, 0.00);

-- Если бы ваш код работал на более низком уровне изоляции
-- (таком как READ UNCOMMITTED, READ COMMITTED или REPEATABLE READ),
-- команда INSERT не была бы остановлена.

-- 2-4в
-- Запустите в контексте Соединения 1 следующий код, который опять
-- выполняет запрос к таблице Sales.OrderDetails и подтверждает транзакцию:

  SELECT orderid, productid, unitprice, qty, discount
  FROM Sales.OrderDetails
  WHERE orderid = 10249;

COMMIT TRAN;

-- Результат будет таким же, как на этапе 2-4а, но поскольку команда
-- INSERT была заблокирована, фантомное чтение исключено.

-- 2-4г
-- Вернитесь к Соединению 2. Команда INSERT должна была завершиться.

-- 2-4д
-- Верните таблицу в исходное состояние:
DELETE FROM Sales.OrderDetails
WHERE orderid = 10249
  AND productid = 2;
  
-- 2-4е
-- Запустите следующий код в рамках обоих соединений,
-- чтобы установить стандартный уровень изоляции:
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

---------------------------------------------------------------------
-- 2-5 Уровень изоляции SNAPSHOT
---------------------------------------------------------------------

-- 2-5а
-- Если вы имеете дело с локальным экземпляром SQL Server, запустите
-- следующий код, чтобы установить для базы данных TSQL2012 уровень
-- изоляции SNAPSHOT (в SQL Database он включен по умолчанию):
ALTER DATABASE TSQL2012 SET ALLOW_SNAPSHOT_ISOLATION ON;

-- 2-5б
-- Запустите внутри Соединения 1 следующий код, который
-- открывает транзакцию, обновляет строки таблицы Sales.OrderDetails
-- и возвращает их в качестве результата:

BEGIN TRAN;

  UPDATE Sales.OrderDetails
    SET discount += 0.05
  WHERE orderid = 10249;

  SELECT orderid, productid, unitprice, qty, discount
  FROM Sales.OrderDetails
  WHERE orderid = 10249;

-- 2-5в
-- Перейдите к Соединению 2, установите уровень изоляции SNAPSHOT и
-- выполните запрос к таблице Sales.OrderDetails. Как видите, вы не
-- заблокированы — вместо этого вы должны получить старую,
-- подтвержденную версию данных, которая была доступна на момент
-- открытия транзакции (со скидкой, равной 0,00):

SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

BEGIN TRAN;

  SELECT orderid, productid, unitprice, qty, discount
  FROM Sales.OrderDetails
  WHERE orderid = 10249;

-- 2-5г
-- Вернитесь к Соединению 1 и подтвердите транзакцию:

COMMIT TRAN;

-- 2-5д
-- Опять запросите данные в контексте Соединения 2; обратите
-- внимание, что скидка по-прежнему равна 0,00:

  SELECT orderid, productid, unitprice, qty, discount
  FROM Sales.OrderDetails
  WHERE orderid = 10249;

-- 2-5е
-- Находясь в том же соединении, подтвердите транзакцию и снова
-- запросите данные; как видите, вы получили скидку размером 0,05:

COMMIT TRAN;

SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;

-- 2-5ж
-- Верните таблицу к исходному состоянию:
UPDATE Sales.OrderDetails
  SET discount = 0.00
WHERE orderid = 10249;

-- Закройте все соединения

---------------------------------------------------------------------
-- 2-6 Уровень изоляции READ COMMITTED SNAPSHOT
---------------------------------------------------------------------

-- 2-6а
-- Если вы имеете дело с локальным экземпляром SQL Server,
-- активируйте для базы данных TSQL2012 параметр READ_COMMITTED_SNAPSHOT
-- (в SQL Database он включен по умолчанию).
ALTER DATABASE TSQL2012 SET READ_COMMITTED_SNAPSHOT ON;

-- 2-6б
-- Откройте два новых соединения (назовем их Соединение 1 и Соединение 2).

-- 2-6в
-- Запустите в контексте Соединения 1 следующий код, который
-- открывает транзакцию, обновляет строки в таблице Sales.OrderDetails
-- и возвращает их в качестве результата:

BEGIN TRAN;

  UPDATE Sales.OrderDetails
    SET discount += 0.05
  WHERE orderid = 10249;

  SELECT orderid, productid, unitprice, qty, discount
  FROM Sales.OrderDetails
  WHERE orderid = 10249;

-- 2-6г

-- Запустите код, представленный ниже, внутри Соединения 2, которое,
-- благодаря включенному параметру READ_COMMITTED_SNAPSHOT, работает
-- в режиме READ COMMITTED SNAPSHOT. Как видите, вы не
-- заблокированы — вместо этого вы должны получить старую, подтвержденную
-- версию данных, которая была доступна на момент запуска команды
-- (со скидкой, равной 0,00):

BEGIN TRAN;

  SELECT orderid, productid, unitprice, qty, discount
  FROM Sales.OrderDetails
  WHERE orderid = 10249;

-- 2-6д
-- Перейдите к Соединению 1 и подтвердите транзакцию:

COMMIT TRAN;

-- 2-6е
-- Вернитесь к Соединению 2; снова запросите данные и подтвердите
-- транзакцию. Обратите внимание, что на этот раз скидка равна 0,05:

  SELECT orderid, productid, unitprice, qty, discount
  FROM Sales.OrderDetails
  WHERE orderid = 10249;

COMMIT TRAN;

-- 2-6ж
-- Верните таблицу к исходному состоянию:
UPDATE Sales.OrderDetails
  SET discount = 0.00
WHERE orderid = 10249;

-- Закройте все соединения

-- 2-6з
-- Если вы имеете дело с локальным экземпляром SQL Server, присвойте
-- параметрам базы данных значения по умолчанию, чтобы отключить уровни
-- изоляции, основанные на управлении версиями строк:
ALTER DATABASE TSQL2012 SET ALLOW_SNAPSHOT_ISOLATION OFF;
ALTER DATABASE TSQL2012 SET READ_COMMITTED_SNAPSHOT OFF;

---------------------------------------------------------------------
-- 3 Взаимное блокирование
---------------------------------------------------------------------

-- 3-1
-- Откройте два новых соединения (назовем их Соединение 1 и Соединение 2).

-- 3-2
-- Запустите в контексте Соединения 1 следующий код, который
-- открывает транзакцию и обновляет в таблице Production.Products
-- строку с товаром под номером 2:

BEGIN TRAN;

  UPDATE Production.Products
    SET unitprice += 1.00
  WHERE productid = 2;

-- 3-3
-- Запустите в контексте Соединения 2 следующий код, который
-- открывает транзакцию и обновляет в таблице Production.Products
-- строку с товаром под номером 3:

BEGIN TRAN;

  UPDATE Production.Products
    SET unitprice += 1.00
  WHERE productid = 3;

-- 3-4
-- Запросите продукт под номером 3 в Соединении 1. Вы будете заблокированы:

  SELECT productid, unitprice
  FROM Production.Products -- WITH (READCOMMITTEDLOCK)
  WHERE productid = 3;

COMMIT TRAN;

-- 3-5
-- Запросите продукт под номером 2 во втором соединении. Выполнение
-- вашего запроса будет приостановлено, а в одном из соединений
-- будет сгенерировано сообщение о взаимном блокировании:

  SELECT productid, unitprice
  FROM Production.Products -- WITH (READCOMMITTEDLOCK)
  WHERE productid = 2;

COMMIT TRAN;

-- 3-6
-- Можете ли вы предложить решение, которое позволило бы избежать этой проблемы? 
-- Ответ: поменяйте порядок доступа к объектам в одной из транзакций.

-- 3-7
-- Приведите таблицу Products к исходному состоянию:
UPDATE Production.Products
  SET unitprice = 19.00
WHERE productid = 2;

UPDATE Production.Products
  SET unitprice = 10.00
WHERE productid = 3;

