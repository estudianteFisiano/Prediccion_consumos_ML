----------------------------------
--------DECLARAR VARIABLES--------
----------------------------------
	
	DECLARE @um VARCHAR(6)
	DECLARE @m1 VARCHAR(6)
	DECLARE @u1m VARCHAR(6)
	DECLARE @u2m VARCHAR(6)
	DECLARE @u3m VARCHAR(6)
	DECLARE @u4m VARCHAR(6)
	DECLARE @u5m VARCHAR(6)
	DECLARE @u6m VARCHAR(6)
	DECLARE @u7m VARCHAR(6)
	DECLARE @u8m VARCHAR(6)
	DECLARE @u9m VARCHAR(6)
	DECLARE @u10m VARCHAR(6)
	DECLARE @u11m VARCHAR(6)
	DECLARE @u12m VARCHAR(6)
	DECLARE @u13m VARCHAR(6)
	DECLARE @u24m VARCHAR(6)
	DECLARE @u25m VARCHAR(6)

----------  COLOCAR EN @um EL PERIODO A PREDECIR-------
		SET @um = '202410'
-------------------------------------------------------
	SET @m1 = CONVERT(VARCHAR(6), DATEADD(MONTH, +1, CAST(@um + '01' AS DATE)), 112)
	SET @u1m = CONVERT(VARCHAR(6), DATEADD(MONTH, -1, CAST(@um + '01' AS DATE)), 112)
	SET @u2m = CONVERT(VARCHAR(6), DATEADD(MONTH, -2, CAST(@um + '01' AS DATE)), 112)
	SET @u3m = CONVERT(VARCHAR(6), DATEADD(MONTH, -3, CAST(@u1m + '01' AS DATE)), 112)
	SET @u4m = CONVERT(VARCHAR(6), DATEADD(MONTH, -4, CAST(@u1m + '01' AS DATE)), 112)
	SET @u5m = CONVERT(VARCHAR(6), DATEADD(MONTH, -5, CAST(@u1m + '01' AS DATE)), 112)
	SET @u6m = CONVERT(VARCHAR(6), DATEADD(MONTH, -6, CAST(@u1m + '01' AS DATE)), 112)
	SET @u7m = CONVERT(VARCHAR(6), DATEADD(MONTH, -7, CAST(@u1m + '01' AS DATE)), 112)
	SET @u8m = CONVERT(VARCHAR(6), DATEADD(MONTH, -8, CAST(@u1m + '01' AS DATE)), 112)
	SET @u9m = CONVERT(VARCHAR(6), DATEADD(MONTH, -9, CAST(@u1m + '01' AS DATE)), 112)
	SET @u10m = CONVERT(VARCHAR(6), DATEADD(MONTH, -10, CAST(@u1m + '01' AS DATE)), 112)
	SET @u11m = CONVERT(VARCHAR(6), DATEADD(MONTH, -11, CAST(@u1m + '01' AS DATE)), 112)
	SET @u12m = CONVERT(VARCHAR(6), DATEADD(MONTH, -12, CAST(@u1m + '01' AS DATE)), 112)
	SET @u13m = CONVERT(VARCHAR(6), DATEADD(MONTH, -13, CAST(@u1m + '01' AS DATE)), 112)
	SET @u24m = CONVERT(VARCHAR(6), DATEADD(MONTH, -14, CAST(@u1m + '01' AS DATE)), 112)
	SET @u25m = CONVERT(VARCHAR(6), DATEADD(MONTH, -15, CAST(@u1m + '01' AS DATE)), 112)

--===================================================================
------------------ DATOS DEL CLIENTE -----------------
--===================================================================

select A.LLAVE,B.LINEACREDITO,A.EDAD,A.DEPARTAMENTO_RENIEC
,A.SITUACIONLABORAL,A.NSE,B.DiasMora,B.NombreTipoTarjeta,NombreSituacionCliente
into #datos_cliente
from PRODUCTION..CLIENTES_CONTACTO a
inner join PRODUCTION..CLIENTE_TC b ON a.llave=b.llave



