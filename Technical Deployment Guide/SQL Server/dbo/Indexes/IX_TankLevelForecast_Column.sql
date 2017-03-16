CREATE NONCLUSTERED INDEX [IX_TankLevelForecast_Column]
    ON [dbo].[TankLevelForecast]
	([Time] ASC, [FacilityId] ASC, [TankLevel] ASC);
