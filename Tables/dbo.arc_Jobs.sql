CREATE TABLE [dbo].[arc_Jobs] (
  [id_job] [int] NOT NULL,
  [job_name] [nchar](50) NOT NULL,
  [working_job] [int] NULL,
  [date_add] [datetime] NOT NULL,
  [date_take] [datetime] NULL,
  [date_exc] [datetime] NULL,
  [type_exec] [smallint] NOT NULL,
  [prefix_job] [char](36) NOT NULL,
  [number_1] [int] NULL,
  [number_2] [int] NULL,
  [number_3] [int] NULL,
  [job_init] [int] NULL,
  [threads] [int] NULL,
  CONSTRAINT [PK_arc_Jobs] PRIMARY KEY CLUSTERED ([id_job])
)
ON [PRIMARY]
GO