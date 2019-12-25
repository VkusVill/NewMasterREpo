CREATE TABLE [dbo].[indexes_texts] (
  [base_name] [nvarchar](100) NOT NULL,
  [name_index] [nvarchar](100) NULL,
  [object_id] [int] NOT NULL,
  [name_table] [nvarchar](100) NOT NULL,
  [sql_text] [nvarchar](max) NULL,
  [date_add] [datetime] NOT NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO