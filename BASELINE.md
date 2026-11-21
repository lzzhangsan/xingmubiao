# 星目标（xingmubiao）稳定基线版本

**基线标签：** `baseline-stable-v1.0-2026-11-20`

**创建日期：** 2026-11-20

**状态：** 已保护（本地 + 远程 GitHub Tag）

## 基线说明

这是当前相对稳定的儿童习惯养成 MVP 版本。

以后所有功能升级、架构优化、UI 调整，都应与此基线做对比，确认是否真正带来了功能提升或代码质量改善。

## 基线时的主要特征

- Flutter 跨平台儿童习惯养成应用
- 目标管理 + 评分式打卡 + 积分 + 心愿库
- 多孩子切换、主题系统
- 主要依赖本地存储（LocalDataStore），Firebase 依赖已引入但使用不完整
- Provider 管理用户与主题
- 结构清晰，可运行的 MVP

## 使用方式

```bash
# 查看基线
 git show baseline-stable-v1.0-2026-11-20

# 从基线创建新分支进行升级
 git checkout -b feature/family-system baseline-stable-v1.0-2026-11-20
```

所有重大变更应在提交信息中注明与基线的差异和改进点。
