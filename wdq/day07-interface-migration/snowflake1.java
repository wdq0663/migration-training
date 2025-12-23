public class UserDao {

    private static final String SNOWFLAKE_URL =
            "jdbc:snowflake://abc123.snowflakecomputing.com/?db=APP_DB&schema=PUBLIC";

    public User findUserById(long userId) throws SQLException {

        Connection conn = DriverManager.getConnection(
                SNOWFLAKE_URL, "sf_user", "sf_pwd"
        );

        String sql =
                "SELECT id, username, created_date " +
                        "FROM users " +
                        "WHERE id = ? " +
                        "AND created_date <= CURRENT_DATE";

        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setLong(1, userId);

        ResultSet rs = ps.executeQuery();

        User user = null;
        if (rs.next()) {
            user = new User();
            user.setId(rs.getLong("id"));
            user.setUsername(rs.getString("username"));
            user.setCreatedDate(
                    rs.getTimestamp("created_date").toLocalDateTime()
            );
        }

        rs.close();
        ps.close();
        conn.close();

        return user;
    }
}
