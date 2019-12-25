CREATE TABLE [dbo].[sql_texts_str] (
  [base] [varchar](50) NOT NULL,
  [name] [sysname] NOT NULL,
  [text] [nvarchar](max) NOT NULL,
  [xtype] [char](2) NOT NULL,
  [rn] [int] NOT NULL,
  [rn_2] [int] NOT NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO

CREATE INDEX [IX_sql_texts_str]
  ON [dbo].[sql_texts_str] ([base], [name], [xtype], [rn])
  ON [PRIMARY]
GO

SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [after_insert]
   ON  [dbo].[sql_texts_str] 
   AFTER insert
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  insert into [jobs].[dbo].[arc_sql_texts_str]
      ([base]
      ,[name]
      ,[text]
      ,[xtype]
      ,[rn]
      ,[rn_2])
   select i.[base]
      ,i.[name]
      ,i.[text]
      ,i.[xtype]
      ,i.[rn]
      ,i.[rn_2]
  FROM inserted i
   left join [jobs].[dbo].[arc_sql_texts_str] arc on
   i.base = arc.base and i.name = arc.name and i.xtype = arc.xtype
   and i.rn = arc.rn  and i.rn_2 = arc.rn_2 and rtrim(convert(nvarchar(4000),i.text)) = rtrim(convert(nvarchar(4000),arc.text))
   where arc.base is null
  
  



END
GO