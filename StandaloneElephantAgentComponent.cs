using TaleWorlds.MountAndBlade;

namespace BEElephantsStandalone
{
    internal sealed class StandaloneElephantAgentComponent : AgentComponent
    {
        internal float NextAttackTime { get; set; }
        internal bool IsRemoved { get; private set; }

        internal StandaloneElephantAgentComponent(Agent agent) : base(agent) { }

        public override void OnAgentRemoved()
        {
            IsRemoved = true;
        }
    }
}
