﻿CREATE TABLE [dbo].[dmexecquerystats] (
  [sql_handle] [varbinary](64) NOT NULL,
  [statement_start_offset] [int] NOT NULL,
  [statement_end_offset] [int] NOT NULL,
  [plan_generation_num] [bigint] NOT NULL,
  [plan_handle] [varbinary](64) NOT NULL,
  [creation_time] [datetime] NOT NULL,
  [last_execution_time] [datetime] NOT NULL,
  [execution_count] [bigint] NOT NULL,
  [total_worker_time] [bigint] NOT NULL,
  [last_worker_time] [bigint] NOT NULL,
  [min_worker_time] [bigint] NOT NULL,
  [max_worker_time] [bigint] NOT NULL,
  [total_physical_reads] [bigint] NOT NULL,
  [last_physical_reads] [bigint] NOT NULL,
  [min_physical_reads] [bigint] NOT NULL,
  [max_physical_reads] [bigint] NOT NULL,
  [total_logical_writes] [bigint] NOT NULL,
  [last_logical_writes] [bigint] NOT NULL,
  [min_logical_writes] [bigint] NOT NULL,
  [max_logical_writes] [bigint] NOT NULL,
  [total_logical_reads] [bigint] NOT NULL,
  [last_logical_reads] [bigint] NOT NULL,
  [min_logical_reads] [bigint] NOT NULL,
  [max_logical_reads] [bigint] NOT NULL,
  [total_clr_time] [bigint] NOT NULL,
  [last_clr_time] [bigint] NOT NULL,
  [min_clr_time] [bigint] NOT NULL,
  [max_clr_time] [bigint] NOT NULL,
  [total_elapsed_time] [bigint] NOT NULL,
  [last_elapsed_time] [bigint] NOT NULL,
  [min_elapsed_time] [bigint] NOT NULL,
  [max_elapsed_time] [bigint] NOT NULL,
  [query_hash] [binary](8) NOT NULL,
  [query_plan_hash] [binary](8) NOT NULL,
  [date_add] [datetime] NOT NULL,
  [execution_count_add] [bigint] NULL,
  [sql_text] [nvarchar](max) NULL,
  [total_worker_time_add] [bigint] NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO