CREATE TABLE [dbo].[Jobs] (
  [id_job] [int] IDENTITY,
  [job_name] [nchar](50) NOT NULL,
  [working_job] [int] NULL,
  [date_add] [datetime] NOT NULL CONSTRAINT [DF_Jobs_date_add] DEFAULT (getdate()),
  [date_take] [datetime] NULL,
  [date_exc] [datetime] NULL,
  [type_exec] [smallint] NOT NULL CONSTRAINT [DF_Jobs_type_exec] DEFAULT (1),
  [prefix_job] [char](36) NOT NULL,
  [number_1] [int] NULL,
  [number_2] [int] NULL,
  [number_3] [int] NULL,
  [job_init] [int] NULL,
  [threads] [int] NULL
)
ON [PRIMARY]
GO

CREATE INDEX [ind_4]
  ON [dbo].[Jobs] ([date_take], [date_exc])
  INCLUDE ([job_name], [prefix_job])
  ON [PRIMARY]
GO

CREATE INDEX [ind1]
  ON [dbo].[Jobs] ([working_job], [date_take])
  INCLUDE ([id_job], [job_name], [prefix_job])
  ON [PRIMARY]
GO

CREATE UNIQUE INDEX [ind2]
  ON [dbo].[Jobs] ([id_job])
  INCLUDE ([working_job], [date_take], [prefix_job], [number_1], [number_2], [number_3], [job_name], [date_exc])
  ON [PRIMARY]
GO

CREATE CLUSTERED INDEX [pk_jobs]
  ON [dbo].[Jobs] ([working_job], [date_take], [id_job])
  ON [PRIMARY]
GO

SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create TRIGGER [del_jobs]
   ON  [dbo].[Jobs] 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

insert into  [jobs].[dbo].[arc_Jobs]
([id_job]
      ,[job_name]
      ,[working_job]
      ,[date_add]
      ,[date_take]
      ,[date_exc]
      ,[type_exec]
      ,[prefix_job]
      ,[number_1]
      ,[number_2]
      ,[number_3]
      ,[job_init]
      ,[threads])
SELECT [id_job]
      ,[job_name]
      ,[working_job]
      ,[date_add]
      ,[date_take]
      ,[date_exc]
      ,[type_exec]
      ,[prefix_job]
      ,[number_1]
      ,[number_2]
      ,[number_3]
      ,[job_init]
      ,[threads]
      
  FROM deleted

END
GO