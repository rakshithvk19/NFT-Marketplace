SET SERVEROUTPUT ON;

DECLARE
    v_table_name      user_constraints.table_name%TYPE;
    v_constraint_name user_constraints.constraint_name%TYPE;
BEGIN
    -- Loop over the tables and constraints where the type 'R' constraints are being referred to
    FOR C IN (
        SELECT 
            uc.table_name, 
            uc.constraint_name
        FROM 
            user_constraints uc
        WHERE 
                uc.constraint_type = 'R'
            AND uc.table_name IN ('NFT_USER', 'NFT', 'REQUEST', 'BID', 
                                    'BIDDER', 'TRANSACTION', 'LISTING')
    ) LOOP
        v_table_name := c.table_name;
        v_constraint_name := c.constraint_name;
        
        -- Construct the ALTER TABLE statement to drop the constraint  
        EXECUTE IMMEDIATE 'ALTER TABLE ' 
                    || v_table_name 
                    || ' DROP CONSTRAINT ' 
                    || v_constraint_name;
        
        -- Output the message
        DBMS_OUTPUT.PUT_LINE('Dropped Constraint ' 
                            || v_constraint_name 
                            || ' from table ' 
                            || v_table_name);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred while dropping constraints: ' || SQLERRM);
END;
/

-- Dropping the user sequences
DECLARE
    sql_statement VARCHAR2(4000);
BEGIN
    FOR S IN (
        SELECT 
            sequence_name
        FROM 
            user_sequences
        WHERE 
            sequence_name NOT LIKE 'ISEQ$$%'
    ) LOOP
        sql_statement := 'DROP SEQUENCE ' || s.sequence_name;
        BEGIN
            EXECUTE IMMEDIATE sql_statement;
        EXCEPTION
            WHEN OTHERS THEN 
                DBMS_OUTPUT.PUT_LINE('Failed to drop sequence: ' || s.sequence_name || ' - Error: ' || SQLERRM);
        END;
    END LOOP;
END;
/

-- Dropping Tables
BEGIN
    FOR i IN (
        WITH mytables AS (
            SELECT 'NFT_USER' tname FROM dual
            UNION ALL
            SELECT 'NFT' FROM dual
            UNION ALL
            SELECT 'REQUEST' FROM dual
            UNION ALL
            SELECT 'TRANSACTION' FROM dual
            UNION ALL
            SELECT 'BIDDER' FROM dual
            UNION ALL
            SELECT 'BID' FROM dual
            UNION ALL
            SELECT 'LISTING' FROM dual
        )
        SELECT m.tname
        FROM mytables m
        INNER JOIN user_tables o ON m.tname = o.table_name
    ) LOOP
        BEGIN
            DBMS_OUTPUT.PUT_LINE('Dropping table: ' || i.tname);
            EXECUTE IMMEDIATE 'DROP TABLE ' || i.tname || ' CASCADE CONSTRAINTS';
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Failed to drop table ' || i.tname || ' - Error: ' || SQLERRM);
        END;
    END LOOP;
END;
/

CREATE SEQUENCE nft_marketplace_seq START WITH 1 INCREMENT BY 1 NOMAXVALUE NOCYCLE;

CREATE TABLE bid (
    bid_id             INTEGER NOT NULL,
    bidder_id          INTEGER,
    bid_amount         NUMBER(10, 2) NOT NULL,
    bid_date           TIMESTAMP,
    bid_status         VARCHAR2(64) NOT NULL,
    nft_nft_id         INTEGER NOT NULL,
    listing_listing_id INTEGER NOT NULL
);

CREATE UNIQUE INDEX bid__idx ON
    bid (
        listing_listing_id
    ASC );

ALTER TABLE bid ADD CONSTRAINT bid_pk PRIMARY KEY ( bid_id );

CREATE TABLE bidder (
    bidder_id        INTEGER NOT NULL,
    nft_user_user_id INTEGER NOT NULL,
    bid_bid_id       INTEGER NOT NULL,
    nft_user_id      INTEGER NOT NULL
);

ALTER TABLE bidder ADD CONSTRAINT bidder_pk PRIMARY KEY ( bidder_id );

CREATE TABLE listing (
    listing_id         INTEGER NOT NULL,
    nft_nft_id         INTEGER NOT NULL,
    listing_status     VARCHAR2(64) NOT NULL,
    listing_start_date DATE NOT NULL,
    listing_end_date   DATE NOT NULL,
    no_of_bids         INTEGER NOT NULL,
    starting_bid       INTEGER
);

COMMENT ON COLUMN listing.listing_status IS
    'completed
ongoing
cancelled';

ALTER TABLE listing ADD CONSTRAINT listing_pk PRIMARY KEY ( listing_id );

