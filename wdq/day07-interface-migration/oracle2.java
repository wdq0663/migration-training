public class OrderReportDao {

    private static final String ORACLE_URL =
            "jdbc:oracle:thin:@//localhost:1521/ORCL";

    public List<OrderReport> getOrderSummary() throws SQLException {

        Connection conn = DriverManager.getConnection(
                ORACLE_URL, "oracle_user", "oracle_pwd"
        );

        String sql =
                "SELECT c.country, COUNT(*) AS order_cnt, SUM(o.amount) AS total_amount " +
                        "FROM customers c, orders o " +
                        "WHERE c.id = o.customer_id " +
                        "AND o.created_date >= SYSDATE - 30 " +
                        "GROUP BY c.country";

        PreparedStatement ps = conn.prepareStatement(sql);
        ResultSet rs = ps.executeQuery();

        List<OrderReport> reports = new ArrayList<>();

        while (rs.next()) {
            OrderReport r = new OrderReport();
            r.setCountry(rs.getString("country"));
            r.setOrderCount(rs.getInt("order_cnt"));
            r.setTotalAmount(rs.getDouble("total_amount"));
            reports.add(r);
        }

        rs.close();
        ps.close();
        conn.close();

        return reports;
    }
}
