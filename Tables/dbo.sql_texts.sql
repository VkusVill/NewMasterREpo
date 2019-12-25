CREATE TABLE [dbo].[sql_texts] (
  [base] [varchar](50) NOT NULL,
  [name] [sysname] NOT NULL,
  [text] [nvarchar](max) NOT NULL,
  [xtype] [char](2) NOT NULL,
  [rn] [int] NOT NULL,
  [table_from] [nchar](100) NOT NULL,
  [crdate] [datetime] NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO

CREATE INDEX [ind1_sql_text]
  ON [dbo].[sql_texts] ([base], [name], [xtype], [rn])
  ON [PRIMARY]
GO

CREATE UNIQUE INDEX [IX_sql_texts]
  ON [dbo].[sql_texts] ([base], [name], [rn])
  ON [PRIMARY]
GO