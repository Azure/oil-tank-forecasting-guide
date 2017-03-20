CREATE TABLE [dbo].[TankLevelSensor] (
    [FacilityId] VARCHAR(50) NOT NULL,
    [Time]       DATETIME2   NOT NULL,
    [Sensor]     VARCHAR(50) NOT NULL,
    [Value]      FLOAT       NULL
);
