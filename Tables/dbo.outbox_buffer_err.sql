CREATE TABLE [dbo].[outbox_buffer_err] (
  [id] [bigint] NOT NULL,
  [number] [char](11) NULL,
  [cashId] [bigint] NULL,
  [checkNumber] [int] NULL,
  [checkSumm] [decimal](15, 2) NULL,
  [bonusSumm] [decimal](15, 2) NULL,
  [typeMessage] [int] NULL,
  [sendIn] [int] NULL,
  [date_add] [datetime] NULL,
  [tov_str] [nvarchar](max) NULL,
  [discount] [decimal](15, 2) NULL,
  [err_msg] [nvarchar](max) NULL,
  [add_date] [datetime] NULL,
  [act] [varchar](1) NULL,
  PRIMARY KEY NONCLUSTERED ([id])
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO