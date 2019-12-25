CREATE TABLE [dbo].[Err_Set_LP_trigger] (
  [id_job] [int] NOT NULL,
  [number_step] [bigint] NOT NULL,
  [duration] [int] NULL,
  [date_add] [datetime] NOT NULL,
  [CashID] [int] NULL,
  [CheckNumber] [int] NULL,
  [number] [char](50) NULL,
  [id_tov] [char](50) NULL,
  [MaxOst] [char](50) NULL,
  [rowUID] [varchar](36) NULL CONSTRAINT [DF_Err_Set_LP_trigger_rowUID] DEFAULT (newid())
)
ON [PRIMARY]
GO

CREATE UNIQUE CLUSTERED INDEX [IX_Err_Set_LP_Trigger1]
  ON [dbo].[Err_Set_LP_trigger] ([rowUID])
  ON [PRIMARY]
GO