## 项目概述

**项目名称：** CUSTOMER_ORDERS 模块迁移

**项目目标：** 将 Oracle 数据库中的客户订单模块完整迁移到 Snowflake

**预计时长：** 3 天（Day 16-18）

---

## 1. 迁移范围

### 1.1 数据库对象

**表（5 张）：**
1. `CUSTOMERS` - 客户信息表
2. `ORDERS` - 订单主表
3. `ORDER_ITEMS` - 订单明细表
4. `PRODUCTS` - 产品信息表
5. `CATEGORIES` - 产品分类表

**视图（2 个）：**
1. `CUSTOMER_ORDER_SUMMARY` - 客户订单汇总视图
2. `TOP_CUSTOMERS` - 最有价值客户视图（VIP）

**存储过程（3 个）：**
1. `calculate_order_total` - 计算订单总额
2. `process_refund` - 处理退款
3. `generate_invoice` - 生成发票

**函数（1 个）：**
1. `get_discount_rate` - 获取客户折扣率

### 1.2 数据量

| 表名 | 行数 | 数据大小 |
|------|------|---------|
| CUSTOMERS | 50,000 | 25 MB |
| ORDERS | 500,000 | 200 MB |
| ORDER_ITEMS | 1,200,000 | 500 MB |
| PRODUCTS | 10,000 | 5 MB |
| CATEGORIES | 50 | < 1 MB |

**总数据量：** ~730 MB

---

## 2. 功能需求

### 2.1 数据迁移要求

- ✅ 100% 数据准确性（无数据丢失）
- ✅ 保持数据完整性（主键、外键约束）
- ✅ 保持数据精度（小数位数）
- ✅ 保持 NULL 值处理

### 2.2 性能要求

| 指标 | 目标值 | 基准（Oracle） |
|------|--------|---------------|
| 单表查询响应时间 | ≤ 2 秒 | 5 秒 |
| JOIN 查询响应时间 | ≤ 5 秒 | 10 秒 |
| 聚合查询响应时间 | ≤ 10 秒 | 30 秒 |
| 并发支持 | 50 用户 | 20 用户 |

### 2.3 成本要求

- 运行成本不高于 Oracle（按相同查询量计算）
- 合理选择 Warehouse 大小

---

## 3. 技术要求

### 3.1 代码质量

- [ ] 所有 DDL 符合 Snowflake 最佳实践
- [ ] 所有 `NUMBER` 类型明确指定精度
- [ ] 所有存储过程使用 SQL Scripting
- [ ] Code Review 通过（≥ 2 个 Approve）

### 3.2 测试要求

- [ ] 单元测试覆盖率 ≥ 80%
- [ ] 所有存储过程有单元测试
- [ ] 数据验证 100% 通过
- [ ] 性能测试达标

### 3.3 文档要求

- [ ] 迁移方案设计文档
- [ ] 数据验证报告
- [ ] 性能测试报告
- [ ] 迁移总结报告

---

## 4. 详细需求

### 4.1 CUSTOMERS 表

**Oracle DDL：**
```sql
CREATE TABLE CUSTOMERS (
    customer_id NUMBER(10) PRIMARY KEY,
    customer_name VARCHAR2(100) NOT NULL,
    email VARCHAR2(100) UNIQUE,
    phone VARCHAR2(20),
    address CLOB,
    credit_limit NUMBER(12, 2),
    customer_type VARCHAR2(20),  -- 'RETAIL' or 'BUSINESS'
    created_date DATE DEFAULT SYSDATE
);
```


**Snowflake DDL**
```sql
CREATE TABLE CUSTOMERS (
    customer_id NUMBER(10,0) PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    address STRING,
    credit_limit NUMBER(12,2),
    customer_type VARCHAR(20),  -- 'RETAIL' 或 'BUSINESS'
    created_date TIMESTAMP_NTZ(0) 
);
```



**迁移要求：**
- `customer_id` 为主键
- `email` 唯一约束
- `address` 字段（CLOB）需要转换为 VARCHAR
- `credit_limit` 保持 2 位小数精度

### 4.2 ORDERS 表

**Oracle DDL：**
```sql
CREATE TABLE ORDERS (
    order_id NUMBER(10) PRIMARY KEY,
    customer_id NUMBER(10) NOT NULL,
    order_date DATE NOT NULL,
    total_amount NUMBER(12, 2),
    discount_amount NUMBER(10, 2),
    tax_amount NUMBER(10, 2),
    status VARCHAR2(20),  -- 'PENDING', 'COMPLETED', 'CANCELLED'
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES CUSTOMERS(customer_id)
);
```


