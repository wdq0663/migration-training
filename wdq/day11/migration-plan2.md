## 存储过程迁移方案说明 —— SP2（游标 + 循环）
### 1. 原存储过程概述

名称：sp_count_users_by_dept
功能：

遍历 departments 表

统计每个部门的用户数量

将统计结果写入 department_user_stats

技术特征：

使用游标

使用 FOR LOOP

包含多次 SQL 执行

数据量可能较大

### 2. 迁移策略选择

选择策略：策略 2 —— Snowflake JavaScript 存储过程

### 3. 选择原因
   评估维度	说明
   游标支持	Snowflake SQL 游标能力有限
   循环控制	JavaScript 更灵活
   可读性	JS 更直观
   执行逻辑	偏过程式

结论：
该存储过程包含游标与循环逻辑，使用 JavaScript 存储过程更易实现与维护。

### 4. 关键迁移点
   Oracle PL/SQL	Snowflake JavaScript
   CURSOR	ResultSet
   FOR LOOP	while (rs.next())
   SELECT INTO	rs.getXXX()
   SYSDATE	CURRENT_TIMESTAMP()
### 5. 风险与应对
   风险	应对措施
   性能问题	控制 ResultSet 大小
   多次 INSERT	批量插入（可选优化）
   权限问题	使用最小权限角色
### 6. 验证方式

对比部门数量是否一致

对比每个部门的用户数

校验统计日期

### 7. 结论

SP2 属于“中等复杂度过程型逻辑”，使用 Snowflake JavaScript 存储过程在可维护性与实现复杂度之间取得平衡。