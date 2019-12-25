CREATE TABLE [dbo].[outbox_buffer] (
  [id] [bigint] IDENTITY,
  [number] [char](11) NOT NULL,
  [cashId] [bigint] NULL,
  [checkNumber] [int] NULL,
  [checkSumm] [decimal](15, 2) NULL,
  [bonusSumm] [decimal](15, 2) NULL,
  [typeMessage] [int] NOT NULL,
  [sendIn] [int] NULL,
  [date_add] [datetime] NULL DEFAULT (getdate()),
  [tov_str] [nvarchar](max) NULL,
  [discount] [decimal](15, 2) NULL,
  PRIMARY KEY NONCLUSTERED ([id])
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO

EXEC sys.sp_addextendedproperty N'MS_Description', N'KasM 09-05-2019 передаваемый список товаров', 'SCHEMA', N'dbo', 'TABLE', N'outbox_buffer', 'COLUMN', N'tov_str'
GO

EXEC sys.sp_addextendedproperty N'MS_Description', N'KasM 09-05-2019 передаваемая скидка', 'SCHEMA', N'dbo', 'TABLE', N'outbox_buffer', 'COLUMN', N'discount'
GO