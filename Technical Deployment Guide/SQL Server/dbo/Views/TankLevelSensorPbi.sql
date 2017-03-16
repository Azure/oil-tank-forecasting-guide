CREATE VIEW [dbo].[TankLevelSensorPbi] AS (
    SELECT [Time]
        , [FacilityId]
        , [Sensor]
        , [Value]
        , CASE
            WHEN LEFT([Sensor], 9) = 'TankLevel' THEN 'TankLevel'
            ELSE LEFT([Sensor], 7)
        END AS [SensorType]
    FROM [dbo].[TankLevelSensor]
    WHERE [Time] > (SELECT DATEADD(HOUR, -12, MAX([Time])) FROM [dbo].[TankLevelSensor])
);
