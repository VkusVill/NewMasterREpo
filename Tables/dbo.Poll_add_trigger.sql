CREATE TABLE [dbo].[Poll_add_trigger] (
  [telegram_id] [bigint] NOT NULL,
  [number] [char](7) NOT NULL,
  [id_poll] [int] NOT NULL,
  [bot_id] [int] NOT NULL CONSTRAINT [DF_Poll_add_trigger_bot_id] DEFAULT (0),
  [date_add] [datetime] NULL CONSTRAINT [DF_Poll_add_trigger_date_add] DEFAULT (getdate())
)
ON [PRIMARY]
GO