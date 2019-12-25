CREATE TABLE [dbo].[Jobs_Procedure] (
  [id_job] [int] NOT NULL,
  [Proc_name] [varchar](50) NOT NULL,
  [Description] [varchar](1500) NOT NULL CONSTRAINT [DF_Jobs_Procedure_Description] DEFAULT (''),
  [date_add] [datetime] NOT NULL CONSTRAINT [DF_Jobs_Procedure_date_add] DEFAULT (getdate()),
  CONSTRAINT [UC_Jobs_Procedure] UNIQUE ([id_job])
)
ON [PRIMARY]
GO