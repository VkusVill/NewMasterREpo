CREATE TABLE [dbo].[arc_inbox_telegram] (
  [id] [bigint] NOT NULL,
  [bot_id] [int] NULL,
  [update_id] [bigint] NULL,
  [message_id] [bigint] NULL,
  [user_id] [bigint] NULL,
  [message_text] [nvarchar](4000) NULL,
  [received_date] [datetime] NULL,
  [answer] [int] NULL
)
ON [PRIMARY]
GO

CREATE INDEX [IX_arc_inbox_telegram]
  ON [dbo].[arc_inbox_telegram] ([user_id])
  ON [PRIMARY]
GO

CREATE INDEX [IX_received_date]
  ON [dbo].[arc_inbox_telegram] ([received_date])
  ON [PRIMARY]
GO