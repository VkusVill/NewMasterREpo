SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		SHEP /Шевченко Павел/
-- Create date: 22.02.2019
-- Description:	ИП-00017103.12. Выводим товар из ассортимента
-- =============================================
CREATE PROCEDURE [dbo].[exclude_assortiment_tov_tt] @id_tov int
, @id_tt int
, @text varchar(64) = 'exclude_зак_покуп'

AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE	@id_job AS int = 100350,
			@job_name varchar(100) = com.dbo.object_name_for_err(@@Procid,DB_ID())

	--Declare @id_tov int = 24758,@id_tt int = 10899,@text char(16) = 'Вывод тест' 


	BEGIN TRY
		
		DECLARE @Период datetime
				, @Выведена int
				, @Характеристика binary(16)
		DECLARE @getdate datetime = DATEADD(YEAR, 2000, GETDATE())
		DECLARE @curdate date = CAST(@getdate AS date)

		SELECT
			@Период = a.Период,
			@Выведена = a.Выведена,
			@Характеристика = a.Характеристика
		FROM (SELECT TOP 1 WITH TIES
				_Period Период,
				_Fld3961 Выведена,
				_Fld3960RRef Характеристика
			FROM IzbenkaFin.dbo._InfoRg3957 AS Tov_Assortiment (NOLOCK)
			WHERE Tov_Assortiment.id_tt_1C = @id_tt
				AND Tov_Assortiment.id_tov_1C = @id_tov
				AND Tov_Assortiment._Period <= @getdate

			ORDER BY ROW_NUMBER() OVER (
				PARTITION BY Tov_Assortiment.id_tov_1C, Tov_Assortiment.id_tt_1C
				ORDER BY Tov_Assortiment._Period DESC, _Fld3961)
		) a

		IF ISNULL(@Выведена, 1) = 0

		BEGIN

			IF OBJECT_ID('tempdb..#add_tovar2') IS NOT NULL	DROP TABLE #add_tovar2
			CREATE TABLE #add_tovar2 (
				id_tt int,
				id_tov int,
				tt_ref binary(16),
				tov_ref binary(16)
			)
			TRUNCATE TABLE #add_tovar2

			INSERT INTO #add_tovar2 (id_tt, id_tov, tt_ref, tov_ref)
				SELECT 
					tt.id_TT,
					t.id_tov,
					tt.Ref,
					t.Ref
				FROM M2..Tovari t
				INNER JOIN M2..tt
					ON tt.id_TT = @id_tt
				WHERE t.id_tov = @id_tov

			-- выводим из ассортимента
			IF @Период = @curdate
				UPDATE TovAss
				SET
					_Fld3961 = 1 -- Выведена
					, _Fld6585 = @getdate -- ДатаСозданияЗаписи
					, _Fld7604 = @text -- Комментарий
					, _Fld7150RRef = 0xA520001FC68B8D1311E0DCA7C7689DB3 -- Автор
				FROM IzbenkaFin.dbo._InfoRg3957 TovAss WITH (ROWLOCK)
					INNER JOIN #add_tovar2 addt
					ON TovAss._Period = @curdate
						AND TovAss._Fld3958RRef = addt.tt_ref
						AND TovAss._Fld3959RRef = addt.tov_ref
				

			ELSE
				INSERT INTO IzbenkaFin.dbo._InfoRg3957 ([_Period]
				, [_Fld3958RRef]
				, [_Fld3959RRef]
				, [_Fld3960RRef]
				, [_Fld3961]
				, [_Fld6975]
				, [_Fld7283]
				, [_Fld6585]
				, [_Fld7150RRef]
				, [_Fld7604]
				, [_Fld9556]
				, [_Fld17345])
					SELECT distinct
						@curdate,
						a.tt_ref,
						a.tov_ref,
						@Характеристика,
						1,
						0,
						a.id_tt,
						@getdate,
						0xA520001FC68B8D1311E0DCA7C7689DB3,
						@text,
						0,
						0
					FROM #add_tovar2 a
			
		END

	END TRY
	BEGIN CATCH
		INSERT INTO jobs..error_jobs (id_job, job_name, number_step, date_add, message)
			SELECT
				@id_job,
				@job_name,
				100,
				GETDATE(),
				'@id_tt=' + rtrim(@id_tt) + ',@id_tov=' + rtrim(@id_tov) + ':' +ERROR_MESSAGE()
	END CATCH
END
GO