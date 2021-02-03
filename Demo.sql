-- Global Stock
select * from Stock

-- Look at the production centers
select * from production_centers

--Look at stock
select * from Stock where [Current Location] = 'PC-13'

--look at products
select * from products

--Register newly produced units
EXEC ProduceNewItems 13, 100002, 1


--Confirm registration
select * from Stock where [Current Location] = 'PC-13'

select * from items where serial_number >= 4

select * from item_history where serial_number >= 3

--Look downstream
EXEC LookDown 'PC-13'

--Ship down the supply chain
EXEC ShipItems 'PC-13', 'WH-749', 100002, 1, 1

select * from items where serial_number >= 4

select * from item_history where serial_number >= 3

--Check production center
select * from Stock where [Current Location] = 'PC-13'

--Check warehouse
select * from Stock where [Current Location] = 'WH-749'

--Check shipments
select * from shipments order by shipment_id desc

select * from shipments_items_junction where shipment_id = 1

-- Receive shipments
EXEC ReceiveShipment 'WH-749', 14
select * from shipments order by shipment_id desc

--Check warehouse
select * from Stock where [Current Location] = 'WH-749'

--Ship it down to the distributor
EXEC LookDown 'WH-749'

EXEC ShipItems 'WH-749', 'DI-188', 100002, 1, 1

select * from shipments order by shipment_id desc

EXEC ReceiveShipment 'DI-188', 15

--Ship it down to the sub-distributor
EXEC LookDown 'DI-188'

EXEC ShipItems 'DI-188', 'SD-188', 100002, 1, 1

select * from shipments order by shipment_id desc

EXEC ReceiveShipment 'SD-188', 16

--Ship it down to the channel partner
EXEC LookDown 'SD-188'

EXEC ShipItems 'SD-188', 'CP-188', 100002, 1, 1

select * from shipments order by shipment_id desc

EXEC ReceiveShipment 'CP-188', 17

--Ship it down to the zone
EXEC LookDown 'CP-188'

EXEC ShipItems 'CP-188', 'ZO-188', 100002, 1, 1

select * from shipments order by shipment_id desc

EXEC ReceiveShipment 'ZO-188', 18

--Ship it down to the zone
EXEC LookDown 'ZO-188'

EXEC ShipItems 'ZO-188', 'ST-188', 100002, 1, 1

select * from shipments order by shipment_id desc

EXEC ReceiveShipment 'ST-188', 19

--Look at stock
select * from Stock where [Current Location] = 'ST-188'

--Sell it
EXEC SellItem 253, 1

select * from item_history where serial_number = 253

select * from SalesView
select *, dbo.GetCountry(CONCAT('ST-', CAST([Store ID] AS VARCHAR(10)))) AS [Country] from SalesView

--Return it
EXEC ReturnItem 253, 188, 'Customer stated Windows phones are better than the iPhone 12 Pro'





select * from ReturnsView


--Ship it back up the supply chain
select * from Stock where [Current Location] = 'ST-188' and Condition = 'Used'

EXEC LookUp 'ST-188'

EXEC ShipItems 'ST-188', 'ZO-188', 100002, 1, 0

select * from shipments order by shipment_id desc

EXEC ReceiveShipment 'ZO-188', 20

--Ship to channel partner
EXEC LookUp 'ZO-188'

EXEC ShipItems 'ZO-188', 'CP-188', 100002, 1, 0

select * from shipments order by shipment_id desc

EXEC ReceiveShipment 'CP-188', 21

--Ship to sub-distributor
EXEC LookUp 'CP-188'

EXEC ShipItems 'CP-188', 'SD-188', 100002, 1, 0

select * from shipments order by shipment_id desc

EXEC ReceiveShipment 'SD-188', 22

--Ship to distributor
EXEC LookUp 'SD-188'

EXEC ShipItems 'SD-188', 'DI-188', 100002, 1, 0

select * from shipments order by shipment_id desc

EXEC ReceiveShipment 'DI-188', 23

--Ship to warehouse
EXEC LookUp 'DI-188'

EXEC ShipItems 'DI-188', 'WH-749', 100002, 1, 0

select * from shipments order by shipment_id desc

EXEC ReceiveShipment 'WH-749', 24

--Ship to warehouse
EXEC LookUp 'WH-749'

EXEC ShipItems 'WH-749', 'PC-13', 100002, 1, 0

select * from shipments order by shipment_id desc

EXEC ReceiveShipment 'PC-13', 25


select * from item_history where serial_number = 253


/***

I did not create non-clustered indexes because...

actions - single column
countries - no look ups are done with continent
customers - in a more realistic situation, the customer table would constantly receive inserts which would require rebuilding the index
item_history and items - these will also receive constant updates
items_temporary - it's a temporary table that gets truncated when the transaction is complete
production_costs - common lookups use the primary keys
products - same as above
returns and sales - will receive constant updates
shipments_items_junction - two column composite primary key table

All procedures and functions do lookups on supply chain nodes by converting the node key to node ID so those lookups are already using an index


I did create one non-clustered index for...

shipments table on the destination_node_key column and the source_node_key column, included all other information with both indexes
node managers may want to look up shipments they sent and are expecting
insertion frequency for the shipments table should be relatively uncommon compared to item history, sales or returns
***/