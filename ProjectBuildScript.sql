USE [master]
GO
/****** Object:  Database [Project1DB]    Script Date: 2/4/2021 10:50:16 AM ******/
CREATE DATABASE [Project1DB]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Project1', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.TRAININGSERVER\MSSQL\DATA\Project1.mdf' , SIZE = 73728KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Project1_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.TRAININGSERVER\MSSQL\DATA\Project1_log.ldf' , SIZE = 139264KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
ALTER DATABASE [Project1DB] SET COMPATIBILITY_LEVEL = 130
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Project1DB].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [Project1DB] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Project1DB] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Project1DB] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Project1DB] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Project1DB] SET ARITHABORT OFF 
GO
ALTER DATABASE [Project1DB] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Project1DB] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Project1DB] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Project1DB] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Project1DB] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Project1DB] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Project1DB] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Project1DB] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [Project1DB] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Project1DB] SET  DISABLE_BROKER 
GO
ALTER DATABASE [Project1DB] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Project1DB] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Project1DB] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Project1DB] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Project1DB] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Project1DB] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Project1DB] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Project1DB] SET RECOVERY FULL 
GO
ALTER DATABASE [Project1DB] SET  MULTI_USER 
GO
ALTER DATABASE [Project1DB] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Project1DB] SET DB_CHAINING OFF 
GO
ALTER DATABASE [Project1DB] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [Project1DB] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [Project1DB] SET DELAYED_DURABILITY = DISABLED 
GO
EXEC sys.sp_db_vardecimal_storage_format N'Project1DB', N'ON'
GO
ALTER DATABASE [Project1DB] SET QUERY_STORE = OFF
GO
USE [Project1DB]
GO
ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;
GO
ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = OFF;
GO
USE [Project1DB]
GO
/****** Object:  User [DESKTOP-E1KTPMR\Mee]    Script Date: 2/4/2021 10:50:17 AM ******/
CREATE USER [DESKTOP-E1KTPMR\Mee] FOR LOGIN [DESKTOP-E1KTPMR\Mee] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  UserDefinedFunction [dbo].[CalculateCost]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[CalculateCost] ( @p_serial_number bigint )
returns float
as
begin
	declare @_product_id int
	declare @_production_center_id int
	declare @_base_cost float

	if exists (select * from items where serial_number = @p_serial_number)
	begin
		select @_product_id = product_id
		from items
		where serial_number = @p_serial_number

		select @_production_center_id = TRY_CAST(SUBSTRING(node_key, 4, 27) AS BIGINT)
		from item_history
		where serial_number = @p_serial_number
		and action = 'Produced'

		select @_base_cost = base_cost
		from production_costs
		where product_id = @_product_id
			and production_center_id = @_production_center_id

		return power(1.08, 7) * @_base_cost
	end

	return 0
end
GO
/****** Object:  UserDefinedFunction [dbo].[DoesNodeExist]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[DoesNodeExist](@p_node_key varchar(30))
returns bit
as
begin

	/****
	This function returns 1 if the node exists and 0 if the node does not exist.

	First thing it does, is split the input node key into node type and node id.
	The node type is the first three characters and identifies which table to look in.
	The node ID is the series of numbers after that.
	Then it checks if the node type is valid (only 8 possible valid values).
	If valid, it will check the appropriate table for existence of the node.
	****/
	declare @_node_type nchar(3)
	declare @_node_id int

	set @_node_type = SUBSTRING(@p_node_key, 1, 3)
	set @_node_id = TRY_CAST(SUBSTRING(@p_node_key, 4, 27) AS INT)
	
	IF (@_node_type = 'PC-')
		BEGIN
			IF EXISTS ( SELECT * FROM production_centers WHERE production_center_id = @_node_id )
				RETURN 1
			ELSE
				RETURN 0
		END
	ELSE IF (@_node_type = 'WH-')
		BEGIN
			IF EXISTS ( SELECT * FROM warehouses WHERE warehouse_id = @_node_id )
				RETURN 1
			ELSE
				RETURN 0
		END
	ELSE IF (@_node_type = 'DI-')
		BEGIN
			IF EXISTS ( SELECT * FROM distributors WHERE distributor_id = @_node_id )
				RETURN 1
			ELSE
				RETURN 0
		END
	ELSE IF (@_node_type = 'SD-')
		BEGIN
			IF EXISTS ( SELECT * FROM sub_distributors WHERE sub_distributor_id = @_node_id )
				RETURN 1
			ELSE
				RETURN 0
		END
	ELSE IF (@_node_type = 'CP-')
		BEGIN
			IF EXISTS ( SELECT * FROM channel_partners WHERE channel_partner_id = @_node_id )
				RETURN 1
			ELSE
				RETURN 0
		END
	ELSE IF (@_node_type = 'ZO-')
		BEGIN
			IF EXISTS ( SELECT * FROM zones WHERE zone_id = @_node_id )
				RETURN 1
			ELSE
				RETURN 0
		END
	ELSE IF (@_node_type = 'ST-')
		BEGIN
			IF EXISTS ( SELECT * FROM stores WHERE store_id = @_node_id )
				RETURN 1
			ELSE
				RETURN 0
		END
	ELSE IF (@_node_type = 'CU-')
		BEGIN
			IF EXISTS ( SELECT * FROM customers WHERE customer_id = @_node_id )
				RETURN 1
			ELSE
				RETURN 0
		END
	ELSE
		RETURN 0

	RETURN 0
