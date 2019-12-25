CREATE TABLE [dbo].[Disable_tbl] (
  [id] [int] IDENTITY,
  [Type_disable] [varchar](50) NOT NULL,
  [is_disable] [bit] NOT NULL CONSTRAINT [DF_Disable_tbl_is_disable] DEFAULT (0),
  [date_update] [datetime] NOT NULL CONSTRAINT [DF_Disable_tbl_date_update] DEFAULT (getdate()),
  [max_time_minute] [int] NOT NULL CONSTRAINT [DF_Disable_tbl_max_time_minute] DEFAULT (60),
  CONSTRAINT [PK_Disable_tbl] PRIMARY KEY CLUSTERED ([id])
)
ON [PRIMARY]
GO