CREATE TABLE [dbo].[OnlinePaysObmen] (
  [id] [int] IDENTITY,
  [payId] [uniqueidentifier] NULL,
  [orderId] [int] NULL,
  [LineN] [tinyint] NULL DEFAULT (1),
  [id_tov] [int] NULL DEFAULT (0),
  [BaseSum] [money] NULL DEFAULT (0),
  [number] [char](7) NULL,
  [datePay] [datetime] NOT NULL DEFAULT (getdate()),
  [ShopNo] [int] NOT NULL DEFAULT (0),
  [CashId] [int] NOT NULL DEFAULT (0),
  [idproj] [tinyint] NOT NULL DEFAULT (0),
  [ispass] [bit] NOT NULL DEFAULT (0),
  [iserror] [bit] NOT NULL DEFAULT (0)
)
ON [PRIMARY]
GO