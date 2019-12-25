CREATE TABLE [dbo].[Tables_clear] (
  [rn] [int] IDENTITY,
  [table_del] [nchar](50) NOT NULL,
  [field_date] [nchar](50) NULL,
  [days_stay] [int] NULL,
  [table_from] [nchar](50) NULL,
  [field_del] [nchar](50) NULL,
  [field_from] [nchar](50) NULL,
  [is_1C] [smallint] NOT NULL CONSTRAINT [DF_Tables_clear_is_1C] DEFAULT (0),
  [text_sql] [nvarchar](max) NULL,
  [is_active] [smallint] NULL CONSTRAINT [DF_Tables_clear_is_active] DEFAULT (1),
  [descr] [varchar](max) NULL,
  [date_add] [datetime] NULL CONSTRAINT [DF_Tables_clear_date_add] DEFAULT (getdate()),
  CONSTRAINT [PK_Tables_clear] PRIMARY KEY CLUSTERED ([table_del])
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO