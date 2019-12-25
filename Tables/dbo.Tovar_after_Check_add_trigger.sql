CREATE TABLE [dbo].[Tovar_after_Check_add_trigger] (
  [rowuid] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Tovar_after_Check_prosess_add_trigger_rowuid] DEFAULT (newsequentialid()),
  [number] [char](7) NOT NULL,
  [cashid] [int] NOT NULL,
  [Checkno] [int] NOT NULL,
  [tov_str] [varchar](max) NOT NULL,
  [id_telegram] [bigint] NOT NULL CONSTRAINT [DF_Tovar_after_Check_prosess_add_trigger_id_telegram] DEFAULT (0),
  [date_add] [datetime] NOT NULL CONSTRAINT [DF_Tovar_after_Check_add_trigger_date_add] DEFAULT (getdate())
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO

CREATE INDEX [IX_Tovar_after_Check_add_trigger]
  ON [dbo].[Tovar_after_Check_add_trigger] ([rowuid], [number])
  ON [PRIMARY]
GO