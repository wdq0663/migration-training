1️⃣ 数据类型相关错误（最常见 & 最致命）
1.1 NUMBER 类型精度丢失（高频）
❌ 错误示例
CREATE TABLE orders (
    amount NUMBER   -- 默认 NUMBER(38,0)，小数会被截断
);

✅ 正确做法
CREATE TABLE orders (
    order_id NUMBER(10, 0),
    amount NUMBER(12, 2),
    tax_rate NUMBER(5, 4)
);

🧠 原因说明

Oracle 中 NUMBER 精度灵活，很多历史表未显式定义

Snowflake 默认 NUMBER(38,0) → 所有小数位直接丢失

✅ 预防 Checklist

 所有 NUMBER 必须显式指定 (precision, scale)

 金额类字段统一 (12,2) 或 (18,2)

 Code Review 时重点检查 NUMBER

 DDL 扫描脚本检测裸 NUMBER

1.2 VARCHAR 长度不足
❌ 错误示例
CREATE TABLE employees (
    name VARCHAR(20)
);

✅ 正确做法
CREATE TABLE employees (
    name VARCHAR(100)
);

🧠 原因说明

Oracle 历史表字段长度偏保守

Snowflake 不限制 VARCHAR 成本，空间不是问题

✅ 预防 Checklist

 分析源数据最大长度

 预留 ≥ 20% 冗余

 日志 / 描述字段可使用最大 VARCHAR

1.3 时间类型选择错误
❌ 错误示例
CREATE TABLE events (
    event_time TIMESTAMP
);

✅ 正确做法
CREATE TABLE events (
    event_date DATE,
    event_time TIMESTAMP_NTZ,
    scheduled_time TIMESTAMP_TZ
);

🧠 原因说明

Snowflake 有 3 种 TIMESTAMP

默认 TIMESTAMP_NTZ 不保存时区

✅ 预防 Checklist

 明确是否需要时区

 统一使用 UTC

 文档说明时间语义

2️⃣ SQL 语法迁移错误
2.1 Oracle (+) OUTER JOIN 未改写
❌ 错误示例
SELECT e.name, d.dept_name
FROM employees e, departments d
WHERE e.dept_id = d.dept_id(+);

✅ 正确做法
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;

✅ 预防 Checklist

 禁止 (+)

 全量使用 ANSI JOIN

 自动化 grep 检测 (+)

2.2 ROWNUM 分页错误
❌ 错误示例
SELECT * FROM employees WHERE ROWNUM <= 10;

✅ 正确做法
SELECT * FROM employees LIMIT 10 OFFSET 20;

✅ 预防 Checklist

 所有分页统一使用 LIMIT / OFFSET

 禁止 ROWNUM

2.3 DUAL 表遗留
❌ 不推荐
SELECT SYSDATE FROM DUAL;

✅ 推荐
SELECT CURRENT_TIMESTAMP();

3️⃣ 存储过程迁移错误
3.1 OUT 参数未转换（高风险）
❌ 错误示例
CREATE PROCEDURE get_salary(
    emp_id IN NUMBER,
    salary OUT NUMBER
);

✅ 正确做法
CREATE PROCEDURE get_salary(emp_id NUMBER)
RETURNS NUMBER
LANGUAGE SQL
AS
$$
DECLARE
    v_salary NUMBER;
BEGIN
    SELECT salary INTO :v_salary
    FROM employees
    WHERE employee_id = :emp_id;
    RETURN v_salary;
END;
$$;

✅ 预防 Checklist

 所有 OUT 参数 → RETURNS

 同步修改 Java 调用代码

 单独测试存储过程

3.2 变量引用缺少冒号
❌ 错误
SELECT salary INTO v_salary FROM employees;

✅ 正确
SELECT salary INTO :v_salary FROM employees;

3.3 ELSIF 拼写错误
❌ Oracle 写法
ELSIF condition THEN

✅ Snowflake
ELSEIF (condition) THEN

4️⃣ JDBC 连接相关错误
4.1 连接池配置不合理
❌ 错误示例
config.setMaximumPoolSize(100);

✅ 正确示例
config.setMaximumPoolSize(20);
config.setMinimumIdle(5);
config.setConnectionTimeout(30000);
config.addDataSourceProperty("client_session_keep_alive", "true");

✅ 预防 Checklist

 连接数与 Warehouse 匹配

 启用 keep_alive

 监控连接池

4.2 存储过程调用方式未更新
❌ 错误
cs.registerOutParameter(2, Types.NUMERIC);

✅ 正确
ResultSet rs = cs.executeQuery();

5️⃣ 数据验证相关错误（最容易被忽略）
5.1 未验证小数精度
✅ 推荐校验
SELECT order_id, amount
FROM orders
WHERE amount != FLOOR(amount)
LIMIT 100;

5.2 未验证 NULL 分布
SELECT COUNT(*)
FROM employees
WHERE commission_pct IS NULL;

6️⃣ 性能相关错误
6.1 未设置聚簇键
ALTER TABLE orders CLUSTER BY (order_date);

6.2 Warehouse 规格选择不当
预防 Checklist

 性能测试

 Auto-Suspend

 使用率监控

7️⃣ 文档与流程错误
7.1 缺少变更说明
预防 Checklist

 填写 interface-modification-checklist

 输出 diff-report

 通知下游系统

8️⃣ 总结
Top 5 高频错误

NUMBER 精度丢失

OUT 参数未改

(+) JOIN 遗留

变量未加冒号

数据验证不足