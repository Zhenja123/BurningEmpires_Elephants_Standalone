using System;
using System.Collections.Generic;
using System.Linq;
using TaleWorlds.Core;
using TaleWorlds.DotNet;
using TaleWorlds.Engine;
using TaleWorlds.InputSystem;
using TaleWorlds.Library;
using TaleWorlds.MountAndBlade;
using TaleWorlds.ObjectSystem;

namespace BEElephantsStandalone
{
    /// <summary>
    /// Standalone port of the elephant attack behavior. Requires the three custom
    /// attack actions to be registered by the module's asset data.
    /// </summary>
    public sealed class StandaloneElephantMissionBehavior : MissionBehavior
    {
        private const float AttackRange = 3f;
        private const float ForwardDotThreshold = 0.2f;
        private const float AttackCooldown = 0.75f;
        private const float AiEvaluationInterval = 0.25f;
        private const float AiAttackChance = 0.01f;
        private const int BaseAttackDamage = 10;

        private readonly MBList<Agent> _nearbyAgents = new MBList<Agent>();
        private float _nextDiscoveryTime;
        private bool _cleanedUp;

        public override MissionBehaviorType BehaviorType => MissionBehaviorType.Other;

        public override void AfterStart()
        {
            base.AfterStart();
            DiscoverElephants();
        }

        public override void OnAgentBuild(Agent agent, Banner banner)
        {
            base.OnAgentBuild(agent, banner);
            TryRegisterElephant(agent);
            TryRegisterElephant(agent != null ? agent.MountAgent : null);
        }

        public override void OnMissionTick(float dt)
        {
            base.OnMissionTick(dt);
            if (_cleanedUp || Mission == null || Mission.Scene == null) return;

            if (Mission.CurrentTime >= _nextDiscoveryTime)
            {
                _nextDiscoveryTime = Mission.CurrentTime + AiEvaluationInterval;
                DiscoverElephants();
                ProcessAIAttacks();
            }
            ProcessPlayerAttack();
        }

        public override void OnAgentHit(Agent affectedAgent, Agent affectorAgent,
            in MissionWeapon affectorWeapon, in Blow blow,
            in AttackCollisionData attackCollisionData)
        {
            if (StandaloneElephantAssets.IsElephant(affectedAgent) && MBRandom.RandomFloat < 0.3f)
                PlaySound(StandaloneElephantAssets.HitSound, affectedAgent.Position);
        }

        public override void OnClearScene()
        {
            _cleanedUp = true;
            base.OnClearScene();
        }

        public override void OnRemoveBehavior()
        {
            _cleanedUp = true;
            base.OnRemoveBehavior();
        }

        protected override void OnEndMission()
        {
            _cleanedUp = true;
            base.OnEndMission();
        }

        private void DiscoverElephants()
        {
            if (Mission == null) return;
            foreach (Agent agent in Mission.Agents)
                TryRegisterElephant(agent);
        }

        private static void TryRegisterElephant(Agent agent)
        {
            if (StandaloneElephantAssets.IsElephant(agent) &&
                agent.GetComponent<StandaloneElephantAgentComponent>() == null)
                agent.AddComponent(new StandaloneElephantAgentComponent(agent));
        }

        private void ProcessPlayerAttack()
        {
            Agent rider = Agent.Main;
            Agent elephant = rider != null ? rider.MountAgent : null;
            if (rider != null && rider.IsActive() && StandaloneElephantAssets.IsElephant(elephant) &&
                Mission.InputManager != null && Mission.InputManager.IsKeyPressed((InputKey)57))
                TryAttack(elephant, rider, null);
        }

        private void ProcessAIAttacks()
        {
            foreach (Agent elephant in Mission.Agents.Where(StandaloneElephantAssets.IsElephant).ToList())
            {
                Agent rider = elephant != null ? elephant.RiderAgent : null;
                if (rider == null || !rider.IsActive() || rider == Agent.Main ||
                    !rider.IsAIControlled || MBRandom.RandomFloat >= AiAttackChance)
                    continue;

                Agent target = rider.GetTargetAgent();
                if (target != null && target.IsActive() && target.IsEnemyOf(rider) &&
                    IsInAttackCone(elephant, target))
                    TryAttack(elephant, rider, target);
            }
        }