**Snowflake DDL**
```sql
CREATE TABLE ORDERS (
    order_id NUMBER(10,0) PRIMARY KEY,
    customer_id NUMBER(10,0) NOT NULL,
    order_date TIMESTAMP_NTZ(0) NOT NULL,
    total_amount NUMBER(12,2),
    discount_amount NUMBER(10,2),
    tax_amount NUMBER(10,2),
    status VARCHAR(20),  -- 'PENDING', 'COMPLETED', 'CANCELLED'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- 外键在 Snowflake 中是信息性约束，不强制执行
    FOREIGN KEY (customer_id) REFERENCES CUSTOMERS(customer_id)
);
```
**迁移要求：**
- 外键约束必须保留
- 建议添加聚簇键（按 `order_date`）
- 金额字段保持 2 位小数


### 4.3 PRODUCTS 表

**Oracle DDL：**
```sql
CREATE TABLE PRODUCTS (
    product_id      NUMBER(10,0)     NOT NULL,
    product_name    VARCHAR(200)     NOT NULL,
    category_id     NUMBER(10,0),
    unit_price      NUMBER(10,2)      NOT NULL,
    status          VARCHAR(20),      -- ACTIVE / INACTIVE
    created_date    DATE              DEFAULT SYSDATE,
    CONSTRAINT pk_products PRIMARY KEY (product_id),
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id) REFERENCES CATEGORIES(category_id)
);
```


**Snowflake DDL**CURRENT_TIMESTAMP
```sql
CREATE TABLE PRODUCTS (
    product_id      NUMBER(10,0)     NOT NULL,
    product_name    VARCHAR(200)     NOT NULL,
    category_id     NUMBER(10,0),
    unit_price      NUMBER(10,2)     NOT NULL,
    status          VARCHAR(20),      -- ACTIVE / INACTIVE
    created_date    TIMESTAMP_NTZ(0) ,
    CONSTRAINT pk_products PRIMARY KEY (product_id),
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id) REFERENCES CATEGORIES(category_id)
);
```



### 4.4 CATEGORIES 表

**Oracle DDL：**
```sql
CREATE TABLE CATEGORIES (
    category_id     NUMBER(10,0)     NOT NULL,
    category_name   VARCHAR(100)     NOT NULL,
    description     VARCHAR(500),
    CONSTRAINT pk_categories PRIMARY KEY (category_id),
    CONSTRAINT uq_category_name UNIQUE (category_name)
);
```


**Snowflake DDL**
```sql
CREATE TABLE CATEGORIES (
    category_id     NUMBER(10,0)     NOT NULL,
    category_name   VARCHAR(100)     NOT NULL,
    description     VARCHAR(500),
    CONSTRAINT pk_categories PRIMARY KEY (category_id),
    CONSTRAINT uq_category_name UNIQUE (category_name)
);
```

### 4.5 ORDER_ITEMS 表

**Oracle DDL：**
```sql
CREATE TABLE ORDER_ITEMS (
    order_item_id   NUMBER(10,0)     NOT NULL,
    order_id        NUMBER(10,0)     NOT NULL,
    product_id      NUMBER(10,0)     NOT NULL,
    quantity        NUMBER(10,0)     NOT NULL,
    unit_price      NUMBER(10,2)     NOT NULL,
    CONSTRAINT pk_order_items PRIMARY KEY (order_item_id),
    CONSTRAINT fk_oi_order
        FOREIGN KEY (order_id) REFERENCES ORDERS(order_id),
    CONSTRAINT fk_oi_product
        FOREIGN KEY (product_id) REFERENCES PRODUCTS(product_id)
);
```


**Snowflake DDL**
```sql
CREATE TABLE ORDER_ITEMS (
    order_item_id   NUMBER(10,0)     NOT NULL,
    order_id        NUMBER(10,0)     NOT NULL,
    product_id      NUMBER(10,0)     NOT NULL,
    quantity        NUMBER(10,0)     NOT NULL,
    unit_price      NUMBER(10,2)     NOT NULL,
    CONSTRAINT pk_order_items PRIMARY KEY (order_item_id),
    CONSTRAINT fk_oi_order
        FOREIGN KEY (order_id) REFERENCES ORDERS(order_id),
    CONSTRAINT fk_oi_product
        FOREIGN KEY (product_id) REFERENCES PRODUCTS(product_id)
);
```