end;
GO
/****** Object:  UserDefinedFunction [dbo].[GetContinent]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetContinent] (@p_country VARCHAR(40))
RETURNS VARCHAR(20)
AS
BEGIN
	DECLARE @_continent VARCHAR(20)
	SELECT @_continent = continent
	FROM countries
	WHERE country = @p_country
	RETURN @_continent
END;
GO
/****** Object:  UserDefinedFunction [dbo].[GetCountry]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[GetCountry](@p_node_key varchar(22))
returns varchar(40)
as
begin
	declare @_node_type nchar(3)
	declare @_country varchar(40)
	declare @_new_node_key varchar(22)
	declare @_node_id int = TRY_CAST(SUBSTRING(@p_node_key, 4, 19) AS int)

	set @_node_type = SUBSTRING(@p_node_key, 1, 3)

	IF (@_node_type = 'PC-')
		begin
			select @_country = country from production_centers where production_center_id = @_node_id
			return @_country
		end
	ELSE IF (@_node_type = 'WH-')
		begin
			select @_new_node_key = di.node_key
			from warehouses wh join distributors di on wh.distributor_id = di.distributor_id
			where wh.warehouse_id = @_node_id

			return dbo.GetCountry(@_new_node_key)
		end
	ELSE IF (@_node_type = 'DI-')
		begin
			SELECT @_country = country FROM distributors WHERE distributor_id = @_node_id
			return @_country
		end
	ELSE IF (@_node_type = 'SD-')
		begin
			select @_new_node_key = di.node_key
			from sub_distributors sd join distributors di on sd.distributor_id = di.distributor_id
			where sd.sub_distributor_id = @_node_id

			return dbo.GetCountry(@_new_node_key)
		end
	ELSE IF (@_node_type = 'CP-')
		begin
			select @_new_node_key = sd.node_key
			from channel_partners cp join sub_distributors sd on cp.sub_distributor_id = sd.sub_distributor_id
			where cp.channel_partner_id = @_node_id

			return dbo.GetCountry(@_new_node_key)
		end
	ELSE IF (@_node_type = 'ZO-')
		begin
			select @_new_node_key = cp.node_key
			from zones as zo join channel_partners as cp on zo.channel_partner_id = cp.channel_partner_id
			where zo.zone_id = @_node_id

			return dbo.GetCountry(@_new_node_key)
		end
	ELSE IF (@_node_type = 'ST-')
		begin
			select @_new_node_key = zo.node_key
			from stores as st join zones as zo on st.zone_id = zo.zone_id
			where st.store_id = @_node_id

			return dbo.GetCountry(@_new_node_key)
		end
	return null
end;
GO
/****** Object:  UserDefinedFunction [dbo].[isConnected]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[isConnected] ( @p_up_node_key varchar(30), @p_down_node_key varchar(30) )
returns bit
as
begin

	/****
	This function will return 1 if the two nodes are connected or 0 if not.

	@p_up_node is the node that's higher in the supply chain
	@p_down_node is the node that's lower in the supply chain

	If both nodes are connected but the order of the parameters is reversed, the function will return 0.
	****/

	-- Check if the nodes exist
	if (dbo.DoesNodeExist(@p_up_node_key) = 0)
		return 0

	if (dbo.DoesNodeExist(@p_down_node_key) = 0)
		return 0

	-- Split up the nodes into node type and node id
	declare @_up_node_type nchar(3)
	declare @_up_node_id int

	set @_up_node_type = SUBSTRING(@p_up_node_key, 1, 3)
	set @_up_node_id = TRY_CAST(SUBSTRING(@p_up_node_key, 4, 27) AS INT)

	declare @_down_node_type nchar(3)
	declare @_down_node_id int

	set @_down_node_type = SUBSTRING(@p_down_node_key, 1, 3)
	set @_down_node_id = TRY_CAST(SUBSTRING(@p_down_node_key, 4, 27) AS INT)

	-- Check @_up_node_type against all possible valid values
	-- If the above is true, check @_down_node_type against one possible valid value
	-- If the above is also true, check if the two nodes are connected

	if (@_up_node_type = 'PC-')
		begin
			if (@_down_node_type = 'WH-')
				begin
					if exists (select * from warehouses where production_center_id = @_up_node_id and warehouse_id = @_down_node_id)
						return 1
					else
						return 0
				end
			else
				return 0
		end
	
	if (@_up_node_type = 'WH-')
		begin
			if (@_down_node_type = 'DI-')
				begin
					if exists (select * from warehouses where warehouse_id = @_up_node_id and distributor_id = @_down_node_id)
						return 1
					else
						return 0
				end
			else
				return 0
		end

	if (@_up_node_type = 'DI-')
		begin
			if (@_down_node_type = 'SD-')
				begin
					if exists (select * from sub_distributors where distributor_id = @_up_node_id and sub_distributor_id = @_down_node_id)
						return 1
					else
						return 0
				end
			else
				return 0
		end

	if (@_up_node_type = 'SD-')
		begin
			if (@_down_node_type = 'CP-')
				begin
					if exists (select * from channel_partners where sub_distributor_id = @_up_node_id and channel_partner_id = @_down_node_id)
						return 1
					else
						return 0
				end
			else
				return 0
		end


	if (@_up_node_type = 'CP-')
		begin
			if (@_down_node_type = 'ZO-')
				begin
					if exists (select * from zones where channel_partner_id = @_up_node_id and zone_id = @_down_node_id)
						return 1
					else
						return 0
				end
			else
				return 0
		end

	if (@_up_node_type = 'ZO-')
		begin
			if (@_down_node_type = 'ST-')
				begin
					if exists (select * from stores where zone_id = @_up_node_id and store_id = @_down_node_id)
						return 1
					else
						return 0
				end
			else
				return 0
		end

	return 0
