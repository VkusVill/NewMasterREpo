CREATE TABLE [dbo].[Charge_Bonus_Card_add_trigger] (
  [row_UID] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Charge_Bonus_Card_add_trigger_row_UID] DEFAULT (newsequentialid()),
  [number] [char](7) NOT NULL,
  [bonus_value] [decimal](15, 2) NOT NULL,
  [user_name] [varchar](50) NOT NULL,
  [descr] [varchar](1000) NOT NULL,
  [type_] [int] NOT NULL CONSTRAINT [DF_Charge_Bonus_Card_add_trigger_type_] DEFAULT (1),
  [date_add] [datetime] NOT NULL CONSTRAINT [DF_Charge_Bonus_Card_add_trigger_date_add] DEFAULT (getdate()),
  [source_id] [int] NULL,
  CONSTRAINT [PK_Charge_Bonus_Card_add_trigger] PRIMARY KEY CLUSTERED ([row_UID])
)
ON [PRIMARY]
GO