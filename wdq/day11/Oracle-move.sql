-- =====================================================
-- SP 1：简单存储过程
-- 功能：参数传递 + 基本 CRUD（插入用户）
-- =====================================================
CREATE OR REPLACE PROCEDURE sp_create_user (
    p_user_id   IN NUMBER,
    p_user_name IN VARCHAR2,
    p_email     IN VARCHAR2
) AS
BEGIN
    INSERT INTO users (
        user_id,
        user_name,
        email,
        register_date
    )
    VALUES (
        p_user_id,
        p_user_name,
        p_email,
        SYSDATE
    );

    COMMIT;
END;
/

--迁移后
CREATE OR REPLACE PROCEDURE sp_create_user (
    p_user_id NUMBER,
    p_user_name STRING,
    p_email STRING
)
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    INSERT INTO users (
        user_id,
        user_name,
        email,
        register_date
    )
    VALUES (
        :p_user_id,
        :p_user_name,
        :p_email,
        CURRENT_TIMESTAMP()
    );

    RETURN 'SUCCESS';
END;
$$;


-- =====================================================
-- SP 2：使用游标和循环
-- 功能：遍历部门并统计每个部门的用户数
-- =====================================================
CREATE OR REPLACE PROCEDURE sp_count_users_by_dept AS

    CURSOR dept_cur IS
        SELECT department_id, department_name
        FROM departments;

    v_user_count NUMBER;

BEGIN
    FOR dept_rec IN dept_cur LOOP

        SELECT COUNT(*)
        INTO v_user_count
        FROM users
        WHERE department_id = dept_rec.department_id;

        INSERT INTO department_user_stats (
            department_id,
            department_name,
            user_count,
            stat_date
        )
        VALUES (
            dept_rec.department_id,
            dept_rec.department_name,
            v_user_count,
            SYSDATE
        );

    END LOOP;

    COMMIT;
END;
/


--迁移后
CREATE OR REPLACE PROCEDURE sp_count_users_by_dept()
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
var deptStmt = snowflake.createStatement({
    sqlText: `SELECT department_id, department_name FROM departments`
});

var deptRs = deptStmt.execute();

while (deptRs.next()) {
    var deptId = deptRs.getColumnValue(1);
    var deptName = deptRs.getColumnValue(2);

    var countStmt = snowflake.createStatement({
        sqlText: `SELECT COUNT(*) FROM users WHERE department_id = ?`,
        binds: [deptId]
    });

    var countRs = countStmt.execute();
    countRs.next();
    var userCount = countRs.getColumnValue(1);

    var insertStmt = snowflake.createStatement({
        sqlText: `
            INSERT INTO department_user_stats
            (department_id, department_name, user_count, stat_date)
            VALUES (?, ?, ?, CURRENT_DATE())
        `,
        binds: [deptId, deptName, userCount]
    });

    insertStmt.execute();
}

return 'SUCCESS';
$$;




-- =====================================================
-- SP 3：动态 SQL + 异常处理
-- 功能：根据传入表名动态删除数据并记录日志
-- =====================================================
CREATE OR REPLACE PROCEDURE sp_purge_table (
    p_table_name IN VARCHAR2
) AS
    v_sql   VARCHAR2(1000);
BEGIN
    -- 动态 SQL
    v_sql := 'DELETE FROM ' || p_table_name;

    EXECUTE IMMEDIATE v_sql;

    INSERT INTO purge_log (
        table_name,
        purge_time,
        status
    )
    VALUES (
        p_table_name,
        SYSDATE,
        'SUCCESS'
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO purge_log (
            table_name,
            purge_time,
            status,
            error_message
        )
        VALUES (
            p_table_name,
            SYSDATE,
            'FAILED',
            SQLERRM
        );

        ROLLBACK;
        RAISE;
END;
/


--迁移后
public void purgeTable(String tableName) {
    String sql = "DELETE FROM " + tableName;

    try (Connection conn = dataSource.getConnection();
         Statement stmt = conn.createStatement()) {

        stmt.executeUpdate(sql);

        logSuccess(tableName);

    } catch (Exception e) {
        logFailure(tableName, e.getMessage());
        throw new RuntimeException(e);
    }
}
