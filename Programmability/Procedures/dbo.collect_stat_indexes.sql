SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[collect_stat_indexes]
	-- Add the parameters for the stored procedure here
@id_job int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @getdate datetime = getdate()

SELECT name 
into #name 
FROM sys.sysdatabases (nolock)
where name <> 'tempdb'
and rtrim(isnull(name,''))<>''

Declare @base as char(50) , @s as nvarchar(max)


DECLARE crs CURSOR LOCAL FOR
 
SELECT name 
FROM #name

 OPEN crs
 FETCH crs INTO @base
	
 WHILE NOT @@fetch_status = -1 
	BEGIN

insert into jobs..Jobs_log ([id_job],[number_step],[duration] , par3) 
select @id_job , 1, DATEDIFF(MILLISECOND , @getdate ,GETDATE()) , @base
select @getdate = getdate()


select @s  = 'use  [' + RTRIM(@base) + 
'] ; 

insert into jobs..indexes_stat
       ([base name]
      ,[OBJECT NAME]
      ,[INDEX NAME]
      ,[USER_SEEKS]
      ,[USER_SCANS]
      ,[USER_LOOKUPS]
      ,[USER_UPDATES]
      ,[Add_SEEKS]
      ,[add_USER_LOOKUPS]
      ,[date_add] )
select 
a.[base name],
a.[OBJECT NAME] , 
a.[INDEX NAME] ,
a.user_seeks , 
a.user_scans , 
a.user_lookups ,
a.user_updates ,
case when a.user_seeks >= isnull(i.USER_SEEKS,0) then a.user_seeks - isnull(i.USER_SEEKS,0) 
else a.user_seeks end Add_SEEKS,
case when a.USER_LOOKUPS >= isnull(i.USER_LOOKUPS,0) then a.USER_LOOKUPS - isnull(i.USER_LOOKUPS,0) 
else a.USER_LOOKUPS end USER_LOOKUPS,
GETDATE() date_add
from (SELECT   
         '''+ RTRIM(@base) +'''  [base name] ,
         OBJECT_NAME(S.[OBJECT_ID]) AS [OBJECT NAME], 
         I.[NAME] AS [INDEX NAME], 
         USER_SEEKS, 
         USER_SCANS, 
         USER_LOOKUPS, 
         USER_UPDATES 
FROM     SYS.DM_DB_INDEX_USAGE_STATS AS S 
         INNER JOIN SYS.INDEXES AS I (nolock)
           ON I.[OBJECT_ID] = S.[OBJECT_ID] 
              AND I.INDEX_ID = S.INDEX_ID
              inner join sys.sysdatabases (nolock) b on b.dbid = s.database_id
              and b.name = '''+ RTRIM(@base) +'''  
WHERE    OBJECTPROPERTY(S.[OBJECT_ID],''IsUserTable'') = 1 
) a
left join 
(select i.[base name] , i.[OBJECT NAME] , i.[INDEX NAME] , i.USER_SEEKS, i.USER_LOOKUPS ,
ROW_NUMBER() over ( PARTITION by i.[base name] , i.[OBJECT NAME] , i.[INDEX NAME] order by i.date_add desc) rn
from jobs..indexes_stat i (nolock)  
) i on a.[base name] = i.[base name]
and a.[OBJECT NAME] = i.[OBJECT NAME] 
and isnull(a.[INDEX NAME],''NULL'') = isnull(i.[INDEX NAME],''NULL'')
and i.rn=1
'

--print @S
EXEC sp_executesql @S








    FETCH NEXT FROM crs INTO @base
 END

CLOSE crs
 


DECLARE crs1 CURSOR LOCAL FOR
 
SELECT name 
from #name

 OPEN crs1
 FETCH crs1 INTO @base
	
 WHILE NOT @@fetch_status = -1 
	BEGIN


select @s  = 'use  [' + RTRIM(@base) + 
'] ; 

