USE WideWorldImporters;



/*Proposition 1: top customers by revenue in 2016*/
SELECT TOP (10)
    c.CustomerID,
    c.CustomerName,
    CAST(SUM(ol.Quantity * ol.UnitPrice) AS decimal(18,2)) AS Revenue2016
FROM Sales.Orders       AS o
JOIN Sales.OrderLines   AS ol ON o.OrderID    = ol.OrderID
JOIN Sales.Customers    AS c  ON o.CustomerID = c.CustomerID
WHERE o.OrderDate >= '2016-01-01'
  AND o.OrderDate <  '2017-01-01'
GROUP BY c.CustomerID, c.CustomerName
ORDER BY Revenue2016 DESC;

/*Proposition 2: top selling products in 2016*/
SELECT TOP (10)
    s.StockItemID,
    s.StockItemName,
    CAST(SUM(ol.Quantity * ol.UnitPrice) AS decimal(18,2)) AS Revenue2016
FROM Sales.Orders     AS o
JOIN Sales.OrderLines AS ol ON o.OrderID    = ol.OrderID
JOIN Warehouse.StockItems AS s ON ol.StockItemID = s.StockItemID
WHERE o.OrderDate >= '2016-01-01' AND o.OrderDate < '2017-01-01'
GROUP BY s.StockItemID, s.StockItemName
ORDER BY Revenue2016 DESC;

/*Proposition 3: 2016 revenue by delivery city*/
SELECT 
    ct.CityName,
    CAST(SUM(ol.Quantity * ol.UnitPrice) AS decimal(18,2)) AS Revenue2016
FROM Sales.Orders         AS o
JOIN Sales.OrderLines     AS ol ON o.OrderID       = ol.OrderID
JOIN Sales.Customers      AS c  ON o.CustomerID    = c.CustomerID
JOIN Application.Cities   AS ct ON c.DeliveryCityID = ct.CityID
WHERE o.OrderDate >= '2016-01-01'
  AND o.OrderDate <  '2017-01-01'
GROUP BY ct.CityName
ORDER BY Revenue2016 DESC;

/*Proposition 4: sales by salesperson(all time)*/
SELECT 
    p.PersonID,
    p.FullName AS Salesperson,
    CAST(SUM(ol.Quantity * ol.UnitPrice) AS decimal(18,2)) AS TotalRevenue
FROM Sales.Orders       AS o
JOIN Sales.OrderLines   AS ol ON o.OrderID = ol.OrderID
JOIN Application.People AS p  ON o.SalespersonPersonID = p.PersonID
GROUP BY p.PersonID, p.FullName
ORDER BY TotalRevenue DESC;

/*Proposition 5: revenue by stock group*/
SELECT 
    g.StockGroupID,
    g.StockGroupName,
    CAST(SUM(ol.Quantity * ol.UnitPrice) AS decimal(18,2)) AS TotalRevenue
FROM Warehouse.StockItems            AS s
JOIN Warehouse.StockItemStockGroups  AS sg ON s.StockItemID = sg.StockItemID
JOIN Warehouse.StockGroups           AS g  ON sg.StockGroupID = g.StockGroupID
JOIN Sales.OrderLines                AS ol ON ol.StockItemID  = s.StockItemID
GROUP BY g.StockGroupID, g.StockGroupName
ORDER BY TotalRevenue DESC;

/*Proposition 6: average picking latency by customers(hours)*/
SELECT 
    c.CustomerID,
    c.CustomerName,
    AVG(DATEDIFF(HOUR, o.OrderDate, o.PickingCompletedWhen)) AS AvgPickHours
FROM Sales.Orders    AS o
JOIN Sales.Customers AS c ON o.CustomerID = c.CustomerID
WHERE o.PickingCompletedWhen IS NOT NULL
GROUP BY c.CustomerID, c.CustomerName
ORDER BY AvgPickHours DESC;

/*Proposition 7: frequently purchased item pairs*/
SELECT TOP (20)
    CASE WHEN a.StockItemID < b.StockItemID THEN a.StockItemID ELSE b.StockItemID END AS ItemA,
    CASE WHEN a.StockItemID < b.StockItemID THEN b.StockItemID ELSE a.StockItemID END AS ItemB,
    COUNT(DISTINCT a.OrderID) AS CoOrderCount
FROM Sales.OrderLines AS a
JOIN Sales.OrderLines AS b
  ON a.OrderID = b.OrderID
 AND a.StockItemID < b.StockItemID
GROUP BY
    CASE WHEN a.StockItemID < b.StockItemID THEN a.StockItemID ELSE b.StockItemID END,
    CASE WHEN a.StockItemID < b.StockItemID THEN b.StockItemID ELSE a.StockItemID END
ORDER BY CoOrderCount DESC;

/*Proposition 8: reorder items with strong recent demand*/
WITH RecentSales AS (
  SELECT ol.StockItemID, SUM(ol.Quantity) AS Qty60d
  FROM Sales.OrderLines AS ol
  JOIN Sales.Orders     AS o ON o.OrderID = ol.OrderID
  WHERE o.OrderDate >= '2016-04-01' 
    AND o.OrderDate <  '2016-06-01'   -- 2-month window
  GROUP BY ol.StockItemID
)
SELECT 
  s.StockItemID,
  s.StockItemName,
  h.QuantityOnHand,
  h.ReorderLevel,
  rs.Qty60d
FROM Warehouse.StockItems        AS s
JOIN Warehouse.StockItemHoldings AS h  ON s.StockItemID = h.StockItemID
JOIN RecentSales                 AS rs ON s.StockItemID = rs.StockItemID
WHERE h.QuantityOnHand < h.ReorderLevel
ORDER BY rs.Qty60d DESC, s.StockItemName;

/*Proposition 9: suppliers who are on-time delivery rate*/
SELECT 
    s.SupplierID,
    s.SupplierName,
    CAST(100.0 * AVG(CASE 
         WHEN pol.LastReceiptDate IS NOT NULL 
          AND pol.LastReceiptDate <= po.ExpectedDeliveryDate 
         THEN 1.0 ELSE 0.0 END) AS decimal(5,2)) AS OnTimePct
FROM Purchasing.PurchaseOrders     AS po
JOIN Purchasing.PurchaseOrderLines AS pol ON po.PurchaseOrderID = pol.PurchaseOrderID
JOIN Purchasing.Suppliers          AS s   ON po.SupplierID      = s.SupplierID
WHERE pol.LastReceiptDate IS NOT NULL
GROUP BY s.SupplierID, s.SupplierName
ORDER BY OnTimePct DESC, s.SupplierName;

/*Proposition 10: customer churn candidates*/
SELECT c.CustomerID, c.CustomerName
FROM Sales.Customers AS c
WHERE EXISTS (
    SELECT 1
    FROM Sales.Orders AS oPast
    WHERE oPast.CustomerID = c.CustomerID
      AND oPast.OrderDate < '2016-10-01'   
)
AND NOT EXISTS (
    SELECT 1
    FROM Sales.Orders AS oRecent
    WHERE oRecent.CustomerID = c.CustomerID
      AND oRecent.OrderDate >= '2016-10-01'  
      AND oRecent.OrderDate <  '2017-01-01'
)
ORDER BY c.CustomerName;