--===================================================================
-------------------PARA SABER CONSUMOS PASADOS-----------
--===================================================================

	--Consumo cliente titular
	
	IF OBJECT_ID('tempdb..#ConsumoTC') IS NOT NULL
		DROP TABLE #ConsumoTC;
	SELECT
		CASE	WHEN a.llave IS NOT NULL THEN a.llave
				WHEN len(a.NroDocumento)=8 THEN 'E-'+a.NroDocumento
				WHEN len(a.NroDocumento)=9 THEN 'X-'+a.NroDocumento
				ELSE NULL END
		AS llave,
		PeriodoCompra,
		Retail,
		Flag_Cat,
		Agrupacion as RUBRO,
		SUM(monto) AS monto,
		count(1) AS trx
	INTO #ConsumoTC
	FROM PRODUCTION.DBO.CONSUMOS_CREDITO A WITH (NOLOCK)
	INNER JOIN (SELECT LLAVE, CuentaTC FROM PRODUCTION..CLIENTE_TC WHERE FLAGULTIMARATIFICACION = '1') B ON A.CuentaTC=B.CuentaTC
	LEFT JOIN PRODUCTION..CATOLOGO_RUBRO c on a.AgrupacionConvenio=c.MCG
	WHERE Periodo BETWEEN @u13m AND @m1
		AND PeriodoCompra BETWEEN @u12m AND @um
		AND a.FlagTitularAdic='0'
		AND Flag_Cuotificacion IN (0,1)
		AND monto>=0
	GROUP BY
		CASE	WHEN a.llave IS NOT NULL THEN a.llave
				WHEN len(a.NroDocumento)=8 THEN 'E-'+a.NroDocumento
				WHEN len(a.NroDocumento)=9 THEN 'X-'+a.NroDocumento
				ELSE NULL END,
		PeriodoCompra,
		Retail,
		Flag_Cat,
		Agrupacion;
	
	
	--Consumo cliente adicional
	
	IF OBJECT_ID('tempdb..#ConsumoADI') IS NOT NULL
		DROP TABLE #ConsumoADI;
	SELECT
		CASE	WHEN a.LlaveAdic IS NOT NULL THEN a.LlaveAdic
				WHEN len(a.NroDocumento)=8 THEN 'E-'+a.NroDocumento
				WHEN len(a.NroDocumento)=9 THEN 'X-'+a.NroDocumento
				ELSE NULL END
		AS llave,
		PeriodoCompra,
		Retail,
		Flag_Cat,
		c.Agrupacion as RUBRO,
		SUM(monto) AS monto,
		count(1) AS trx
	INTO #ConsumoADI
	FROM PRODUCTION.DBO.CONSUMOS_CREDITO a WITH (NOLOCK) 
	LEFT JOIN PRODUCTION..CATOLOGO_RUBRO c on a.AgrupacionConvenio=c.MCG
	WHERE Periodo BETWEEN @u13m AND @m1 
		AND PeriodoCompra BETWEEN @u12m AND @um
		AND a.FlagTitularAdic='1' 
		AND Flag_Cuotificacion IN (0,1)
		AND monto>=0
	GROUP BY
		CASE	WHEN a.LlaveAdic IS NOT NULL THEN a.LlaveAdic
				WHEN len(a.NroDocumento)=8 THEN 'E-'+a.NroDocumento
				WHEN len(a.NroDocumento)=9 THEN 'X-'+a.NroDocumento
				ELSE NULL END,
		PeriodoCompra,
		Retail,
		Flag_Cat,
		c.Agrupacion;

--------------------------------
------------UNION---------------
--------------------------------

	IF OBJECT_ID('tempdb..#unionconsumos') IS NOT NULL
		DROP TABLE #unionconsumos;
	
SELECT T.llave,T.PeriodoCompra,T.Retail,T.Flag_Cat,T.RUBRO,T.RUBRO_FINAL,T.monto,T.trx,
DATEDIFF(MONTH,LAG(convert(date,PeriodoCompra+'01',112)) OVER(PARTITION BY llave,RUBRO_FINAL order by convert(date,PeriodoCompra+'01',112)),convert(date,PeriodoCompra+'01',112)) as meses_entre_consumos_rubro,
DATEDIFF(MONTH,LAG(convert(date,PeriodoCompra+'01',112)) OVER(PARTITION BY llave,Retail order by convert(date,PeriodoCompra+'01',112)),convert(date,PeriodoCompra+'01',112)) as meses_entre_consumos_retail,
DATEDIFF(MONTH,LAG(convert(date,PeriodoCompra+'01',112)) OVER(PARTITION BY llave order by convert(date,PeriodoCompra+'01',112)),convert(date,PeriodoCompra+'01',112)) as meses_entre_consumos
into #unionconsumos
FROM(
	SELECT Llave, PeriodoCompra, Retail, Flag_Cat,RUBRO,
	CASE	WHEN Retail IN ('TOTTUS','SAGA','FAZIL','MAESTRO','SODIMAC','HIPERBODEGA') OR RUBRO = 'Supermercados' THEN 'Supermercados'
			ELSE RUBRO 
	END as RUBRO_FINAL
	, SUM(monto) AS monto, SUM(trx) AS trx
	FROM
	(
		SELECT Llave, PeriodoCompra, Retail, Flag_Cat,RUBRO, monto, trx
		FROM #ConsumoTC
		UNION ALL
		SELECT Llave, PeriodoCompra, Retail, Flag_Cat,RUBRO, monto, trx
		FROM #ConsumoADI

	) AS UnionTables
	where UnionTables.llave is not null
	GROUP BY Llave, PeriodoCompra, Retail, Flag_Cat, RUBRO
) as T

