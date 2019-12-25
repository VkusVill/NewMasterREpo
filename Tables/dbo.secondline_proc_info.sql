CREATE TABLE [dbo].[secondline_proc_info] (
  [id_job] [int] NULL,
  [proc_name] [varchar](100) NULL,
  [proc_info] [varchar](500) NULL,
  CONSTRAINT [UC_secondline_proc_info] UNIQUE ([id_job])
)
ON [PRIMARY]
GO