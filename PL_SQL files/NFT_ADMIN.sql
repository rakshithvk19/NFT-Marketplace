SET SERVEROUTPUT ON

DECLARE
    user_exists      NUMBER;
    user_connected   NUMBER;
BEGIN
    -- Check if the user already exists
    SELECT COUNT(*)
    INTO user_exists
    FROM all_users
    WHERE username = 'APP_ADMIN';

    -- Check if the user is already connected
    SELECT COUNT(*)
    INTO user_connected
    FROM v$session
    WHERE username = 'APP_ADMIN';

    -- Drop the user if it already exists and is not connected
    IF user_exists > 0 THEN
        IF user_connected = 0 THEN
            EXECUTE IMMEDIATE 'DROP USER APP_ADMIN CASCADE';
            DBMS_OUTPUT.PUT_LINE('User APP_ADMIN has been dropped');
        ELSE
            DBMS_OUTPUT.PUT_LINE('User is connected to the Database and cannot be dropped at this point');
            RETURN;
        END IF;
    ELSE
        DBMS_OUTPUT.PUT_LINE('User APP_ADMIN does not exist');
    END IF;

    -- Create user
    EXECUTE IMMEDIATE 'CREATE USER APP_ADMIN IDENTIFIED BY AppAdminNFTMarketplace2024';

    -- Grant privileges
    EXECUTE IMMEDIATE 'GRANT CONNECT, RESOURCE, CREATE TABLE, CREATE VIEW, CREATE USER, DROP USER, CREATE SESSION, CREATE PROCEDURE, CREATE SEQUENCE, CREATE TRIGGER TO APP_ADMIN WITH ADMIN OPTION';
    EXECUTE IMMEDIATE 'GRANT SELECT ON dba_users TO APP_ADMIN';

    -- Set quota
    EXECUTE IMMEDIATE 'ALTER USER APP_ADMIN QUOTA 10M ON DATA';
    
    DBMS_OUTPUT.PUT_LINE('APP_ADMIN created with privileges');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
END;
/
