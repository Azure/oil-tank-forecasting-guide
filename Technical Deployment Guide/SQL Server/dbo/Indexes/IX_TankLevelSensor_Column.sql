CREATE NONCLUSTERED INDEX [IX_TankLevelSensor_Column]
    ON [dbo].[TankLevelSensor]
	([Time] ASC, [FacilityId] ASC, [Sensor] ASC);
