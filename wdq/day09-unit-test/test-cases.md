
## 1. 测试用例列表

### 1.1 正常场景

| 用例ID | 测试场景 | 输入 | 预期输出 |
|--------|---------|------|---------|
| TC-001 | 单个商品订单 | quantity=2, price=100.00 | total=200.00 |
| TC-002 | 多个商品订单 | 3个商品 | total=各商品金额之和 |
| TC-003 | 包含折扣 | discount=10% | total=原价*0.9 |
| TC-004 | 包含税费 | tax=5% | total=原价*1.05 |

### 1.2 边界场景

| 用例ID | 测试场景 | 输入 | 预期输出 |
|--------|---------|------|---------|
| TC-010 | 数量为0 | quantity=0 | total=0.00 |
| TC-011 | 价格为0 | price=0.00 | total=0.00 |
| TC-012 | 最大金额 | price=999999.99 | 正确计算 |
| TC-013 | 小数精度 | price=10.555 | total=10.56（四舍五入） |

### 1.3 异常场景

| 用例ID | 测试场景 | 输入 | 预期行为 |
|--------|---------|------|---------|
| TC-020 | 负数数量 | quantity=-1 | 抛出 IllegalArgumentException |
| TC-021 | 负数价格 | price=-10.00 | 抛出 IllegalArgumentException |
| TC-022 | NULL 输入 | orderItems=null | 抛出 NullPointerException |

---

## 2. 测试代码示例

### 2.1 正常场景测试

```java
@Test
@DisplayName("TC-001: 单个商品订单金额计算")
void testSingleItemOrder() {
    // Given
    OrderItem item = new OrderItem("Product A", 2, new BigDecimal("100.00"));
    Order order = new Order(List.of(item));

    // When
    BigDecimal total = orderCalculator.calculateTotal(order);

    // Then
    assertEquals(new BigDecimal("200.00"), total);
}

@Test
@DisplayName("TC-003: 包含折扣的订单")
void testOrderWithDiscount() {
    // Given
    OrderItem item = new OrderItem("Product B", 1, new BigDecimal("100.00"));
    Order order = new Order(List.of(item));
    order.setDiscount(new BigDecimal("0.10"));  // 10% 折扣

    // When
    BigDecimal total = orderCalculator.calculateTotal(order);

    // Then
    assertEquals(new BigDecimal("90.00"), total);
}
```

### 2.2 边界场景测试

```java
@Test
@DisplayName("TC-013: 小数精度测试 - 四舍五入")
void testDecimalPrecision() {
    // Given
    OrderItem item = new OrderItem("Product C", 1, new BigDecimal("10.555"));
    Order order = new Order(List.of(item));

    // When
    BigDecimal total = orderCalculator.calculateTotal(order);

    // Then
    // Snowflake 和 Oracle 都应该保持2位小数精度
    assertEquals(new BigDecimal("10.56"), total);
    assertEquals(2, total.scale());
}
```

### 2.3 异常场景测试

```java
@Test
@DisplayName("TC-020: 负数数量应该抛出异常")
void testNegativeQuantity() {
    // Given
    OrderItem item = new OrderItem("Product D", -1, new BigDecimal("100.00"));

    // When & Then
    assertThrows(IllegalArgumentException.class, () -> {
        new Order(List.of(item));
    }, "数量不能为负数");
}
```

---

## 3. 数据库测试（Oracle vs Snowflake）

### 3.1 对比测试

```java
@Test
@DisplayName("验证 Oracle 和 Snowflake 计算结果一致")
void testOracleVsSnowflake() {
    // Given
    String orderId = "ORD-12345";

    // When
    BigDecimal oracleTotal = oracleRepository.calculateOrderTotal(orderId);
    BigDecimal snowflakeTotal = snowflakeRepository.calculateOrderTotal(orderId);

    // Then
    assertEquals(oracleTotal, snowflakeTotal,
        "Oracle 和 Snowflake 的计算结果应该一致");
}
```

### 3.2 聚合函数测试

```java
@Test
@DisplayName("验证 SUM 函数精度")
void testSumPrecision() {
    // Given: 插入测试数据
    testRepository.insertTestOrders(List.of(
        new BigDecimal("10.11"),
        new BigDecimal("20.22"),
        new BigDecimal("30.33")
    ));

    // When: 在 Snowflake 中计算
    BigDecimal total = snowflakeRepository.sumOrderAmounts();

    // Then: 验证精度
    assertEquals(new BigDecimal("60.66"), total);
    assertEquals(2, total.scale(), "小数位数应该是2位");
}