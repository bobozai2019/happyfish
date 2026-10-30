# Gate 2 首次可玩报告

文档角色：`verification_evidence`

状态：[已完成]

日期：2026-08-08

范围：T03、T04

## 结论

- T03 [已完成]：双炮台、瞄准、倍率、单发/连发、子弹、范围渔网与原子归属入口已实现。
- T04 [已完成]：通用鱼、4 条预制曲线路径、权重生成、离场回收及 Boss 调度已实现。
- Gate 2 [已完成]：自动化真实节点测试与 180 帧启动烟雾测试通过；长时条件采用确定性时间推进覆盖。

## 验收项

| 项 | 标准 | 证据 | 结果 |
|---|---|---|---|
| 双人瞄准 | 两座炮台同时旋转且输入不串线 | 同帧 `p1_aim_left` + `p2_aim_right` InputMap 集成测试 | pass |
| 倍率切换 | 两人可独立切换 1×/2×/5× | 同帧 P1 升档、P2 降档，分别得到 2×、5× | pass |
| 单发与连发 | 按下立即发射，按住 0.25s 连发 | 双方同时按住 35 physics frames，双方均发射至少 2 发 | pass |
| 自动降档 | 余额不足时选择可支付最高档 | 2 金币请求 5×，实际使用 2×、扣 2 金币 | pass |
| 子弹和渔网 | 命中/出界生命周期只完成一次 | `Projectile.resolve_once()` 重复调用测试；pending 最终归零 | pass |
| 渔网范围 | 1×/2×/5× 半径来自资源 | 1× 不覆盖、5× 覆盖相同 115px 中心距鱼体的物理查询测试 | pass |
| 鱼群生成 | 权重、间隔、路径和 20 条上限正常 | 4 条静态 Curve2D；0.55-1.0s 生成窗口与上限断言 | pass |
| 捕获归属 | 同一鱼最多被声明一次 | P1 首次 `try_claim_capture` 成功，P2 重复声明失败 | pass |
| 暂停 | 生成与 Boss 计时停止 | SceneTree pause 前后 `elapsed_time` 不变 | pass |
| Boss 调度骨架 | 警告、单实例和冷却可触发 | 18 捕获触发、2s 确定性推进、单 Boss、离场后约 90s 冷却 | pass |

## 命令与结果

```powershell
godot --headless --editor --path . --quit
# exit 0；CannonController、Projectile、NetEffect、FishActor、SpawnDirector 类注册成功

godot --headless --path . --script res://tests/run_all.gd
# exit 0；PASS: Gate 1 数据与 Gate 2 灰盒对象、生成、Boss 调度校验通过

godot --headless --path . --quit-after 180
# exit 0；连续运行 180 帧无启动或运行时错误
```

## 自动化覆盖的人工步骤

1. 双人同时瞄准、切倍率和长按开火由 InputMap 集成测试直接驱动。
2. 网半径与金币请求由真实 Cannon/Projectile/NetEffect 节点测试覆盖。
3. 鱼群生成窗口、暂停、Boss 警告和冷却使用真实 SpawnDirector 加确定性时间推进，避免等待 3 分钟的非确定性人工测试。

## 问题与返工

| 问题 | 严重度 | 负责人 | 返工任务 | 状态 |
|---|---|---|---|---|
| 当前为代码绘制灰盒造型，尚无成品原型动画与声音 | 低 | 主 agent | T07 | planned |
