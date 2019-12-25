CREATE TABLE [dbo].[arc_sql_texts_str] (
  [base] [varchar](50) NOT NULL,
  [name] [sysname] NOT NULL,
  [text] [nvarchar](max) NOT NULL,
  [xtype] [char](2) NOT NULL,
  [rn] [int] NOT NULL,
  [rn_2] [int] NOT NULL,
  [date_add] [datetime] NOT NULL CONSTRAINT [DF_arc_sql_texts_str_date_add] DEFAULT (getdate())
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO

CREATE CLUSTERED INDEX [IX_arc_sql_texts_str]
  ON [dbo].[arc_sql_texts_str] ([base], [name], [xtype], [rn])
  ON [PRIMARY]
GO