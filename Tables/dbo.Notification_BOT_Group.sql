CREATE TABLE [dbo].[Notification_BOT_Group] (
  [id_group] [bigint] NOT NULL,
  [Name] [varchar](100) NOT NULL,
  [Descr] [varchar](1000) NOT NULL,
  CONSTRAINT [PK_BOT_Group] PRIMARY KEY CLUSTERED ([id_group])
)
ON [PRIMARY]
GO