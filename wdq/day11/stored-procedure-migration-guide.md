📘 Stored Procedure Migration Guide

Oracle PL/SQL → Snowflake 迁移实战指南

1. 文档目的

本指南用于规范和指导 Oracle PL/SQL 存储过程迁移至 Snowflake 的实践，帮助开发人员在不同场景下选择合适的迁移策略，避免常见错误，提高迁移质量与可维护性。

2. Snowflake 中的存储过程类型概览

Snowflake 提供两种主要的存储过程实现方式：

2.1 Snowflake Scripting（SQL 存储过程）

类似 PL/SQL 的过程式 SQL

适合 简单、线性逻辑

不推荐复杂控制流或大规模循环

适用特点：

CRUD

简单条件判断

少量变量

2.2 Snowflake JavaScript 存储过程

使用 JavaScript 作为过程语言

通过 Snowflake 提供的 API 执行 SQL

控制流能力强

适用特点：

游标 / 循环

多步逻辑

中等复杂度过程

2.3 Java 应用层实现（推荐策略之一）

将存储过程逻辑迁移到 Java 服务中

使用 JDBC 调用 Snowflake

适用特点：

动态 SQL（尤其是对象名）

复杂事务

高安全风险操作

需要统一审计与权限控制

3. 三种迁移策略总览
策略	目标实现	典型场景
策略 1	Java 应用层	动态 SQL、高风险逻辑
策略 2	JavaScript SP	游标、循环、中等复杂度
策略 3	Snowflake Scripting	简单 CRUD
4. 迁移策略详细说明
4.1 策略 1：迁移至 Java 应用层（推荐）
适用场景

动态拼接表名 / 列名

DELETE / TRUNCATE 等高风险操作

显式事务控制

需要严格权限校验

优点

安全性最高

易于测试和审计

与现代架构一致

缺点

改造成本相对较高

示例
try {
    conn.setAutoCommit(false);
    stmt.executeUpdate(sql);
    conn.commit();
} catch (Exception e) {
    conn.rollback();
    throw e;
}

4.2 策略 2：Snowflake JavaScript 存储过程
适用场景

Oracle CURSOR

FOR / WHILE LOOP

多次 SQL 执行

逻辑较复杂但仍希望保留在 DB 层

优点

控制流灵活

易模拟 Oracle 游标

缺点

JavaScript 调试成本较高

不适合极大数据量循环

示例
while (rs.next()) {
    var cnt = rs.getColumnValue(1);
}

4.3 策略 3：Snowflake Scripting（SQL）
适用场景

参数传递

简单 INSERT / UPDATE

逻辑清晰、步骤少

优点

改动最小

易读易维护

缺点

不适合复杂过程逻辑

5. 常见语法与概念转换规则
5.1 变量与控制流
Oracle PL/SQL	Snowflake
ELSIF	ELSEIF
SYSDATE	CURRENT_TIMESTAMP()
SELECT INTO	LET / JS ResultSet
OUT 参数	RETURNS
5.2 游标与循环
Oracle	Snowflake
CURSOR	ResultSet
FOR rec IN cursor	while (rs.next())
%ROWTYPE	JS 对象
5.3 动态 SQL
Oracle	Snowflake
EXECUTE IMMEDIATE	JS stmt.execute()
SQLERRM	Exception message

⚠️ 注意：
Snowflake 不支持对对象名使用 bind 变量，涉及对象名的动态 SQL 强烈建议迁移至应用层。

6. 事务与异常处理差异
6.1 事务控制

Snowflake 存储过程 默认自动提交

不推荐在 SP 中显式 COMMIT / ROLLBACK

复杂事务应放在应用层

6.2 异常处理
Oracle	Snowflake
EXCEPTION WHEN OTHERS	try / catch
SQLERRM	error.message
7. 决策树（迁移策略选择）
开始
 │
 ├─ 是否包含动态 SQL（表名/列名）？
 │        ├─ 是 → Java 应用层（策略 1）
 │        └─ 否
 │
 ├─ 是否使用游标 / 循环？
 │        ├─ 是 → JavaScript 存储过程（策略 2）
 │        └─ 否
 │
 ├─ 是否仅为简单 CRUD？
 │        ├─ 是 → Snowflake Scripting（策略 3）
 │        └─ 否 → JavaScript 存储过程（策略 2）

8. 功能验证建议

对比 Oracle 与 Snowflake 结果集

校验行数、聚合值

验证异常分支

检查时间与精度

9. 最佳实践总结
技术层面

优先减少存储过程数量

复杂逻辑上移应用层

严禁高风险动态 SQL 留在 DB

流程层面

每个 SP 必须有 migration-plan.md

必须有功能验证用例

必须通过 Code Review