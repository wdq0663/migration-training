public class OrderReportDao {

    private static final String SNOWFLAKE_URL =
            "jdbc:snowflake://abc123.snowflakecomputing.com/?db=APP_DB&schema=PUBLIC";

    public List<OrderReport> getOrderSummary() throws SQLException {

        Connection conn = DriverManager.getConnection(
                SNOWFLAKE_URL, "sf_user", "sf_pwd"
        );

        String sql =
                "SELECT c.country, " +
                        "       COUNT(*) AS order_cnt, " +
                        "       SUM(o.amount) AS total_amount " +
                        "FROM customers c " +
                        "JOIN orders o ON c.id = o.customer_id " +
                        "WHERE o.created_date >= CURRENT_DATE - 30 " +
                        "GROUP BY c.country";

        PreparedStatement ps = conn.prepareStatement(sql);
        ResultSet rs = ps.executeQuery();

        List<OrderReport> reports = new ArrayList<>();

        while (rs.next()) {
            OrderReport r = new OrderReport();
            r.setCountry(rs.getString("country"));
            r.setOrderCount(rs.getLong("order_cnt"));
            r.setTotalAmount(rs.getBigDecimal("total_amount"));
            reports.add(r);
        }

        rs.close();
        ps.close();
        conn.close();

        return reports;
    }
}
