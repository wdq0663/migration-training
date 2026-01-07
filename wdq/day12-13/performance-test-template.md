# 性能测试模板（Performance Test Template）

> 本模板用于 **Snowflake SQL / 应用查询的性能测试、对比分析与验证**，可直接复制用于迁移、优化、回归阶段。

---

## 1. 测试背景（Background）

* **测试目标**：

  * ☐ 基准性能评估
  * ☐ 优化前后对比
  * ☐ 并发 / 压力验证

* **业务场景说明**：

  * 涉及的业务功能：
  * 查询/接口用途：
  * 是否为核心链路：是 / 否

---

## 2. 测试对象（Test Target）

### 2.1 SQL / 接口信息

* SQL ID / 接口名：

* 查询类型：

  * ☐ 单表查询
  * ☐ 多表 JOIN
  * ☐ 聚合（GROUP BY）
  * ☐ 子查询 / CTE

* 是否涉及大表（>1 亿行）：是 / 否

---

## 3. 测试环境（Test Environment）

### 3.1 Snowflake 环境

| 项目             | 配置             |
| -------------- | -------------- |
| Account        |                |
| Warehouse      |                |
| Warehouse Size | XS / S / M / L |
| Auto Suspend   | 开 / 关          |
| Auto Resume    | 开 / 关          |
| Result Cache   | 开 / 关          |

### 3.2 数据规模

| 表名 | 行数 | 数据量 |
| -- | -- | --- |
|    |    |     |
|    |    |     |

---

## 4. 测试方法（Test Methodology）

### 4.1 测试类型

* ☐ 基准测试（Baseline）
* ☐ 对比测试（Before / After）
* ☐ 负载测试（Concurrency）

### 4.2 测试规则

* 每次测试执行次数：____ 次
* 是否清空 Result Cache：是 / 否
* 是否固定 Warehouse：是 / 否
* 是否避开业务高峰：是 / 否

---

## 5. 性能指标（Metrics）

### 5.1 核心指标

| 指标            | 说明               | 记录值 |
| ------------- | ---------------- | --- |
| 执行时间（ms）      | P50 / P95        |     |
| 扫描数据量（GB）     | Table Scan Bytes |     |
| 扫描分区数         | Scanned / Total  |     |
| Rows In / Out | 是否数据膨胀           |     |
| Warehouse 使用率 | CPU / IO         |     |

---

## 6. Query Profile 分析（关键）

### 6.1 Profile 摘要

* 主要耗时 Stage：
* 主要算子（Operator）：
* 是否存在全表扫描：是 / 否
* 是否发生数据膨胀：是 / 否

### 6.2 问题识别

| 问题类型       | 具体表现 | 影响 |
| ---------- | ---- | -- |
| 剪枝失效       |      |    |
| JOIN 顺序不合理 |      |    |
| 聚合数据量过大    |      |    |

---

## 7. 优化方案（Optimization Plan）

### 7.1 优化点列表

* ☐ 改写 WHERE 条件（启用剪枝）
* ☐ 调整 JOIN 顺序
* ☐ 增加 / 调整 Clustering Key
* ☐ 改写子查询为 CTE
* ☐ 拆分复杂 SQL

### 7.2 具体修改说明

```sql
-- 优化前 SQL

-- 优化后 SQL
```

---

## 8. 优化效果对比（Before vs After）

| 指标           | Before | After | 提升 |
| ------------ | ------ | ----- | -- |
| 执行时间         |        |       |    |
| 扫描数据量        |        |       |    |
| 扫描分区数        |        |       |    |
| Warehouse 成本 |        |       |    |

> 是否达到目标提升：

* ☐ ≥ 30%
* ☐ ≥ 50%

---

## 9. 结论与建议（Conclusion）

* 本次优化是否生效：是 / 否
* 是否建议推广到其他查询：是 / 否
* 是否需要结构性改造（表设计 / 数据模型）：是 / 否

---

## 10. 常见性能反模式（记录用）

* ☐ WHERE 条件中对列做函数
* ☐ JOIN 前未过滤大表
* ☐ 无限制返回大结果集
* ☐ 盲目调大 Warehouse

---

## 11. 附录（Artifacts）

* Query Profile 截图（Before / After）
* Query History 导出
* JMeter / Gatling 报告（如有）

---

**模板版本**：v1.0
**适用场景**：Oracle → Snowflake 迁移 / 性能优化 / 回归测试
