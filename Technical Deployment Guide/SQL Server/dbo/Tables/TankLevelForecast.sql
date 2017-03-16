CREATE TABLE [dbo].[TankLevelForecast] (
    [Time]              DATETIME2   NOT NULL,
    [FacilityId]        VARCHAR(50) NOT NULL,
    [TankLevel]         FLOAT       NULL,
    [TankLevelForecast] FLOAT       NULL
);