### 4.6 CUSTOMER_ORDER_SUMMARY 视图

**功能：** 每个客户的订单统计汇总

**Oracle 实现：**
```sql
CREATE OR REPLACE VIEW CUSTOMER_ORDER_SUMMARY AS
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id)            AS total_orders,
    SUM(o.total_amount)          AS total_order_amount,
    AVG(o.total_amount)          AS avg_order_amount,
    MAX(o.order_date)            AS last_order_date
FROM CUSTOMERS c
LEFT JOIN ORDERS o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.customer_name;
```


**Snowflake DDL**
```sql
CREATE OR REPLACE VIEW CUSTOMER_ORDER_SUMMARY AS
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id)            AS total_orders,
    SUM(o.total_amount)          AS total_order_amount,
    AVG(o.total_amount)          AS avg_order_amount,
    MAX(o.order_date)            AS last_order_date
FROM CUSTOMERS c
LEFT JOIN ORDERS o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.customer_name;
```

### 4.7 TOP_CUSTOMERS （VIP 客户） 视图

**功能：** 


总消费金额排名前 10

只统计 COMPLETED 订单

**Oracle 实现：**
```sql
CREATE OR REPLACE VIEW top_customers AS
SELECT
    customer_id,
    customer_name,
    lifetime_value
FROM (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(o.total_amount) AS lifetime_value,
        ROW_NUMBER() OVER (
            ORDER BY SUM(o.total_amount) DESC
        ) AS rn
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.status = 'COMPLETED'
    GROUP BY
        c.customer_id,
        c.customer_name
)
WHERE rn <= 10;
```


**Snowflake DDL**
```sql
CREATE OR REPLACE VIEW TOP_CUSTOMERS AS
SELECT
    c.customer_id,
    c.customer_name,
    SUM(o.total_amount) AS lifetime_value
FROM CUSTOMERS c
JOIN ORDERS o
    ON c.customer_id = o.customer_id
WHERE o.status = 'COMPLETED'
GROUP BY
    c.customer_id,
    c.customer_name
QUALIFY ROW_NUMBER() OVER (
    ORDER BY SUM(o.total_amount) DESC
) <= 10;
```


### 4.8 calculate_order_total 存储过程

**功能：** 计算订单总额（含税和折扣）

**Oracle 实现：**
```sql
CREATE OR REPLACE PROCEDURE calculate_order_total (
    p_order_id IN  NUMBER,
    p_total    OUT NUMBER
) AS
    v_subtotal NUMBER := 0;
    v_discount NUMBER := 0;
    v_tax      NUMBER := 0;
BEGIN
    -- 订单明细小计（SUM 在无数据时返回 NULL，不会抛 NO_DATA_FOUND）
    SELECT NVL(SUM(quantity * unit_price), 0)
    INTO v_subtotal
    FROM order_items
    WHERE order_id = p_order_id;

    -- 订单折扣与税
    SELECT
        NVL(discount_amount, 0),
        NVL(tax_amount, 0)
    INTO v_discount, v_tax
    FROM orders
    WHERE order_id = p_order_id;

    p_total := v_subtotal - v_discount + v_tax;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- orders 表中找不到订单
        p_total := 0;
END calculate_order_total;
/
```


**Snowflake DDL**
```sql
CREATE OR REPLACE PROCEDURE calculate_order_total(p_order_id FLOAT)
RETURNS FLOAT
LANGUAGE JAVASCRIPT
AS
$$
var v_subtotal = 0;
var v_discount = 0;
var v_tax = 0;

try {
    // 订单明细小计
    var stmt1 = snowflake.createStatement({
        sqlText: `SELECT IFNULL(SUM(quantity * unit_price), 0) AS subtotal
                  FROM ORDER_ITEMS
                  WHERE order_id = ?`,
        binds: [p_order_id]
    });
    var rs1 = stmt1.execute();
    if (rs1.next()) {
        v_subtotal = rs1.getColumnValue("SUBTOTAL");
    }

    // 订单折扣与税
    var stmt2 = snowflake.createStatement({
        sqlText: `SELECT IFNULL(discount_amount, 0) AS discount,
                         IFNULL(tax_amount, 0) AS tax
                  FROM ORDERS
                  WHERE order_id = ?`,
        binds: [p_order_id]
    });
    var rs2 = stmt2.execute();
    if (rs2.next()) {
        v_discount = rs2.getColumnValue("DISCOUNT");
        v_tax = rs2.getColumnValue("TAX");
    }

    // 计算总额
    return v_subtotal - v_discount + v_tax;

} catch (err) {
    // 找不到订单或其他错误
    return 0;
}
$$;
```

