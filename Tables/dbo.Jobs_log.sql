CREATE TABLE [dbo].[Jobs_log] (
  [id_job] [int] NULL,
  [number_step] [bigint] NULL,
  [duration] [int] NULL,
  [date_add] [datetime] NULL CONSTRAINT [DF_Jobs_log_date_add] DEFAULT (getdate()),
  [working_job] [int] NULL,
  [par1] [int] NULL,
  [par2] [int] NULL,
  [par3] [char](50) NULL,
  [par4] [char](50) NULL,
  [id] [bigint] IDENTITY,
  CONSTRAINT [PK_Jobs_log] PRIMARY KEY CLUSTERED ([id])
)
ON [PRIMARY]
GO

CREATE INDEX [ind_parall_1]
  ON [dbo].[Jobs_log] ([id_job], [number_step], [date_add])
  INCLUDE ([par1], [par2], [par3])
  ON [PRIMARY]
GO

CREATE INDEX [IX_Jobs_log]
  ON [dbo].[Jobs_log] ([id_job])
  ON [PRIMARY]
GO

CREATE INDEX [IX_Jobs_log_1]
  ON [dbo].[Jobs_log] ([date_add])
  ON [PRIMARY]
GO