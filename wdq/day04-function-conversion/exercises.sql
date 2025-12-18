 **练习 1**: 转换 DECODE
   ```sql
   -- Oracle
   SELECT employee_id,
          DECODE(department_id, 10, 'Admin', 20, 'Sales', 'Other') AS dept_name
   FROM employees;

   -- 改写为 Snowflake (请在此处填写)
   ```
   SELECT employee_id,
       CASE
         WHEN department_id = 10 THEN 'Admin'
         WHEN department_id = 20 THEN 'Sales'
         ELSE 'Other'
       END AS dept_name
    FROM employees;


   **练习 2**: 转换 ROWNUM
   ```sql
   -- Oracle: 查询前 10 条记录
   SELECT * FROM orders WHERE ROWNUM <= 10;

   -- 改写为 Snowflake (请在此处填写)
   ```
    SELECT *
    FROM (
    SELECT *,
         ROW_NUMBER() OVER () AS rn
    FROM orders
    )
    WHERE rn <= 10;


    SELECT *,
       ROW_NUMBER() OVER () AS rn
    FROM orders
    QUALIFY rn <= 10;



   **练习 3**: 转换 ADD_MONTHS
   ```sql
   -- Oracle: 计算 3 个月后的日期
   SELECT order_id, ADD_MONTHS(order_date, 3) AS due_date
   FROM orders;

   -- 改写为 Snowflake (请在此处填写)
   ```
   SELECT order_id, DATEADD(MONTH,3,order_date) FROM orders;

   **练习 4**: 转换 CONNECT BY（挑战）
   ```sql
   -- Oracle: 查询组织层级
   SELECT employee_id, manager_id, LEVEL
   FROM employees
   START WITH manager_id IS NULL
   CONNECT BY PRIOR employee_id = manager_id;

   -- 改写为 Snowflake 递归 CTE (请在此处填写)
   ```

    WITH RECURSIVE org_tree AS (
    -- 起点：根节点
    SELECT employee_id, name, manager_id, 1 AS lvl
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- 递归：找下属
    SELECT e.employee_id, e.name, e.manager_id, c.lvl + 1 AS lvl
    FROM employees e
    JOIN org_tree c
      ON e.manager_id = c.employee_id
    )
    SELECT *
    FROM org_tree
    ORDER BY lvl, manager_id, employee_id;

