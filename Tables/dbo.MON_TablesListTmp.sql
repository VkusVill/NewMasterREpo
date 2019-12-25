CREATE TABLE [dbo].[MON_TablesListTmp] (
  [DBName] [varchar](255) NOT NULL,
  [TableName] [varchar](255) NOT NULL,
  CONSTRAINT [PK_TablesList] PRIMARY KEY CLUSTERED ([DBName], [TableName])
)
ON [PRIMARY]
GO