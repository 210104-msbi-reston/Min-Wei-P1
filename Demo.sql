select * from item_history where serial_number = 253

-- Global Stock
select * from view_Stock

-- Look at the production centers
select * from production_centers

--Look at stock
select * from view_Stock where [Current Location] = 'PC-13'

--look at products
select * from products

--Register newly produced units
EXEC proc_ProduceNewItems 13, 100002, 1000


--Confirm registration
select * from view_Stock where [Current Location] = 'PC-13'

select * from items where serial_number >= 11254

select * from item_history where serial_number >= 11254

--Look downstream
EXEC proc_LookDown 'PC-13'

--Ship down the supply chain
EXEC proc_ShipItems 'PC-13', 'WH-749', 100002, 1000, 1

select * from items where serial_number >= 11254

select * from item_history where serial_number >= 11254

--Check shipments
select * from shipments order by shipment_id desc

select * from shipments_items_junction where shipment_id = 38

--Check production center
select * from view_Stock where [Current Location] = 'PC-13'

--Check warehouse
select * from view_Stock where [Current Location] = 'WH-749'

-- Receive shipments
EXEC proc_ReceiveShipment 'WH-749', 38
select * from shipments order by shipment_id desc

--Check warehouse
select * from view_Stock where [Current Location] = 'WH-749'

--Ship it down to the distributor
EXEC proc_LookDown 'WH-749'

EXEC proc_ShipItems 'WH-749', 'DI-188', 100002, 1000, 1

select * from shipments order by shipment_id desc

EXEC proc_ReceiveShipment 'DI-188', 33

--Ship it down to the sub-distributor
EXEC proc_LookDown 'DI-188'

EXEC proc_ShipItems 'DI-188', 'SD-188', 100002, 1000, 1

select * from shipments order by shipment_id desc

EXEC proc_ReceiveShipment 'SD-188', 34

--Ship it down to the channel partner
EXEC proc_LookDown 'SD-188'

EXEC proc_ShipItems 'SD-188', 'CP-188', 100002, 1000, 1

select * from shipments order by shipment_id desc

EXEC proc_ReceiveShipment 'CP-188', 35

--Ship it down to the zone
EXEC proc_LookDown 'CP-188'

EXEC proc_ShipItems 'CP-188', 'ZO-188', 100002, 1000, 1

select * from shipments order by shipment_id desc

EXEC proc_ReceiveShipment 'ZO-188', 36

--Ship it down to the zone
EXEC proc_LookDown 'ZO-188'

EXEC proc_ShipItems 'ZO-188', 'ST-188', 100002, 1000, 1

select * from shipments order by shipment_id desc

EXEC proc_ReceiveShipment 'ST-188', 37

--Look at stock
select * from view_Stock where [Current Location] = 'ST-188'

--Sell it
EXEC proc_SellItem 10255, 1

select * from item_history where serial_number = 10255

select * from view_Sales


--Return it
EXEC proc_ReturnItem 10255, 188, 'Customer stated Windows phones are better than the iPhone 12 Pro'





select * from view_Returns


--Ship it back up the supply chain
select * from view_Stock where [Current Location] = 'ST-188' and Condition = 'Used'

EXEC proc_LookUp 'ST-188'

EXEC proc_ShipItems 'ST-188', 'ZO-188', 100002, 1, 0

select * from shipments order by shipment_id desc

EXEC proc_ReceiveShipment 'ZO-188', 20

--Ship to channel partner
EXEC proc_LookUp 'ZO-188'

EXEC proc_ShipItems 'ZO-188', 'CP-188', 100002, 1, 0

select * from shipments order by shipment_id desc

EXEC proc_ReceiveShipment 'CP-188', 21

--Ship to sub-distributor
EXEC proc_LookUp 'CP-188'

EXEC proc_ShipItems 'CP-188', 'SD-188', 100002, 1, 0

select * from shipments order by shipment_id desc

EXEC proc_ReceiveShipment 'SD-188', 22

--Ship to distributor
EXEC proc_LookUp 'SD-188'

EXEC proc_ShipItems 'SD-188', 'DI-188', 100002, 1, 0

select * from shipments order by shipment_id desc

EXEC proc_ReceiveShipment 'DI-188', 23

--Ship to warehouse
EXEC proc_LookUp 'DI-188'

EXEC proc_ShipItems 'DI-188', 'WH-749', 100002, 1, 0

select * from shipments order by shipment_id desc

EXEC proc_ReceiveShipment 'WH-749', 24

--Ship to warehouse
EXEC proc_LookUp 'WH-749'

EXEC proc_ShipItems 'WH-749', 'PC-13', 100002, 1, 0

select * from shipments order by shipment_id desc

EXEC proc_ReceiveShipment 'PC-13', 25


select * from item_history where serial_number = 253

select * from customers


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



All node tables including customer have a trigger on insert that populates their node key
***/