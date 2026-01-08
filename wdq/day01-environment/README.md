# Day 01 - 环境准备

## 环境配置过程

### 1. Snowflake 账户配置

**配置步骤：**
1. 接收到 Snowflake 账户邀请邮件
2. 设置密码并启用 MFA（多因素认证）
3. 登录 Snowflake Web UI
4. 验证账户角色：`ACCOUNTADMIN`, `SYSADMIN`, `PUBLIC`

**遇到的问题：**

- **问题1：** 无法看到某些数据库
    - **原因分析：** 当前角色权限不足
    - **解决方案：** 使用 `USE ROLE SYSADMIN;` 切换角色
    - **参考资料：** 内部文档 wiki/access-control/role-hierarchy.md

### 2. 开发工具安装

**已安装工具清单：**
- [ ] IntelliJ IDEA 2024.1.1
- [ ] DBeaver 23.3.0
- [ ] Git 2.43.0
- [ ] Oracle SQL Developer 23.1
- [ ] SnowSQL CLI 1.2.28


### 3. Git 工作流

**仓库克隆：**
```bash
git clone https://github.com/company/snowflake-migration.git
cd snowflake-migration
git checkout -b feature/wdq-day01
```

**提交规范测试：**
```bash
# 测试提交
echo "# Day 01 Setup" > test.md
git add test.md
git commit -m "docs: add day01 setup notes"
git push origin feature/wdq01
```

**PR 提交检查：**
- [x] Commit message 符合规范（type: description）
- [x] 分支命名符合 `feature/{name}-{task}` 格式
- [x] PR 描述清晰，包含任务目标

### 4. Hello World 程序

**Oracle 版本：**
```sql
-- oracle_hello.sql
SELECT 'Hello World from Oracle' AS message,
       SYSDATE AS current_time,
       USER AS current_user
FROM DUAL;
```

**Snowflake 版本：**
```sql
-- snowflake_hello.sql
SELECT 'Hello World from Snowflake' AS message,
       CURRENT_TIMESTAMP() AS current_time,
       CURRENT_USER() AS current_user;
```

**运行结果对比：**
| 数据库 | Message | Current Time | Current User |
|--------|---------|--------------|--------------|
| Oracle | Hello World from Oracle | 2025-01-15 09:30:00 | ZHANG_SAN |
| Snowflake | Hello World from Snowflake | 2025-01-15 09:30:00.123 | ZHANG_SAN |

**差异点：**
1. Oracle 使用 `DUAL` 伪表，Snowflake 不需要
2. Oracle 使用 `SYSDATE`，Snowflake 使用 `CURRENT_TIMESTAMP()`
3. Snowflake 时间戳精度更高（包含毫秒）

## 学习收获

1. 理解了 Snowflake 的角色层次结构（ACCOUNTADMIN > SYSADMIN > 自定义角色）
2. 掌握了基本的 SQL 差异（DUAL、日期函数）
3. 熟悉了团队的 Git 工作流程

## 后续计划

明天开始学习 SQL 语法对比，重点关注：
- JOIN 语法差异
- 聚合函数差异
- 字符串处理函数
