SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE VIEW [dbo].[WhoIsActive]
AS
SELECT     w2.[dd hh:mm:ss.mss], w1.session_id, w1.sql_text, w1.login_name, w1.wait_info, w1.CPU, w1.tempdb_allocations, w1.tempdb_current, w1.blocking_session_id, 
                      w1.reads, w1.writes, w1.physical_reads, w1.used_memory, w1.status, w1.open_tran_count, w1.percent_complete, w1.host_name, w1.database_name, 
                      w1.program_name, w1.start_time, w1.login_time, w1.request_id, w1.collection_time
FROM         dbo.WhoIsActive_1 AS w1 INNER JOIN
                      dbo.WhoIsActive_2 AS w2 ON w1.session_id = w2.session_id AND w1.start_time = w2.start_time




GO