---
name: code-review
description: "Use when: 代码评审, review, PR审查, 查找bug, 风险评估, 回归影响分析, 测试覆盖检查. Perform a severity-first review with actionable fixes."
---
# Code Review Skill

## 目标

对变更进行高质量评审，优先发现：

- 功能错误
- 安全风险
- 性能问题
- 可维护性问题
- 测试缺失

## 输入

- 变更文件列表（或 git diff）
- 相关需求说明（可选）
- 运行/测试方式（可选）

## 工作流程

1. 先快速理解变更意图与影响范围。
2. 按严重级别输出问题（Critical/High/Medium/Low）。
3. 每个问题必须包含：
   - 位置（文件与行）
   - 问题原因
   - 影响范围
   - 最小修复建议
4. 检查是否存在回归风险：
   - 边界条件
   - 并发/异步行为
   - 空值与异常路径
   - 配置兼容性
5. 检查测试覆盖：
   - 是否有新增/更新测试
   - 缺哪些关键测试用例
6. 若未发现问题，明确说明“未发现阻断问题”，并给出剩余风险与建议测试点。

## 输出格式

- Findings（按严重级别排序）
- Open Questions / Assumptions
- Change Summary（简要）
- Suggested Tests（可执行）

## 评审原则

- 结论要可验证，避免主观措辞。
- 优先给“最小可落地修复方案”。
- 不改风格类细节，除非会导致可读性或维护风险。
- 若信息不足，先列假设再下结论。
