## 存储过程迁移方案说明 —— SP1（简单 CRUD）
### 1. 原存储过程概述

名称：sp_create_user
功能：

接收用户 ID、用户名、邮箱

向 users 表插入一条记录

自动记录注册时间

显式提交事务

技术特征：

无游标

无动态 SQL

无异常处理

逻辑简单、线性执行

### 2. 迁移策略选择

选择策略：策略 3 —— Snowflake Scripting（SQL 存储过程）

### 3. 选择原因
   评估维度	说明
   逻辑复杂度	⭐ 非常简单
   SQL 依赖	纯 SQL
   事务控制	Snowflake 可自动管理
   可维护性	高
   是否需要应用层	否

结论：
该存储过程逻辑简单，适合直接保留在数据库层，使用 Snowflake Scripting 可最大程度保持原有结构与可读性。

### 4. 关键迁移点
   Oracle PL/SQL	Snowflake Scripting
   SYSDATE	CURRENT_TIMESTAMP()
   COMMIT	可移除（自动提交）
   VARCHAR2	VARCHAR
   NUMBER	NUMBER(p,s)
### 5. 风险与应对
   风险	应对措施
   时间函数差异	统一使用 UTC
   自动提交差异	明确不在 SP 中控制事务
### 6. 验证方式

插入数据后校验行数

对比 Oracle 与 Snowflake 插入结果

校验时间字段是否正确生成

### 7. 结论

SP1 适合使用 Snowflake Scripting 进行迁移，可在保持逻辑一致的前提下，减少应用层改造成本。