CREATE TABLE nft (
    nft_id           INTEGER NOT NULL,
    title            VARCHAR2(20 CHAR) NOT NULL,
    description      VARCHAR2(100 CHAR),
    mint_date        TIMESTAMP NOT NULL,
    file_url         httpuritype NOT NULL,
    token_id         VARCHAR2(50 CHAR) NOT NULL,
    price            NUMBER(10, 2) NOT NULL,
    status           VARCHAR2(20 CHAR) NOT NULL,
    nft_user_user_id INTEGER NOT NULL,
    nft_user_id      INTEGER NOT NULL
);

COMMENT ON COLUMN nft.status IS
    'It in an ENUM having the values
	AVAILABLE
	SOLD
	UNDER- REVIEW
	INACTIVE
	';

ALTER TABLE nft ADD CONSTRAINT nft_pk PRIMARY KEY ( nft_id );

CREATE TABLE nft_user (
    nft_user_id       INTEGER NOT NULL,
    nft_user_name     VARCHAR2(20 CHAR) NOT NULL,
    email             VARCHAR2(30 CHAR) NOT NULL,
    password          VARCHAR2(20 CHAR) NOT NULL,
    wallet_address    VARCHAR2(60 CHAR) NOT NULL,
    registration_date TIMESTAMP NOT NULL,
    last_login        TIMESTAMP NOT NULL,
    profile_picture   BLOB,
    role              VARCHAR2(64 CHAR)
);

COMMENT ON COLUMN nft_user.role IS
    'This is an ENUM having value
	BUYER
	SELLER
	BOTH';

ALTER TABLE nft_user ADD CONSTRAINT nft_user_pk PRIMARY KEY ( nft_user_id );

CREATE TABLE request (
    request_id       INTEGER NOT NULL,
    request_time     DATE NOT NULL,
    request_status   VARCHAR2(64) NOT NULL,
    nft_user_user_id INTEGER NOT NULL,
    nft_nft_id       INTEGER NOT NULL,
    nft_user_id      INTEGER NOT NULL
);

ALTER TABLE request ADD CONSTRAINT request_pk PRIMARY KEY ( request_id );

CREATE TABLE transaction (
    transcation_id     INTEGER NOT NULL,
    transaction_date   TIMESTAMP,
    transaction_price  NUMBER(10, 2),
    status             VARCHAR2(20) NOT NULL,
    nft_user_user_id   INTEGER NOT NULL,
    transaction_hash   VARCHAR2(60 CHAR) NOT NULL,
    listing_listing_id INTEGER NOT NULL,
    request_request_id INTEGER NOT NULL,
    nft_user_id        INTEGER NOT NULL
);

CREATE UNIQUE INDEX transaction__idx ON
    transaction (
        listing_listing_id
    ASC );

CREATE UNIQUE INDEX transaction__idxv1 ON
    transaction (
        request_request_id
    ASC );

ALTER TABLE transaction ADD CONSTRAINT transaction_pk PRIMARY KEY ( transcation_id,
                                                                    nft_user_id );

ALTER TABLE bid
    ADD CONSTRAINT bid_listing_fk FOREIGN KEY ( listing_listing_id )
        REFERENCES listing ( listing_id );

ALTER TABLE bid
    ADD CONSTRAINT bid_nft_fk FOREIGN KEY ( nft_nft_id )
        REFERENCES nft ( nft_id );

ALTER TABLE bidder
    ADD CONSTRAINT bidder_bid_fk FOREIGN KEY ( bid_bid_id )
        REFERENCES bid ( bid_id );

ALTER TABLE bidder
    ADD CONSTRAINT bidder_nft_user_fk FOREIGN KEY ( nft_user_user_id )
        REFERENCES nft_user ( nft_user_id );

ALTER TABLE listing
    ADD CONSTRAINT listing_nft_fk FOREIGN KEY ( nft_nft_id )
        REFERENCES nft ( nft_id );

ALTER TABLE nft
    ADD CONSTRAINT nft_nft_user_fk FOREIGN KEY ( nft_user_user_id )
        REFERENCES nft_user ( nft_user_id );

ALTER TABLE request
    ADD CONSTRAINT request_nft_fk FOREIGN KEY ( nft_nft_id )
        REFERENCES nft ( nft_id );

ALTER TABLE request
    ADD CONSTRAINT request_nft_user_fk FOREIGN KEY ( nft_user_user_id )
        REFERENCES nft_user ( nft_user_id );

ALTER TABLE transaction
    ADD CONSTRAINT transaction_listing_fk FOREIGN KEY ( listing_listing_id )
        REFERENCES listing ( listing_id );

ALTER TABLE transaction
    ADD CONSTRAINT transaction_nft_user_fk FOREIGN KEY ( nft_user_user_id )
        REFERENCES nft_user ( nft_user_id );

ALTER TABLE transaction
    ADD CONSTRAINT transaction_request_fk FOREIGN KEY ( request_request_id )
        REFERENCES request ( request_id );
        
COMMIT;