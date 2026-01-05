Oracle → Snowflake Migration Tool 原理解析

这个脚本实际上分为 四大模块：

数据类型映射

表名提取

列解析与 DDL 生成

SQL 方言转换

数据类型映射 (TYPE_MAPPING)
TYPE_MAPPING = {
"NUMBER": "NUMBER",
"VARCHAR2": "VARCHAR",
"CHAR": "CHAR",
"DATE": "DATE",
"TIMESTAMP": "TIMESTAMP",
"CLOB": "STRING"
}


目的：Oracle 数据类型 → Snowflake 对应类型

原理：

遍历列定义时，先提取 Oracle 类型

查字典找到对应 Snowflake 类型

支持 NUMBER、VARCHAR2、CHAR、DATE、TIMESTAMP、CLOB 等常用类型

举例：VARCHAR2(20) → VARCHAR(20)

表名提取 (extract_table_name)
def extract_table_name(ddl: str) -> str:
match = re.search(
r"CREATE\s+(?:OR\s+REPLACE\s+)?TABLE\s+((?:\"[^\"]+\"|\w+)(?:\.(?:\"[^\"]+\"|\w+))?)",
ddl,
re.IGNORECASE
)


目的：从 Oracle DDL 中提取表名，支持各种真实写法

特点：

支持 CREATE TABLE 和 CREATE OR REPLACE TABLE

支持 schema-qualified（如 sales.orders）

支持双引号 "ORDERS"

原理：

正则匹配表名部分

如果有 schema，用 split(".")[-1] 只保留表名

去掉双引号，保证 Snowflake 语法正确

列解析与 DDL 生成 (convert_column + convert_ddl)
(a) 单列转换 convert_column
def convert_column(line: str) -> str:
line = line.strip().rstrip(",")
parts = line.split()
col_name = parts[0]
oracle_type = parts[1]


步骤：

去除首尾空格和尾部逗号

提取列名和类型

映射 Oracle 类型到 Snowflake 类型

处理 NOT NULL

处理 DEFAULT，同时把 Oracle 特定函数转换：

SYSDATE → CURRENT_DATE

SYSTIMESTAMP → CURRENT_TIMESTAMP

输出示例：

order_date DATE DEFAULT CURRENT_DATE

(b) DDL 生成 convert_ddl
block_match = re.search(
r"CREATE\s+(?:OR\s+REPLACE\s+)?TABLE\s+[^\(]+\((.*)\)\s*;",
oracle_ddl,
re.IGNORECASE | re.DOTALL
)


核心思想：

用正则一次性抓出括号内列块

re.DOTALL 允许匹配多行

贪婪匹配 (.*) 获取完整列列表

逐行解析：

忽略空行和注释

只处理以 列名 + 类型 开头的行

调用 convert_column 生成 Snowflake 列定义

生成最终 DDL：

CREATE OR REPLACE TABLE orders (
order_id NUMBER(18,0) NOT NULL,
...
);
-- MANUAL STEP REQUIRED: indexes, constraints, partitions


原理：先抓列块，再逐行解析，避免了之前“in_cols + 行首匹配”的脆弱逻辑
稳定应对企业真实 DDL（跨行、缩进、注释、OR REPLACE、schema、双引号）

SQL 方言转换 (translate_sql)
def translate_sql(sql_text: str) -> str:
sql_text = re.sub(r'\bSYSDATE\b', 'CURRENT_DATE', sql_text, flags=re.IGNORECASE)
sql_text = re.sub(r'\bSYSTIMESTAMP\b', 'CURRENT_TIMESTAMP', sql_text, flags=re.IGNORECASE)


作用：将 Oracle SQL 语句转换为 Snowflake 可执行语法

原理：

使用正则批量替换 Oracle 特定函数

可扩展为更多方言规则，例如：

NVL → COALESCE

TO_CHAR(date) → TO_VARCHAR(date)

举例：

INSERT INTO orders(order_id, order_date) VALUES(1, SYSDATE);


转换后：

INSERT INTO orders(order_id, order_date) VALUES(1, CURRENT_DATE);

脚本整体流程

读取 Oracle DDL 文件

调用 convert_ddl() → 生成 Snowflake DDL

调用 translate_sql() → 简单 SQL 方言转换

输出结果到控制台,结果如图所示
![](test1.png)
Oracle DDL 特点

使用 CREATE OR REPLACE TABLE

多个高精度 NUMBER(p,s) 数值列

行内定义 PRIMARY KEY

独立 ALTER TABLE ... CLUSTER BY 语句

包含注释、缩进，接近真实生产 DDL

该示例主要验证了脚本在复杂 DDL 场景下的稳定性：

正确识别 OR REPLACE 表名

精确映射高精度 NUMBER 类型

自动完成 CURRENT_TIMESTAMP 转换

安全忽略 Oracle 物理特性（CLUSTER BY）

这体现了工具的设计取向：只自动迁移 Snowflake 语义明确的对象。

![](test2.png)
Oracle DDL 特点

使用 DEFAULT SYSDATE、DEFAULT SYSTIMESTAMP

包含独立的 CREATE INDEX 语句

表结构相对简单，但包含典型 Oracle 方言

说明

该示例重点展示：

SYSDATE → CURRENT_DATE

SYSTIMESTAMP → CURRENT_TIMESTAMP

SQL 方言通过正则规则安全转换

同时可以看到：

Oracle 索引未被自动迁移

避免将 OLTP 思维下的索引直接带入 Snowflake

![](test3.png)
Oracle DDL 特点

表结构与主键定义分离

使用 ALTER TABLE ADD CONSTRAINT PRIMARY KEY

常见于规范化建模或老系统

说明

该示例体现了工具的重要原则：

表结构优先迁移

约束不盲目自动化

明确提示人工决策



为什么这个脚本稳定
问题	解决方案
表名带 OR REPLACE、schema、双引号	extract_table_name 正则处理
列块跨行、缩进、注释	convert_ddl 正则抓列块 + strip +过滤
Oracle 类型差异	TYPE_MAPPING + DEFAULT 函数转换
SQL 方言差异	translate_sql 正则批量替换