**迁移要求：**
- OUT 参数改为 RETURNS
- 使用 Snowflake SQL Scripting
- 保持业务逻辑一致



### 4.9 process_refund 存储过程

**功能：** 

将订单状态更新为 CANCELLED

写回退款金额

**Oracle 实现：**
```sql
CREATE OR REPLACE PROCEDURE process_refund (
    p_order_id IN  NUMBER,
    p_result   OUT VARCHAR2
) AS
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_exists
    FROM orders
    WHERE order_id = p_order_id;

    IF v_exists = 0 THEN
        p_result := 'ORDER NOT FOUND';
        RETURN;
    END IF;

    UPDATE orders
    SET status = 'CANCELLED'
    WHERE order_id = p_order_id;

    p_result := 'REFUND PROCESSED';

EXCEPTION
    WHEN OTHERS THEN
        p_result := 'ERROR: ' || SQLERRM;
END process_refund;
/
```



**Snowflake DDL**
```sql
CREATE OR REPLACE PROCEDURE process_refund(
    p_order_id NUMBER(10,0)
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO :v_exists
    FROM ORDERS
    WHERE order_id = :p_order_id;

    IF (v_exists = 0) THEN
        RETURN 'ORDER NOT FOUND';
    END IF;

    UPDATE ORDERS
    SET status = 'CANCELLED'
    WHERE order_id = :p_order_id;

    RETURN 'REFUND PROCESSED';
END;
$$;
```


### 4.10 generate_invoice 存储过程

**功能：** 

生成发票信息（逻辑示例）

返回发票文本内容

**Oracle 实现：**
```sql
CREATE OR REPLACE FUNCTION generate_invoice (
    p_order_id IN NUMBER
) RETURN VARCHAR2 AS
    v_customer_name VARCHAR2(200);
    v_total         NUMBER(12,2);
BEGIN
    SELECT
        c.customer_name,
        o.total_amount
    INTO
        v_customer_name,
        v_total
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_id = p_order_id;

    RETURN
        'Invoice for Order ' || p_order_id ||
        ', Customer: ' || v_customer_name ||
        ', Total Amount: ' || v_total;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'ORDER NOT FOUND';
    WHEN OTHERS THEN
        RETURN 'ERROR: ' || SQLERRM;
END generate_invoice;
/
```


**Snowflake DDL**
```sql
CREATE OR REPLACE PROCEDURE generate_invoice(
    p_order_id NUMBER(10,0)
)
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    v_customer_name STRING;
    v_total NUMBER(12,2);
BEGIN
    SELECT
        c.customer_name,
        o.total_amount
    INTO
        :v_customer_name,
        :v_total
    FROM ORDERS o
    JOIN CUSTOMERS c
        ON o.customer_id = c.customer_id
    WHERE o.order_id = :p_order_id;

    RETURN
        'Invoice for Order ' || p_order_id ||
        ', Customer: ' || v_customer_name ||
        ', Total Amount: ' || v_total;
END;
$$;
```


### 4.11 get_discount_rate 函数

**规则示例：** 

BUSINESS：10%

RETAIL：5%

其他：0%

**Oracle 实现：**
```sql
CREATE OR REPLACE FUNCTION get_discount_rate (
    p_customer_type IN VARCHAR2
) RETURN NUMBER
IS
BEGIN
    RETURN CASE
        WHEN p_customer_type = 'BUSINESS' THEN 0.10
        WHEN p_customer_type = 'RETAIL'  THEN 0.05
        ELSE 0.00
    END;
END get_discount_rate;
/
```

**Snowflake DDL**
```sql
CREATE OR REPLACE FUNCTION get_discount_rate(
    p_customer_type VARCHAR
)
RETURNS NUMBER(5,2)
LANGUAGE SQL
AS
$$
    CASE
        WHEN p_customer_type = 'BUSINESS' THEN 0.10
        WHEN p_customer_type = 'RETAIL' THEN 0.05
        ELSE 0.00
    END
$$;
```

---