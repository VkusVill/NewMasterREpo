CREATE TABLE [dbo].[MON_TablesRowCountsArhiv] (
  [DBName] [varchar](255) NOT NULL,
  [TableName] [varchar](255) NOT NULL,
  [RowCountCurrentDay] [bigint] NULL,
  [RowCountOldDay1] [bigint] NULL,
  [RowCountOldDay2] [bigint] NULL,
  [RowCountOldDay3] [bigint] NULL,
  [RowCountOldDay4] [bigint] NULL,
  [RowCountOldDay5] [bigint] NULL,
  [RowCountOldDay6] [bigint] NULL,
  [DateLastUpdate] [date] NULL,
  CONSTRAINT [PK_TablesRowCountsArhiv] PRIMARY KEY CLUSTERED ([DBName], [TableName])
)
ON [PRIMARY]
GO