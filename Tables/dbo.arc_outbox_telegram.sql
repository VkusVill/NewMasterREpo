CREATE TABLE [dbo].[arc_outbox_telegram] (
  [id] [bigint] NOT NULL,
  [bot_id] [int] NULL,
  [user_id] [bigint] NULL,
  [incoming_message] [int] NULL,
  [message] [varchar](8000) NULL,
  [keyboard_id] [int] NULL,
  [keyboard_parameter] [varchar](1000) NULL,
  [message_type] [int] NULL,
  [add_date] [datetime] NULL,
  [send_date] [datetime] NULL,
  [CashID] [int] NULL,
  [CashCheckNo] [int] NULL,
  CONSTRAINT [PK_arc_outbox_telegram_ID] PRIMARY KEY CLUSTERED ([id])
)
ON [PRIMARY]
GO

CREATE INDEX [IX_add_date]
  ON [dbo].[arc_outbox_telegram] ([add_date])
  ON [PRIMARY]
GO

CREATE INDEX [IX_arc_outbox_telegram]
  ON [dbo].[arc_outbox_telegram] ([user_id])
  ON [PRIMARY]
GO