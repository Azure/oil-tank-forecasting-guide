CREATE TABLE [dbo].[TankLevelSensor] (
    [FacilityId] NVARCHAR (50) NOT NULL,
    [Time]       DATETIME2      NOT NULL,
    [Sensor]     NVARCHAR (50) NOT NULL,
    [Value]      FLOAT (53)    NULL
);