end
GO
/****** Object:  Table [dbo].[products]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[products](
	[product_id] [int] NOT NULL,
	[product_name] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[product_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[items]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[items](
	[serial_number] [bigint] IDENTITY(1,1) NOT NULL,
	[product_id] [int] NULL,
	[node_key] [varchar](22) NULL,
	[is_new] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[serial_number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[view_Stock]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[view_Stock] as
SELECT serial_number AS [Serial Number],
	i.product_id AS [Product ID],
	p.product_name AS [Product Name],
	i.node_key AS [Current Location],
	CASE
		WHEN is_new > 0 THEN 'New'
		WHEN is_new = 0 THEN 'Used'
		END AS [Condition]
FROM items AS i, products AS p
WHERE i.product_id = p.product_id
GO
/****** Object:  Table [dbo].[stores]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[stores](
	[store_id] [int] IDENTITY(1,1) NOT NULL,
	[node_key] [varchar](13) NULL,
	[name] [varchar](50) NULL,
	[zone_id] [int] NULL,
 CONSTRAINT [PK__stores__A2F2A30CBC76527A] PRIMARY KEY CLUSTERED 
(
	[store_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[sales]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[sales](
	[sale_id] [bigint] IDENTITY(1,1) NOT NULL,
	[store_id] [int] NULL,
	[customer_id] [bigint] NULL,
	[serial_number] [bigint] NULL,
	[date_time] [datetime] NULL,
 CONSTRAINT [PK__sales__E1EB00B26C7E2553] PRIMARY KEY CLUSTERED 
(
	[sale_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[customers]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[customers](
	[customer_id] [bigint] IDENTITY(1,1) NOT NULL,
	[node_key] [varchar](22) NULL,
	[forename] [varchar](20) NULL,
	[surname] [varchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[customer_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[view_Sales]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[view_Sales]
as
SELECT        s.date_time AS [Date & Time], s.store_id AS [Store ID], st.name AS [Store Name], cu.customer_id AS [Customer ID], CONCAT(cu.forename, ' ', cu.surname) AS [Customer Name], p.product_id AS [Product ID], 
                         p.product_name AS [Product Name], dbo.CalculateCost(s.serial_number) AS Price, dbo.GetCountry(CONCAT('ST-', CAST(st.store_id AS VARCHAR(10)))) AS [Country]
FROM            dbo.sales AS s INNER JOIN
                         dbo.stores AS st ON s.store_id = st.store_id INNER JOIN
                         dbo.customers AS cu ON s.customer_id = cu.customer_id INNER JOIN
                         dbo.items AS i ON s.serial_number = i.serial_number INNER JOIN
                         dbo.products AS p ON i.product_id = p.product_id
GO
/****** Object:  Table [dbo].[returns]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[returns](
	[rma_number] [bigint] IDENTITY(1,1) NOT NULL,
	[store_id] [int] NULL,
	[customer_id] [bigint] NULL,
	[serial_number] [bigint] NULL,
	[reason] [varchar](150) NULL,
	[date_time] [datetime] NULL,
 CONSTRAINT [PK__returns__C53F9E474C794A6A] PRIMARY KEY CLUSTERED 
(
	[rma_number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[view_Returns]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[view_Returns]
as
SELECT        r.date_time AS [Date of Return], r.store_id AS [Store ID], st.name AS [Store Name], r.customer_id AS [Customer ID], CONCAT(cu.forename, ' ', cu.surname) AS [Customer Name], i.product_id AS [Product ID], 
                         p.product_name AS [Product Name], dbo.CalculateCost(r.serial_number) AS [Original Purchase Price], dbo.GetCountry(CONCAT('ST-', CAST(st.store_id AS VARCHAR(10)))) AS [Country], r.reason AS [Reason For Return]
FROM            dbo.[returns] AS r INNER JOIN
                         dbo.stores AS st ON r.store_id = st.store_id INNER JOIN
                         dbo.customers AS cu ON r.customer_id = cu.customer_id INNER JOIN
                         dbo.items AS i ON r.serial_number = i.serial_number INNER JOIN
                         dbo.products AS p ON i.product_id = p.product_id
GO
/****** Object:  Table [dbo].[actions]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[actions](
	[action] [varchar](20) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[action] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[channel_partners]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[channel_partners](
	[channel_partner_id] [int] IDENTITY(1,1) NOT NULL,
	[node_key] [varchar](13) NULL,
	[name] [varchar](50) NULL,
	[sub_distributor_id] [int] NULL,
 CONSTRAINT [PK__channel___3BB5122E8ED9EEC8] PRIMARY KEY CLUSTERED 
(
	[channel_partner_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[countries]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[countries](
	[country] [varchar](40) NOT NULL,
	[continent] [varchar](20) NULL,
 CONSTRAINT [PK_countries] PRIMARY KEY CLUSTERED 
(
	[country] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[distributors]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[distributors](
	[distributor_id] [int] IDENTITY(1,1) NOT NULL,
	[node_key] [varchar](13) NULL,
	[name] [varchar](50) NULL,
	[country] [varchar](40) NULL,
 CONSTRAINT [PK__distribu__32F5A7678630690E] PRIMARY KEY CLUSTERED 
(
	[distributor_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[item_history]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[item_history](
	[date_time] [datetime] NOT NULL,
	[serial_number] [bigint] NOT NULL,
	[node_key] [varchar](22) NULL,
	[action] [varchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[date_time] ASC,
	[serial_number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[items_temporary]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[items_temporary](
	[serial_number] [bigint] NOT NULL,
	[product_id] [int] NULL,
	[node_key] [varchar](22) NULL,
	[is_new] [bit] NULL,
 CONSTRAINT [PK_items_temporary] PRIMARY KEY CLUSTERED 
(
	[serial_number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[production_centers]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[production_centers](
	[production_center_id] [int] IDENTITY(1,1) NOT NULL,
	[node_key] [varchar](13) NULL,
	[name] [varchar](50) NULL,
	[country] [varchar](40) NULL,
 CONSTRAINT [PK__producti__20D88C7B63865F38] PRIMARY KEY CLUSTERED 
(
	[production_center_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[production_costs]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[production_costs](
	[product_id] [int] NOT NULL,
	[production_center_id] [int] NOT NULL,
	[base_cost] [float] NULL,
PRIMARY KEY CLUSTERED 
(
	[product_id] ASC,
	[production_center_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[shipments]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[shipments](
	[shipment_id] [bigint] IDENTITY(1,1) NOT NULL,
	[source_node_key] [varchar](13) NULL,
	[destination_node_key] [varchar](13) NULL,
	[delivered] [bit] NULL,
	[date_time] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[shipment_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[shipments_items_junction]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[shipments_items_junction](
	[shipment_id] [bigint] NULL,
	[serial_number] [bigint] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[sub_distributors]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[sub_distributors](
	[sub_distributor_id] [int] IDENTITY(1,1) NOT NULL,
	[node_key] [varchar](13) NULL,
	[name] [varchar](50) NULL,
	[distributor_id] [int] NULL,
 CONSTRAINT [PK__sub_dist__C300FD088E00B616] PRIMARY KEY CLUSTERED 
(
	[sub_distributor_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[warehouses]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[warehouses](
	[warehouse_id] [int] IDENTITY(1,1) NOT NULL,
	[node_key] [varchar](13) NULL,
	[name] [varchar](50) NULL,
	[production_center_id] [int] NULL,
	[distributor_id] [int] NULL,
 CONSTRAINT [PK__warehous__734FE6BFD6F18F16] PRIMARY KEY CLUSTERED 
(
	[warehouse_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[zones]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[zones](
	[zone_id] [int] IDENTITY(1,1) NOT NULL,
	[node_key] [varchar](13) NULL,
	[name] [varchar](50) NULL,
	[channel_partner_id] [int] NULL,
 CONSTRAINT [PK__zones__80B401DFC94F3304] PRIMARY KEY CLUSTERED 
(
	[zone_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [idx_shipments_destination]    Script Date: 2/4/2021 10:50:17 AM ******/
