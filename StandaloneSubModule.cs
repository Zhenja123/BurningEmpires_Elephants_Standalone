using TaleWorlds.MountAndBlade;

namespace BEElephantsStandalone
{
    /// <summary>
    /// Standalone module entry point. This intentionally contains no Burning Empires references.
    /// </summary>
    public sealed class StandaloneSubModule : MBSubModuleBase
    {
        public override void OnBeforeMissionBehaviorInitialize(Mission mission)
        {
            base.OnBeforeMissionBehaviorInitialize(mission);

            if (mission != null &&
                mission.GetMissionBehavior<StandaloneElephantMissionBehavior>() == null)
            {
                mission.AddMissionBehavior(new StandaloneElephantMissionBehavior());
            }
        }
    }
}
