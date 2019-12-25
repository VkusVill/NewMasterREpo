CREATE TABLE [dbo].[arc_outbox_mp] (
  [id] [bigint] NOT NULL,
  [oneSignalToken] [varchar](40) NOT NULL,
  [Heading_message] [nvarchar](50) NOT NULL,
  [Message] [nvarchar](500) NOT NULL,
  [Type_message] [int] NOT NULL,
  [date_message] [datetime] NOT NULL,
  [date_send] [datetime] NOT NULL,
  [Data_message] [nvarchar](max) NOT NULL,
  [read_time] [datetime] NULL,
  [number] [char](7) NULL,
  [response] [int] NULL,
  [type_distribusion] [tinyint] NULL,
  [photo_url] [nvarchar](1024) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO

CREATE INDEX [IX_date_mess]
  ON [dbo].[arc_outbox_mp] ([date_message])
  ON [PRIMARY]
GO