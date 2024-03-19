SET SERVEROUTPUT ON

DECLARE
    view_count NUMBER;
BEGIN
    -- Count through views and drop them
    SELECT
        COUNT(*)
    INTO view_count
    FROM
        user_views;

    IF view_count > 0 THEN
        FOR view_rec IN (
            SELECT
                view_name
            FROM
                user_views
        ) LOOP
            EXECUTE IMMEDIATE 'DROP VIEW ' || view_rec.view_name;
            dbms_output.put_line('Dropped view: ' || view_rec.view_name);
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('All views have been deleted.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('No views found to delete.');
    END IF;
    
    -- RAKSHITH ADD YOUR CODE HERE
    
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error: ' || sqlerrm);
END;
/   