CREATE NONCLUSTERED INDEX [idx_shipments_destination] ON [dbo].[shipments]
(
	[destination_node_key] ASC
)
INCLUDE([source_node_key],[delivered],[date_time]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [idx_shipments_source]    Script Date: 2/4/2021 10:50:17 AM ******/
CREATE NONCLUSTERED INDEX [idx_shipments_source] ON [dbo].[shipments]
(
	[source_node_key] ASC
)
INCLUDE([destination_node_key],[delivered],[date_time]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[items] ADD  DEFAULT ((1)) FOR [is_new]
GO
ALTER TABLE [dbo].[shipments] ADD  DEFAULT ((0)) FOR [delivered]
GO
ALTER TABLE [dbo].[channel_partners]  WITH CHECK ADD  CONSTRAINT [FK__channel_p__sub_d__4222D4EF] FOREIGN KEY([sub_distributor_id])
REFERENCES [dbo].[sub_distributors] ([sub_distributor_id])
GO
ALTER TABLE [dbo].[channel_partners] CHECK CONSTRAINT [FK__channel_p__sub_d__4222D4EF]
GO
ALTER TABLE [dbo].[distributors]  WITH CHECK ADD  CONSTRAINT [FK__distribut__count__30F848ED] FOREIGN KEY([country])
REFERENCES [dbo].[countries] ([country])
GO
ALTER TABLE [dbo].[distributors] CHECK CONSTRAINT [FK__distribut__count__30F848ED]
GO
ALTER TABLE [dbo].[item_history]  WITH CHECK ADD FOREIGN KEY([serial_number])
REFERENCES [dbo].[items] ([serial_number])
GO
ALTER TABLE [dbo].[item_history]  WITH CHECK ADD  CONSTRAINT [FK_item_history_action] FOREIGN KEY([action])
REFERENCES [dbo].[actions] ([action])
GO
ALTER TABLE [dbo].[item_history] CHECK CONSTRAINT [FK_item_history_action]
GO
ALTER TABLE [dbo].[items]  WITH CHECK ADD FOREIGN KEY([product_id])
REFERENCES [dbo].[products] ([product_id])
GO
ALTER TABLE [dbo].[production_centers]  WITH CHECK ADD  CONSTRAINT [FK_production_centers_country] FOREIGN KEY([country])
REFERENCES [dbo].[countries] ([country])
GO
ALTER TABLE [dbo].[production_centers] CHECK CONSTRAINT [FK_production_centers_country]
GO
ALTER TABLE [dbo].[production_costs]  WITH CHECK ADD FOREIGN KEY([product_id])
REFERENCES [dbo].[products] ([product_id])
GO
ALTER TABLE [dbo].[production_costs]  WITH CHECK ADD FOREIGN KEY([production_center_id])
REFERENCES [dbo].[production_centers] ([production_center_id])
GO
ALTER TABLE [dbo].[returns]  WITH CHECK ADD  CONSTRAINT [FK__returns__custome__3F115E1A] FOREIGN KEY([customer_id])
REFERENCES [dbo].[customers] ([customer_id])
GO
ALTER TABLE [dbo].[returns] CHECK CONSTRAINT [FK__returns__custome__3F115E1A]
GO
ALTER TABLE [dbo].[returns]  WITH CHECK ADD  CONSTRAINT [FK__returns__serial___40058253] FOREIGN KEY([serial_number])
REFERENCES [dbo].[items] ([serial_number])
GO
ALTER TABLE [dbo].[returns] CHECK CONSTRAINT [FK__returns__serial___40058253]
GO
ALTER TABLE [dbo].[returns]  WITH CHECK ADD  CONSTRAINT [FK__returns__store_i__3E1D39E1] FOREIGN KEY([store_id])
REFERENCES [dbo].[stores] ([store_id])
GO
ALTER TABLE [dbo].[returns] CHECK CONSTRAINT [FK__returns__store_i__3E1D39E1]
GO
ALTER TABLE [dbo].[sales]  WITH CHECK ADD  CONSTRAINT [FK__sales__serial_nu__31B762FC] FOREIGN KEY([serial_number])
REFERENCES [dbo].[items] ([serial_number])
GO
ALTER TABLE [dbo].[sales] CHECK CONSTRAINT [FK__sales__serial_nu__31B762FC]
GO
ALTER TABLE [dbo].[sales]  WITH CHECK ADD  CONSTRAINT [FK__sales__store_id__30C33EC3] FOREIGN KEY([store_id])
REFERENCES [dbo].[stores] ([store_id])
GO
ALTER TABLE [dbo].[sales] CHECK CONSTRAINT [FK__sales__store_id__30C33EC3]
GO
ALTER TABLE [dbo].[sales]  WITH CHECK ADD  CONSTRAINT [FK_sales_customer_id] FOREIGN KEY([customer_id])
REFERENCES [dbo].[customers] ([customer_id])
GO
ALTER TABLE [dbo].[sales] CHECK CONSTRAINT [FK_sales_customer_id]
GO
ALTER TABLE [dbo].[shipments_items_junction]  WITH CHECK ADD FOREIGN KEY([serial_number])
REFERENCES [dbo].[items] ([serial_number])
GO
ALTER TABLE [dbo].[shipments_items_junction]  WITH CHECK ADD FOREIGN KEY([shipment_id])
REFERENCES [dbo].[shipments] ([shipment_id])
GO
ALTER TABLE [dbo].[stores]  WITH CHECK ADD  CONSTRAINT [FK__stores__zone_id__49C3F6B7] FOREIGN KEY([zone_id])
REFERENCES [dbo].[zones] ([zone_id])
GO
ALTER TABLE [dbo].[stores] CHECK CONSTRAINT [FK__stores__zone_id__49C3F6B7]
GO
ALTER TABLE [dbo].[sub_distributors]  WITH CHECK ADD  CONSTRAINT [FK__sub_distr__distr__3E52440B] FOREIGN KEY([distributor_id])
REFERENCES [dbo].[distributors] ([distributor_id])
GO
ALTER TABLE [dbo].[sub_distributors] CHECK CONSTRAINT [FK__sub_distr__distr__3E52440B]
GO
ALTER TABLE [dbo].[warehouses]  WITH CHECK ADD  CONSTRAINT [FK__warehouse__distr__398D8EEE] FOREIGN KEY([distributor_id])
REFERENCES [dbo].[distributors] ([distributor_id])
GO
ALTER TABLE [dbo].[warehouses] CHECK CONSTRAINT [FK__warehouse__distr__398D8EEE]
GO
ALTER TABLE [dbo].[warehouses]  WITH CHECK ADD  CONSTRAINT [FK_warehouses_production_center_id] FOREIGN KEY([production_center_id])
REFERENCES [dbo].[production_centers] ([production_center_id])
GO
ALTER TABLE [dbo].[warehouses] CHECK CONSTRAINT [FK_warehouses_production_center_id]
GO
ALTER TABLE [dbo].[zones]  WITH CHECK ADD  CONSTRAINT [FK__zones__channel_p__45F365D3] FOREIGN KEY([channel_partner_id])
REFERENCES [dbo].[channel_partners] ([channel_partner_id])
GO
ALTER TABLE [dbo].[zones] CHECK CONSTRAINT [FK__zones__channel_p__45F365D3]
GO
/****** Object:  StoredProcedure [dbo].[proc_LookDown]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[proc_LookDown] @p_node_key varchar(20)
as
begin
	declare @_node_type nchar(3)
	declare @_node_id int

	set @_node_type = SUBSTRING(@p_node_key, 1, 3)
	set @_node_id = TRY_CAST(SUBSTRING(@p_node_key, 4, 17) AS INT)
	
	IF (@_node_type = 'PC-')
			SELECT warehouse_id as [Warehouse ID], 
				node_key as [Node Key], 
				name as [Warehouse Name], 
				dbo.GetCountry(node_key) as [Country] 
			FROM warehouses 
			WHERE production_center_id = @_node_id
	ELSE IF (@_node_type = 'WH-')
			SELECT d.distributor_id as [Distributor ID], 
				d.node_key as [Node Key], 
				d.name as [Distributor Name], 
				d.country as [Country] 
			FROM warehouses w, distributors d 
			WHERE w.distributor_id = d.distributor_id AND w.warehouse_id = @_node_id
	ELSE IF (@_node_type = 'DI-')
			SELECT sd.sub_distributor_id as [Sub-Distributor ID], 
				sd.node_key as [Node Key], 
				sd.name as [Sub-Distributor Name]
			FROM sub_distributors as sd
			WHERE distributor_id = @_node_id
	ELSE IF (@_node_type = 'SD-')
			SELECT channel_partner_id as [Channel Partner ID],
				node_key as [Node Key],
				name as [Channel Partner Name]
			FROM channel_partners 
			WHERE sub_distributor_id = @_node_id
	ELSE IF (@_node_type = 'CP-')
			SELECT zone_id as [Zone ID],
				node_key as [Node Key],
				name as [Zone Name]
			FROM zones 
			WHERE channel_partner_id = @_node_id
	ELSE IF (@_node_type = 'ZO-')
			SELECT store_id as [Store ID],
				node_key as [Node Key],
				name as [Store Name]
			FROM stores 
			WHERE zone_id = @_node_id
	ELSE
		PRINT 'Invalid node key'
end
GO
/****** Object:  StoredProcedure [dbo].[proc_LookUp]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[proc_LookUp] @p_node_key varchar(20)
as
begin
	declare @_node_type nchar(3)
	declare @_node_id int

	set @_node_type = SUBSTRING(@p_node_key, 1, 3)
	set @_node_id = TRY_CAST(SUBSTRING(@p_node_key, 4, 17) AS INT)
	
	IF (@_node_type = 'ST-')
			SELECT z.zone_id as [Zone ID],
				z.node_key as [Node Key],
				z.name as [Zone Name]
			FROM stores s, zones z 
			WHERE s.store_id = @_node_id and s.zone_id = z.zone_id
	ELSE IF (@_node_type = 'WH-')
			SELECT pc.production_center_id as [Production Center ID],
				pc.node_key as [Node Key],
				pc.name as [Production Center Name],
				pc.country as [Country]
			FROM warehouses w join production_centers pc
			ON w.production_center_id = pc.production_center_id
			WHERE w.warehouse_id = @_node_id
	ELSE IF (@_node_type = 'DI-')
			SELECT wh.warehouse_id as [Warehouse ID],
				wh.node_key as [Node Key],
				wh.name as [Warehouse Name]
			FROM distributors di JOIN warehouses wh
			ON di.distributor_id = wh.distributor_id
			WHERE di.distributor_id = @_node_id
	ELSE IF (@_node_type = 'SD-')
			SELECT di.distributor_id as [Distributor ID],
				di.node_key as [Node Key],
				di.name as [Distributor Name]
			FROM sub_distributors sd JOIN distributors di
			ON sd.distributor_id = di.distributor_id
			WHERE sub_distributor_id = @_node_id
	ELSE IF (@_node_type = 'CP-')
			SELECT sd.sub_distributor_id as [Sub-Distributor ID],
				sd.node_key as [Node Key],
				sd.name as [Sub-Distributor Name]
			FROM channel_partners AS cp JOIN sub_distributors AS sd
			ON cp.sub_distributor_id = sd.sub_distributor_id
			WHERE cp.channel_partner_id = @_node_id
	ELSE IF (@_node_type = 'ZO-')
			SELECT cp.channel_partner_id as [Channel Partner Name],
				cp.node_key as [Node Key],
				cp.name as [Channel Partner Name]
			FROM zones AS zo JOIN channel_partners AS cp
			ON zo.channel_partner_id = cp.channel_partner_id
			WHERE zone_id = @_node_id
	ELSE
		PRINT 'Invalid node key'
end
GO
/****** Object:  StoredProcedure [dbo].[proc_ProduceNewItems]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[proc_ProduceNewItems] @p_production_center_id int, @p_product_id int, @p_quantity int
as
begin
	declare @_run bit = 1

	if not exists (
		select * from production_centers where production_center_id = @p_production_center_id )
	begin
		set @_run = 0
		print 'Production Center not found.';
	end

	if not exists (
		select * from products where product_id = @p_product_id )
	begin
		set @_run = 0
		print 'Product not found.';
	end

	if (@p_quantity <= 0)
	begin
		set @_run = 0
		print 'Please enter a positive quantity'
	end

	if (@_run > 0)
	begin
		declare @_i int = 0

		while @_i < @p_quantity
		begin
			insert into items
			values(
				@p_product_id,
				CONCAT('PC-', CAST(@p_production_center_id as varchar(20))),
				1
				)

			set @_i += 1
		end
	end

end;
GO
/****** Object:  StoredProcedure [dbo].[proc_ReceiveShipment]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[proc_ReceiveShipment] @p_receiver_node_key varchar(13), @p_shipment_id bigint
as
begin
	if ( exists (select * from shipments where shipment_id = @p_shipment_id and destination_node_key = @p_receiver_node_key and delivered = 0) )
		begin
			-- Update the node_key column in the items table to mark the items' new location
			update items
			set node_key = @p_receiver_node_key
			from shipments_items_junction as si
			join items as i
			on si.serial_number = i.serial_number
			where si.shipment_id = @p_shipment_id
			
			-- Insert into the item_history table to log the movement
			insert into item_history
			select GETDATE(), serial_number, @p_receiver_node_key, 'Delivered'
			from shipments_items_junction
			where shipment_id = @p_shipment_id

			-- Update the shipments table to mark that the shipment has been delivered
			update shipments
			set delivered = 1
			where shipment_id = @p_shipment_id
		end
	else
		print 'Invalid input'
end
GO
/****** Object:  StoredProcedure [dbo].[proc_ReturnItem]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[proc_ReturnItem] @p_serial_number bigint, @p_store_id int, @p_reason varchar(150)
as
begin
	DECLARE @_run bit = 1

	IF NOT EXISTS ( SELECT * FROM items WHERE is_new = 0 AND serial_number = @p_serial_number and node_key like 'CU-%')
	BEGIN
		PRINT 'Invalid input'
		SET @_run = 0
	END

	IF NOT EXISTS ( SELECT * FROM stores WHERE store_id = @p_store_id )
	BEGIN
		PRINT 'Store not found'
		SET @_run = 0
	END

	IF (@_run > 0)
	BEGIN
		DECLARE @_customer_id BIGINT
		
		SELECT @_customer_id = CAST(SUBSTRING(node_key, 4, 20) AS BIGINT) FROM items WHERE serial_number = @p_serial_number

		INSERT INTO returns
		VALUES (@p_store_id, @_customer_id, @p_serial_number, @p_reason, GETDATE())

		DECLARE @_node_key VARCHAR(22) = CONCAT('ST-', CAST(@p_store_id AS VARCHAR(10)))

		INSERT INTO item_history
		VALUES (GETDATE(), @p_serial_number, @_node_key, 'Returned')

		UPDATE items
		SET node_key = @_node_key
		WHERE serial_number = @p_serial_number

		
	END
end
GO
/****** Object:  StoredProcedure [dbo].[proc_SellItem]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[proc_SellItem] @p_serial_number bigint, @p_customer_id bigint
as
begin
	declare @_run bit = 1
	if not exists( select * from customers where customer_id = @p_customer_id )
	begin
		print 'Customer not found'
		set @_run = 0
	end

	if not exists( select * from items where serial_number = @p_serial_number and is_new = 1 )
	begin
		print 'Item not found or it has already been sold'
		set @_run = 0
	end

	if (@_run > 0)
	begin
		declare @_customer_node_key varchar(22) = CONCAT('CU-', CAST(@p_customer_id AS VARCHAR(19)))
		declare @_store_id int

		select @_store_id = CAST(SUBSTRING(node_key, 4, 20) as INT)
		from items
		where serial_number = @p_serial_number

		insert into sales
		values(@_store_id, @p_customer_id, @p_serial_number, GETDATE())

		update items
		set node_key = @_customer_node_key, is_new = 0
		where serial_number = @p_serial_number

		insert into item_history
		values (GETDATE(), @p_serial_number, @_customer_node_key, 'Sold')
	end
end;
GO
/****** Object:  StoredProcedure [dbo].[proc_ShipItems]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


 create procedure [dbo].[proc_ShipItems] @p_source_node_key varchar(13), @p_destination_node_key varchar(13), @p_product_id int, @p_quantity int, @p_ship_down bit
 as
 begin

 	/***
	This procedure simulates one node in the supply chain shipping items to another node in the supply chain

	@p_source_node_key : the shipper
	@p_destination_node_key : where the items are being shipped
	@p_product_id : what is being shipped
	@p_quantity : how much is being shipped
	@p_ship_down : is this being shipped down the supply chain?
		1 : shipping down the supply chain
		0 : shipping up the supply chain

	If @p_ship_down is 1 (shipping down) and the source is lower in the supply chain than the destination, the function won't run,
		because a lower node can't ship down to a higher node, it must ship up to a higher node.
	The same is true if @p_ship_down is 0 (shipping up) and the destination is lower than the source.

	***/

	DECLARE @_run BIT = 1
	-- First the procedure will check if the source and destination are connected in the supply chain
	-- The function call will also check for the existence of the nodes
	IF (@p_ship_down = 0)
		BEGIN
			IF (dbo.isConnected(@p_destination_node_key, @p_source_node_key) = 0)
			BEGIN
				SET @_run = 0
				PRINT 'Invalid input: the source or destination may have been entered incorrectly or they are not connected'
			END
		END
	ELSE
		BEGIN
			IF (dbo.isConnected(@p_source_node_key, @p_destination_node_key) = 0)
			BEGIN
				SET @_run = 0
				PRINT 'Invalid input: the source or destination may have been entered incorrectly or they are not connected'
			END
		END

	-- Check if the requested quantity is valid
	-- Will also check if the product ID is valid
	IF (@p_quantity <= 0)
		BEGIN
			SET @_run = 0
			PRINT 'Please enter a positive number for quantity'
		END
	ELSE IF (@p_quantity > ( SELECT count(*) FROM items WHERE node_key = @p_source_node_key AND product_id = @p_product_id AND is_new = @p_ship_down))
		BEGIN
			SET @_run = 0
			PRINT 'Quantity is greater than amount in stock or the product ID was entered incorrectly'
		END

	IF (@_run > 0)
		BEGIN
			-- Store the shipped items in a temporary table
			INSERT INTO items_temporary
			SELECT TOP (@p_quantity) *
			FROM items
			WHERE node_key = @p_source_node_key
				AND product_id = @p_product_id
				AND is_new = @p_ship_down

			-- Log the shipment in the item_history table
			INSERT INTO item_history
			SELECT GETDATE(), it.serial_number, @p_destination_node_key, 'Shipped'
			FROM items_temporary AS it
			
			-- Mark the shipped items as 'In Transit' as they are no longer in any node
			UPDATE items
			SET node_key = 'In Transit'
			FROM items_temporary
			WHERE items.serial_number = items_temporary.serial_number

			-- Declare a table variable to get the identity of the new shipment
			DECLARE @_tbl_id TABLE ( id BIGINT )
			-- Log a new shipment in the shipments table
			INSERT INTO shipments
			OUTPUT inserted.shipment_id
			INTO @_tbl_id
			VALUES (@p_source_node_key, @p_destination_node_key, 0, GETDATE())

			-- Store the new shipment id in a scalar variable
			DECLARE @_shipment_id BIGINT
			SELECT @_shipment_id = MAX(ti.id) FROM @_tbl_id ti

			-- Log the serial numbers of all items in the shipment
			INSERT INTO shipments_items_junction
			SELECT @_shipment_id, serial_number FROM items_temporary


			-- Clear the tempory table
			TRUNCATE TABLE items_temporary
		END




 end
GO
/****** Object:  StoredProcedure [dbo].[ShipItemsDown(DEPRECATED)]    Script Date: 2/4/2021 10:50:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[ShipItemsDown(DEPRECATED)] --@p_source_node_key varchar(30), @p_destination_node_key varchar(30), @p_product_id int, @p_quantity int
as
begin
	/***
	This procedure simulates one node in the supply chain shipping items down to another node in the supply chain

	@p_source_node_key : the shipper
	@p_destination_node_key : where the items are being shipped
	@p_product_id : what is being shipped
	@p_quantity : how much is being shipped

	This procedure ships down so @p_source_node_key must be the node higher in the supply chain
	And @p_destination_node_key must be the node lower in the supply chain
	The function will not run if the nodes are not mapped correctly

	***/
	/***
	declare @_run bit = 1

	-- First the procedure will check if the source and destination are connected in the supply chain
	-- The function call will also check for the existence of the nodes

	if (dbo.isConnected(@p_source_node_key, @p_destination_node_key) = 0)
		begin
			set @_run = 0
			print 'Invalid input: the source or destination may have been entered incorrectly or they are not connected';
		end

	-- Check if the requested quantity is valid
	-- Will also check if the product ID is valid
	if ( @p_quantity <= 0 )
		begin
			set @_run = 0
			print 'Please enter a positive number for quantity';
		end
	else if (@p_quantity > ( select count(*) from items where node_key = @p_source_node_key and product_id = @p_product_id and is_new = 1 ))
		begin
			set @_run = 0
			print 'Quantity is greater than amount in stock or the product ID was entered incorrectly';
		end

	
	if ( @_run > 0 )
		begin
			-- Store the shipped items in a temporary table
			insert into items_temporary
			select top (@p_quantity) *
			from items
			where node_key = @p_source_node_key 
				and product_id = @p_product_id 
				and is_new = 1

			-- Log the shipment in the item_history table
			insert into item_history
			select GETDATE(), it.serial_number, @p_destination_node_key, 'Shipped'
			from items_temporary it

			-- Mark the shipped items as 'In Transit' as they are no longer in any node
			update items
			set node_key = 'In Transit'
			from items_temporary
			where items.serial_number = items_temporary.serial_number

			-- Declare a table variable to get the identity of the new shipment
			declare @_tbl_id table ( id bigint )
			-- Log a new shipment in the shipments table
			insert into shipments
			output inserted.shipment_id
			into @_tbl_id
			values (@p_source_node_key, @p_destination_node_key, 0, GETDATE())

			-- Store the new shipment id in a scalar variable
			declare @_shipment_id bigint
			select @_shipment_id = MAX(ti.id) from @_tbl_id ti

			-- Log the serial numbers of all items in the shipment
			insert into shipments_items_junction
			select @_shipment_id, serial_number from items_temporary


			-- Clear the tempory table
			truncate table items_temporary
		end
		***/
		PRINT 'use ShipItems'
end;
GO
USE [master]
GO
ALTER DATABASE [Project1DB] SET  READ_WRITE 
GO
