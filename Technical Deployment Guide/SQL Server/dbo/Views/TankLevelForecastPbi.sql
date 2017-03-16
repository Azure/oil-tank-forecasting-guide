CREATE VIEW [dbo].[TankLevelForecastPbi] AS (
    SELECT Forecasts.[Time]
        , Forecasts.[FacilityId]
        , Actuals.[TankLevel] 
        , Forecasts.[TankLevelForecast]
        , Forecasts.[TankLevelForecast] - Actuals.[TankLevel] AS Error
        , (ABS(Forecasts.[TankLevelForecast] - Actuals.[TankLevel]) / Actuals.[TankLevel]) * 100 AS AbsPctError
    FROM (
        SELECT DATEADD(hour, 1, DATEADD(MINUTE, ROUND(DATEDIFF(MINUTE, 0, [Time]) / 15.0, 0) * 15, 0)) AS [Time]
                , [FacilityId]
                , [TankLevelForecast]
                FROM [dbo].[TankLevelForecast]
    ) AS Forecasts
    LEFT JOIN (
        SELECT DATEADD(minute, ROUND(DATEDIFF(MINUTE, 0, [Time]) / 15.0, 0) * 15, 0) AS [Time]
                , [FacilityId]
                , [TankLevel]
                FROM [dbo].[TankLevelForecast]
    ) AS Actuals
    ON Actuals.[Time] = Forecasts.[Time]
    AND Actuals.[FacilityId] = Forecasts.[FacilityId]
    WHERE Forecasts.[Time] > (SELECT DATEADD(HOUR, -12, MAX([Time])) FROM [dbo].[TankLevelForecast])
);
