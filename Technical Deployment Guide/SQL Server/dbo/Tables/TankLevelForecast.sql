CREATE TABLE [dbo].[TankLevelForecast] (
    [FacilityId]        NVARCHAR (50) NOT NULL,
    [Time]              DATETIME2      NOT NULL,
    [TankLevel]         FLOAT (53)    NULL,
    [TankLevelForecast] FLOAT (53)    NULL
);

