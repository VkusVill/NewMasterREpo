CREATE TABLE [dbo].[type_jobs] (
  [job_name] [nchar](50) NOT NULL,
  [max_time] [int] NOT NULL,
  [is_active] [smallint] NOT NULL CONSTRAINT [DF_type_jobs_is_active] DEFAULT (1),
  [parameters] [int] NOT NULL,
  [restart_long_work] [smallint] NOT NULL CONSTRAINT [DF_type_jobs_restart_long_work] DEFAULT (0),
  [restart_err] [smallint] NOT NULL CONSTRAINT [DF_type_jobs_restart_err] DEFAULT (0),
  [kill_disable] [bit] NULL,
  [descr] [varchar](2000) NULL,
  [priority] [smallint] NULL,
  [date_update_tj] [datetime] NULL DEFAULT (getdate()),
  CONSTRAINT [PK_type_jobs] PRIMARY KEY CLUSTERED ([job_name])
)
ON [PRIMARY]
GO