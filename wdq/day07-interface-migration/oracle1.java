public class UserDao {

    private static final String ORACLE_URL =
            "jdbc:oracle:thin:@//localhost:1521/ORCL";

    public User findUserById(long userId) throws SQLException {

        Connection conn = DriverManager.getConnection(
                ORACLE_URL, "oracle_user", "oracle_pwd"
        );

        String sql =
                "SELECT id, username, created_date " +
                        "FROM users " +
                        "WHERE id = ? " +
                        "AND created_date <= SYSDATE";

        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setLong(1, userId);

        ResultSet rs = ps.executeQuery();

        User user = null;
        if (rs.next()) {
            user = new User();
            user.setId(rs.getLong("id"));
            user.setUsername(rs.getString("username"));
            user.setCreatedDate(rs.getDate("created_date"));
        }

        rs.close();
        ps.close();
        conn.close();

        return user;
    }
}
