一、文档说明

项目：oracle-snowflake-migration-training

迁移内容：Oracle JDBC 接口 → Snowflake JDBC 接口

涉及接口数：2

修改方式：人工迁移（遵循 Interface Modification SOP）

二、接口一：用户信息查询接口（Simple SELECT）
1️⃣ 接口说明
项目	内容
接口名称	findUserById
功能	根据用户 ID 查询用户基本信息
SQL 类型	单表 SELECT
复杂度	低
2️⃣ 修改前（Oracle）
private static final String ORACLE_URL =
"jdbc:oracle:thin:@//localhost:1521/ORCL";

String sql =
"SELECT id, username, created_date " +
"FROM users " +
"WHERE id = ? " +
"AND created_date <= SYSDATE";

user.setCreatedDate(rs.getDate("created_date"));

3️⃣ 修改后（Snowflake）
private static final String SNOWFLAKE_URL =
"jdbc:snowflake://abc123.snowflakecomputing.com/?db=APP_DB&schema=PUBLIC";

String sql =
"SELECT id, username, created_date " +
"FROM users " +
"WHERE id = ? " +
"AND created_date <= CURRENT_DATE";

user.setCreatedDate(
rs.getTimestamp("created_date").toLocalDateTime()
);

4️⃣ 差异点对比说明
修改点	Oracle	Snowflake	说明
JDBC URL	oracle:thin	snowflake	替换数据源
日期函数	SYSDATE	CURRENT_DATE	SQL 方言差异
时间类型读取	getDate	getTimestamp	保留时间精度
5️⃣ 风险与验证

✅ SQL 执行成功

✅ 返回结果字段一致

✅ 时间字段精度符合预期

三、接口二：订单统计报表接口（JOIN + GROUP BY）
1️⃣ 接口说明
项目	内容
接口名称	getOrderSummaryReport
功能	按客户统计订单数量与金额
SQL 类型	JOIN + 聚合
复杂度	中
2️⃣ 修改前（Oracle）
String sql =
"SELECT c.customer_name, " +
"COUNT(o.id) AS order_cnt, " +
"SUM(o.amount) AS total_amount " +
"FROM orders o, customers c " +
"WHERE o.customer_id = c.id " +
"AND o.created_date >= SYSDATE - 30 " +
"GROUP BY c.customer_name " +
"HAVING SUM(o.amount) > 1000";

3️⃣ 修改后（Snowflake）
String sql =
"SELECT c.customer_name, " +
"COUNT(o.id) AS order_cnt, " +
"SUM(o.amount) AS total_amount " +
"FROM orders o " +
"JOIN customers c ON o.customer_id = c.id " +
"WHERE o.created_date >= DATEADD(day, -30, CURRENT_DATE) " +
"GROUP BY c.customer_name " +
"HAVING SUM(o.amount) > 1000";

4️⃣ 差异点对比说明
修改点	Oracle	Snowflake	说明
JOIN 方式	隐式 JOIN	显式 JOIN	可读性与规范
日期计算	SYSDATE - 30	DATEADD	Snowflake 标准函数
SQL 规范	老式写法	ANSI JOIN	推荐实践
5️⃣ 聚合结果处理差异
// Oracle
BigDecimal total = rs.getBigDecimal("total_amount");

// Snowflake
BigDecimal total = rs.getBigDecimal("total_amount");


聚合字段在 Snowflake 中返回 NUMBER，BigDecimal 兼容，无需调整。

6️⃣ 风险与验证

✅ JOIN 结果行数一致

✅ 聚合结果与 Oracle 对账一致

✅ 性能满足预期（Snowflake 扫描优化）