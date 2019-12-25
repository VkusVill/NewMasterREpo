CREATE TABLE [dbo].[buffer_outbox_mp] (
  [id] [bigint] IDENTITY,
  [oneSignalToken] [varchar](36) NOT NULL DEFAULT (''),
  [Heading_message] [nvarchar](50) NOT NULL DEFAULT (''),
  [Message] [nvarchar](500) NOT NULL DEFAULT (''),
  [Type_message] [int] NOT NULL DEFAULT (0),
  [date_message] [datetime] NOT NULL DEFAULT (getdate()),
  [Data_message] [varchar](1000) NOT NULL DEFAULT (''),
  [number] [char](7) NOT NULL,
  [photo_url] [varchar](300) NULL
)
ON [PRIMARY]
GO

CREATE UNIQUE CLUSTERED INDEX [cl_id]
  ON [dbo].[buffer_outbox_mp] ([id])
  ON [PRIMARY]
GO