        private void TryAttack(Agent elephant, Agent rider, Agent preferredTarget)
        {
            if (elephant == null || rider == null || !elephant.IsActive() || !rider.IsActive())
                return;

            StandaloneElephantAgentComponent component =
                elephant.GetComponent<StandaloneElephantAgentComponent>();
            if (component == null || component.IsRemoved || Mission.CurrentTime < component.NextAttackTime)
                return;

            ActionIndexCache currentAction = elephant.GetCurrentAction(0);
            string actionName = currentAction.GetName();
            if (actionName != null && actionName.IndexOf("attack", StringComparison.OrdinalIgnoreCase) >= 0)
                return;

            if (!StandaloneElephantAssets.TryGetAttackActions(out ActionIndexCache[] actions))
                return;

            ActionIndexCache action = actions[MBRandom.RandomInt(actions.Length)];
            if (!elephant.SetActionChannel(0, ref action, false, (AnimFlags)0,
                0f, 1f, -0.2f, 0.4f, 0f, false, -0.2f, 0, true))
                return;

            component.NextAttackTime = Mission.CurrentTime + AttackCooldown;
            PlaySound(StandaloneElephantAssets.AttackSound, elephant.Position);
            ApplyAttackDamage(elephant, rider, preferredTarget);
        }

        private void ApplyAttackDamage(Agent elephant, Agent rider, Agent preferredTarget)
        {
            _nearbyAgents.Clear();
            Mission.GetNearbyAgents(elephant.Position.AsVec2, AttackRange, _nearbyAgents);

            foreach (Agent target in _nearbyAgents
                .Where(target => target != null && target != rider && target != elephant)
                .OrderBy(target => target != preferredTarget ? 1 : 0)
                .ThenBy(target => target.Index))
            {
                if (target.IsActive() && target.IsEnemyOf(rider) && IsInAttackCone(elephant, target))
                    RegisterElephantBlow(elephant, target);
            }
        }

        private static bool IsInAttackCone(Agent elephant, Agent target)
        {
            Vec3 delta = target.Position - elephant.Position;
            float lengthSquared = delta.LengthSquared;
            if (lengthSquared > AttackRange * AttackRange || lengthSquared <= 0.0001f)
                return false;

            return Vec3.DotProduct(delta.NormalizedCopy(),
                elephant.LookDirection.NormalizedCopy()) > ForwardDotThreshold;
        }

        private static void RegisterElephantBlow(Agent elephant, Agent target)
        {
            bool blocking = false;
            int damage = BaseAttackDamage;

            Blow blow = new Blow(elephant.Index)
            {
                DamageType = (DamageTypes)2,
                BoneIndex = target.Monster.HeadLookDirectionBoneIndex,
                GlobalPosition = target.Position,
                BaseMagnitude = damage,
                InflictedDamage = damage * 2,
                SwingDirection = elephant.LookDirection,
                Direction = elephant.LookDirection,
                DamageCalculated = true,
                BlowFlag = (BlowFlags)(blocking ? 16 : 32)
            };

            blow.GlobalPosition.z += target.GetEyeGlobalHeight();
            blow.WeaponRecord.FillAsMeleeBlow(null, null, -1, (sbyte)(-1));
            if (target.MountAgent != null)
                blow.BlowFlag = (BlowFlags)2048;

            AttackCollisionData collision = AttackCollisionData.GetAttackCollisionDataForDebugPurpose(
                blocking, false, false, true, false, false, false, false, false, false,
                false, false, (CombatCollisionResult)(blocking ? 3 : 1), -1, 0, 2,
                blow.BoneIndex, (BoneBodyPartType)0, elephant.Monster.MainHandItemBoneIndex,
                (TaleWorlds.MountAndBlade.Agent.UsageDirection)2, -1, (CombatHitResultFlags)0, 0.5f, 1f,
                0f, 0f, 0f, 0f, 0f, 0f, Vec3.Up, blow.Direction, blow.GlobalPosition,
                Vec3.Zero, Vec3.Zero, target.Velocity, Vec3.Up);
            target.RegisterBlow(blow, ref collision);
        }

        private void PlaySound(int eventId, Vec3 position)
        {
            if (eventId < 0 || Mission == null || Mission.Scene == null) return;
            try
            {
                SoundEvent sound = SoundEvent.CreateEvent(eventId, Mission.Scene);
                if (sound != null && sound.IsValid)
                {
                    sound.SetPosition(position);
                    sound.Play();
                }
            }
            catch
            {
                // Audio failure must not interrupt mission behavior.
            }
        }
    }
}
