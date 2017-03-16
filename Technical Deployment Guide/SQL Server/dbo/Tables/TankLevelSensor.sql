CREATE TABLE [dbo].[TankLevelSensor] (
    [Time]       DATETIME2   NOT NULL,
    [FacilityId] VARCHAR(50) NOT NULL,
    [Sensor]     VARCHAR(50) NOT NULL,
    [Value]      FLOAT       NULL
);