insert into jobs..indexes_texts
SELECT 
''' + RTRIM(@base) + ''' base_name ,i.name name_index, i.object_id ,c.name  name_table,
''CREATE '' +
     CASE WHEN i.is_unique = 1 
        THEN ''UNIQUE '' 
        ELSE '' '' 
    END +     
    CASE WHEN i.index_id = 1 
        THEN ''CLUSTERED'' 
        ELSE ''NONCLUSTERED'' 
    END +'' INDEX '' +  RTRIM( i.name) +  ''  on ''  + RTRIM(c.name) + ''
    ('' + (
    SELECT STUFF(CAST((
        SELECT '', ['' + COL_NAME(ic.[object_id], ic.column_id) + '']'' +
                CASE WHEN ic.is_descending_key = 1
                    THEN '' DESC''
                    ELSE ''''
                END
        FROM sys.index_columns ic WITH(NOLOCK)
        WHERE i.[object_id] = ic.[object_id]
            AND i.index_id = ic.index_id
            and ic.is_included_column = 0
        order by ic.index_column_id   
        FOR XML PATH(N''''), TYPE) AS NVARCHAR(MAX)), 1, 2, '''')
  
        ) + '')''
        
        + ISNULL( 
        ''
    INCLUDE 
    ('' + (
    SELECT STUFF(CAST((
        SELECT '', ['' + COL_NAME(ic.[object_id], ic.column_id) + '']'' +
                CASE WHEN ic.is_descending_key = 1
                    THEN '' DESC''
                    ELSE ''''
                END
        FROM sys.index_columns ic WITH(NOLOCK)
        WHERE i.[object_id] = ic.[object_id]
            AND i.index_id = ic.index_id
            and ic.is_included_column = 1
        order by ic.index_column_id
        FOR XML PATH(N''''), TYPE) AS NVARCHAR(MAX)), 1, 2, '''')
  
        ) + '')'' , '''') sql_text ,
        GETDATE() date_add
        
    FROM sys.indexes i WITH(NOLOCK)
    inner join sys.objects c (nolock) on i.object_id = c.object_id
     where c.type_desc = ''USER_TABLE''


  '

--print @S
EXEC sp_executesql @S



    FETCH NEXT FROM crs1 INTO @base
 END

CLOSE crs1


drop table #name


insert into jobs..dmexecquerystats
([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time]
,[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads]
,[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes]
,[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time]
,[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash]
,[date_add],[execution_count_add],[sql_text],[total_worker_time_add])
select top 100 qs.sql_handle,qs.statement_start_offset,qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time]
,qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads]
,qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes]
,qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time]
,qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash] 
, getdate() date_add , 
case when qs.execution_count >= ISNULL(e.execution_count ,0 ) 
	then qs.execution_count - ISNULL(e.execution_count ,0 ) else qs.execution_count end [execution_count_add]
 , st.text [sql_text]
 ,  case when qs.total_worker_time >= ISNULL(e.total_worker_time ,0 ) 
	then qs.total_worker_time - ISNULL(e.total_worker_time ,0 ) else qs.total_worker_time end [total_worker_time_add]
from
sys.dm_exec_query_stats (nolock)qs
cross apply sys.dm_exec_sql_text   (qs.sql_handle)  st
left join 

(select * , 
ROW_NUMBER() over (PARTITIOn by sql_handle , statement_end_offset, statement_start_offset,
e.plan_handle order by date_add desc) rn
from jobs..dmexecquerystats e ) e
on qs.sql_handle = e.sql_handle
and qs.statement_end_offset =  e.statement_end_offset
and qs.statement_start_offset =  e.statement_start_offset
and qs.plan_handle = e.plan_handle
and e.rn=1
order by case when qs.total_worker_time >= ISNULL(e.total_worker_time ,0 ) then qs.total_worker_time - ISNULL(e.total_worker_time ,0 ) else qs.total_worker_time end desc


 
END
GO