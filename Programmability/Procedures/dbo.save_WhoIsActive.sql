SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[save_WhoIsActive]  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DECLARE @s nVARCHAR(4000) , @temp_table char(36),  @temp_table_2 char(36)


select @temp_table= replace(convert(char(36),NEWID()) , '-' , '_')
select @temp_table_2= replace(convert(char(36),NEWID()) , '-' , '_')
 
EXEC [master].dbo.sp_WhoIsActive 
	@format_output = 0, 
	@return_schema = 1, 
	@schema = @s OUTPUT
 
SET @s = REPLACE(@s, '<table_name>', 'Temp_tables.dbo.[' + @temp_table + ']')

exec ( 'create table Temp_tables.dbo.[' + @temp_table_2 + '] ([dd hh:mm:ss.mss] [varchar](8000) NULL,
	                        [session_id] [smallint] NOT NULL, [start_time] datetime )')

--print @temp_table_2
--print @s
EXEC(@s) 

Set @s = '
EXEC [master].dbo.sp_WhoIsActive 
@DESTINATION_TABLE = ''Temp_tables.dbo.[' + @temp_table_2 +']'',
@output_column_list = ''[dd hh:mm:ss.mss],[session_id],[start_time] ''
      
EXEC [master].dbo.sp_WhoIsActive @format_output = 0,
@DESTINATION_TABLE = ''Temp_tables.dbo.[' + @temp_table + ']'';
'
--print  @S

EXEC sp_executeSQL @s

Set @s = '
insert into vv03..WhoIsActive
SELECT   w1.collection_time,  w2.[dd hh:mm:ss.mss], w1.session_id, w1.sql_text, w1.login_name, w1.wait_info, w1.CPU, w1.tempdb_allocations, w1.tempdb_current, w1.blocking_session_id, 
                      w1.reads, w1.writes, w1.physical_reads, w1.used_memory, w1.status, w1.open_tran_count, w1.percent_complete, w1.host_name, w1.database_name, 
                      w1.program_name, w1.start_time, w1.login_time, w1.request_id
FROM         Temp_tables.dbo.[' + @temp_table + '] AS w1 INNER JOIN
                      Temp_tables.dbo.[' + @temp_table_2 + '] AS w2 ON w1.session_id = w2.session_id and w1.start_time = w2.start_time

drop table Temp_tables.dbo.[' + @temp_table + ']
drop table Temp_tables.dbo.[' + @temp_table_2 + ']
'                      
EXEC sp_executeSQL @s                      



 
END
GO