--------------------------------
------------RESULTADO FINAL---------
--------------------------------

	SELECT 
		A.Llave,A.LINEACREDITO,A.EDAD,A.DEPARTAMENTO_RENIEC,A.SITUACIONLABORAL,A.NSE,A.DiasMora,A.NombreTipoTarjeta,A.NombreSituacionCliente
		ROUND(AVG(case when PeriodoCompra<@um THEN CAST(meses_entre_consumos as float) END),2) as meses_entre_consumos,
		'' as meses_entre_consumos_categorizado,

------------------------------------------------------------------------------------------------------------------------
		--SALUD (RECURRENTE)
		MAX(CASE WHEN PeriodoCompra = @u1m AND RUBRO_FINAL = 'Salud' THEN 1 ELSE 0 END) AS consumio_h1m_SALUD,
		SUM(CASE WHEN PeriodoCompra = @u1m AND RUBRO_FINAL = 'Salud' THEN monto ELSE 0 END) AS monto_consum_h1m_SALUD,
		SUM(CASE WHEN PeriodoCompra =@u1m AND RUBRO_FINAL = 'Salud' THEN trx ELSE 0 END) AS trx_consum_h1m_SALUD,
		
		MAX(CASE WHEN PeriodoCompra >=@u3m AND RUBRO_FINAL = 'Salud' THEN 1 ELSE 0 END) AS consumio_h2m_h3m_SALUD,
		SUM(CASE WHEN PeriodoCompra >=@u3m AND RUBRO_FINAL = 'Salud' THEN monto ELSE 0 END) AS monto_consum_h2m_h3m_SALUD,
		SUM(CASE WHEN PeriodoCompra >=@u3m AND RUBRO_FINAL = 'Salud' THEN trx ELSE 0 END) AS trx_consum_h2m_h3m_SALUD,
		
		MAX(CASE WHEN PeriodoCompra  >=@u5m AND RUBRO_FINAL = 'Salud' THEN 1 ELSE 0 END) AS consumio_h4m_h5m_SALUD,
		SUM(CASE WHEN PeriodoCompra  >=@u5m AND RUBRO_FINAL = 'Salud' THEN monto ELSE 0 END) AS monto_consum_h4m_h5m_SALUD,
		SUM(CASE WHEN PeriodoCompra  >=@u5m AND RUBRO_FINAL = 'Salud' THEN trx ELSE 0 END) AS trx_consum_h4m_h5m_SALUD,

		DATEDIFF(MONTH,convert(date,max(CASE WHEN PeriodoCompra<@um AND RUBRO_FINAL = 'Salud' THEN PeriodoCompra END)+'01',112),convert(date,@u1m+'01',112)) as ult_mes_consum_SALUD,
		ROUND(AVG(case when RUBRO_FINAL='Salud' and PeriodoCompra<@um THEN CAST(meses_entre_consumos_rubro as float) END),2) as meses_entre_consum_SALUD,

------------------------------------------------------------------------------------------------------------------------
		-------  INDICAR PERIODO A PREDECIR -----------
		@um as PERIODO_PREDECIR,
		IIF(right(@um,2) IN('05','06','07','12'),1,0) AS Periodo_en_temporada_consumo,

--------------------------------------------------------------------------------------------------------------------------
		--******************* CAMPOS A PREDECIR ***************************************************

		MAX(CASE WHEN PeriodoCompra = @um AND RUBRO_FINAL='Salud' THEN 1 ELSE 0 END) AS consumio_um_SALUD,
		SUM(CASE WHEN PeriodoCompra = @um AND RUBRO_FINAL='Salud' THEN monto ELSE 0 END) AS monto_consumio_um_SALUD,

	INTO PRODUCTION.DBO.XV_PRUEBA_ML 
	FROM #datos_cliente A
	LEFT JOIN #unionconsumos B ON A.LLAVE=B.LLAVE
	GROUP BY A.Llave,A.LINEACREDITO,A.EDAD,A.DEPARTAMENTO_RENIEC,A.SITUACIONLABORAL,A.NSE,A.DiasMora,A.NombreTipoTarjeta,A.NombreSituacionCliente


--======== CATEGORIZAMOS meses_entre_consumos ==================
	UPDATE PRODUCTION.DBO.XV_PRUEBA_ML
	SET meses_entre_consumos_categorizado = CASE	WHEN meses_entre_consumos>=0 and  meses_entre_consumos<=1 THEN '[0-1]'
													WHEN meses_entre_consumos>1 and  meses_entre_consumos<=3 THEN '<1-3]'
													WHEN meses_entre_consumos>3 and  meses_entre_consumos<=5 THEN '<3-5]'
													WHEN meses_entre_consumos>5 and  meses_entre_consumos<=7 THEN '<5-7]'
													WHEN meses_entre_consumos>7 and  meses_entre_consumos<=9 THEN '<7-9]'
													WHEN meses_entre_consumos>9 and  meses_entre_consumos<=11 THEN '<9-11]'
													WHEN meses_entre_consumos>11 THEN '<11-inf]'
													ELSE 'SIN COMPRA' END ;
