# Device manufacturer database


## Project Details

This goal of this project is to create a product tracking system that can track products by serial number along the supply chain all the way to the customer's hands. For this project, the client is Apple and I assume to role of a database architect. An apple product is created by the manufacturer. It is then shipped down the supply chain all the way to the store where it is then sold to a customer. The supply chain can be visualized below:

Manufacturer -> Warehouse -> Distributor -> Sub-distributor -> Channel Partner -> Zone -> Store

Of course, the stores will sell the products to the customer.

Each continent has four manufacturers. The manufacturers ship products to the warehouses within their continent.
Each country has four warehouses and one distributor.
Each distributor can have multiple sub-distributors below them. Sub-distributors have multiple channel partners below them. Channel partners have multiple zones below them. And zones have multiple stores below them.

The tracking system can where each product has been by serial number. For a given serial number, it can track which manufacturer it was produced at, which warehouse it was shipped to, etc. This tracking system also includes to which customer it was sold.

A product can be returned and shipped back to the manufacturer. This too is tracked.

Each manufacturer has a fixed price for how much it sells a product. When the next node in the supply chain buys it from the manufacturer, they mark up the price by 8% per node. Since a product makes 7 jumps before reaching a customer, the price the customer pays is the [price set by the manufacturer] * 1.08^7.

This database includes views and stored procedures that supply chain managers may use as well as triggers to automatically populate derived fields. It also includes stored procedures to simulate products being shipped up and down the supply chain. In addition to that, the database also has non-clustered indexes to speed up performance.

## Technologies Used

- T-SQL
- SQL Server
- SQL Server Integration Services

## Features

- The ability the track any item by serial number regardless of where it is in the supply chain (or if it's in the customer's hands)
- Can show an item's entire history including where it was manufacturered and where in the supply chain it passed
- Useful views for managers to look at sales and returns
- Indexes to improve database performance


## Getting Started

Clone the repository and restore the provided database.
git clone https://github.com/210104-msbi-reston/Min-Wei-P1.git

## Usage

Shipping the items up and down the supply chain is done with stored procedures. For a demo, simply open the Demo.sql file.

## License

This project may not be used for commercial purposes.
