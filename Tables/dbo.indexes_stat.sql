CREATE TABLE [dbo].[indexes_stat] (
  [base name] [nvarchar](128) NOT NULL,
  [OBJECT NAME] [nvarchar](128) NOT NULL,
  [INDEX NAME] [nvarchar](128) NULL,
  [USER_SEEKS] [bigint] NOT NULL,
  [USER_SCANS] [bigint] NOT NULL,
  [USER_LOOKUPS] [bigint] NOT NULL,
  [USER_UPDATES] [bigint] NOT NULL,
  [Add_SEEKS] [bigint] NULL,
  [date_add] [datetime] NOT NULL,
  [add_USER_LOOKUPS] [bigint] NULL
)
ON [PRIMARY]
GO

CREATE INDEX [ind1_is]
  ON [dbo].[indexes_stat] ([base name], [OBJECT NAME], [INDEX NAME], [date_add] DESC)
  INCLUDE ([USER_SEEKS])
  ON [PRIMARY]
GO