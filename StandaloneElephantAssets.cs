using System;
using TaleWorlds.Core;
using TaleWorlds.Engine;
using TaleWorlds.MountAndBlade;
using TaleWorlds.ObjectSystem;

namespace BEElephantsStandalone
{
    internal static class StandaloneElephantAssets
    {
        private static ActionIndexCache[] _attackActions;
        private static int _attackSound = -1;
        private static int _hitSound = -1;

        internal static bool IsElephant(Agent agent)
        {
            if (agent == null) return false;
            var monster = agent.Monster;
            return monster != null &&
                   string.Equals(((MBObjectBase)monster).StringId, "elephant", StringComparison.Ordinal);
        }

        internal static bool TryGetAttackActions(out ActionIndexCache[] actions)
        {
            if (_attackActions == null)
            {
                _attackActions = new[]
                {
                    ActionIndexCache.Create("act_elephant_attack_1"),
                    ActionIndexCache.Create("act_elephant_attack_2"),
                    ActionIndexCache.Create("act_elephant_attack_3")
                };
            }

            actions = _attackActions;
            foreach (var action in actions)
                if (action.Index < 0) return false;
            return true;
        }

        internal static int AttackSound
        {
            get
            {
                if (_attackSound < 0)
                    _attackSound = ResolveSound("elephantAttacking");
                return _attackSound;
            }
        }

        internal static int HitSound
        {
            get
            {
                if (_hitSound < 0)
                    _hitSound = ResolveSound("elephantHit");
                return _hitSound;
            }
        }

        private static int ResolveSound(string id)
        {
            try { return SoundEvent.GetEventIdFromString(id); }
            catch { return -1; }
        }
    }
}
