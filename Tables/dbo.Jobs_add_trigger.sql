CREATE TABLE [dbo].[Jobs_add_trigger] (
  [id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Jobs_add_trigger_id] DEFAULT (newid()),
  [number] [char](7) NOT NULL,
  [procedure_name] [varchar](100) NOT NULL,
  [param1] [varchar](max) NULL,
  [param2] [int] NULL,
  [date_add] [datetime] NULL CONSTRAINT [DF_Jobs_add_trigger_date_add] DEFAULT (getdate()),
  [id_telegram] [bigint] NULL,
  [server_name] [varchar](50) NULL,
  CONSTRAINT [PK_Jobs_add_trigger] PRIMARY KEY CLUSTERED ([id])
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO

CREATE INDEX [IX_Jobs_add_trigger_1]
  ON [dbo].[Jobs_add_trigger] ([procedure_name])
  ON [PRIMARY]
GO