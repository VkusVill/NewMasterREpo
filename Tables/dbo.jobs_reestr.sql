CREATE TABLE [dbo].[jobs_reestr] (
  [id_jr] [int] IDENTITY,
  [is_active] [smallint] NOT NULL,
  [Descr_j_r] [nchar](200) NOT NULL,
  [ProcedureName] [nchar](50) NOT NULL,
  [time_j_r] [time] NOT NULL,
  [r_period_minute] [int] NOT NULL,
  [time_j_p_finish] [time] NOT NULL,
  [weekdays] [nchar](7) NULL,
  [monthdays] [nchar](30) NULL,
  [date_disable] [datetime] NULL,
  [descr_disable] [varchar](1000) NULL,
  [date_add] [datetime] NULL DEFAULT (getdate()),
  CONSTRAINT [PK_jobs_reestr_] PRIMARY KEY CLUSTERED ([ProcedureName])
)
ON [PRIMARY]
GO