## 存储过程迁移方案说明 —— SP3（动态 SQL + 异常处理）
### 1. 原存储过程概述

名称：sp_purge_table
功能：

接收表名参数

动态拼接 DELETE SQL

执行数据清理

记录成功或失败日志

显式事务控制与异常抛出

技术特征：

动态 SQL（对象名）

DELETE 高风险操作

显式 COMMIT / ROLLBACK

完整异常处理逻辑

### 2. 迁移策略选择

选择策略：策略 1 —— 迁移至 Java 应用层

### 3. 选择原因（关键）
   风险点	说明
   SQL 注入	表名无法 bind
   权限风险	DELETE 任意表
   事务控制	Snowflake SP 不推荐
   审计需求	应集中在应用层

结论：
该存储过程属于高风险运维型逻辑，不适合继续保留在数据库层，必须迁移至应用层。

### 4. 关键迁移点
````
   Oracle PL/SQL	Java 应用
   EXECUTE IMMEDIATE	Statement
   COMMIT / ROLLBACK	JDBC 事务
   EXCEPTION	try / catch
   SQLERRM	Exception.getMessage()
   ````
### 5. 安全设计

表名白名单控制

禁止外部任意传参

统一日志记录

明确异常抛出

### 6. 验证方式

校验允许表可成功清理

校验非法表名被拒绝

校验日志记录完整

校验异常可被捕获

### 7. 结论

SP3 属于“动态对象 + 高风险 DML”类型，应从数据库层彻底剥离，迁移至 Java 应用层以确保安全性、可维护性和审计能力。