CREATE TABLE [dbo].[TankLevelForecast] (
    [FacilityId]        VARCHAR(50) NOT NULL,
    [Time]              DATETIME2   NOT NULL,
    [TankLevel]         FLOAT       NULL,
    [TankLevelForecast] FLOAT       NULL
);
