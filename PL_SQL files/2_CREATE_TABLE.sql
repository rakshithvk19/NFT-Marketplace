-- Run this script as APP_Admin
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
    file_url         VARCHAR2(100 CHAR) NOT NULL,
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
        

-- Inserting into nft user entity.
INSERT INTO nft_user (nft_user_id, nft_user_name, email, password, wallet_address, registration_date, last_login, role)
VALUES (1, 'John Doe', 'john.doe@example.com', 'pass123word', '0x0987654321ABCDEF', TIMESTAMP '2022-03-14 12:00:00', TIMESTAMP '2022-03-14 12:00:00', 'BUYER');

INSERT INTO nft_user (nft_user_id, nft_user_name, email, password, wallet_address, registration_date, last_login, role)
VALUES (2, 'Jane Doe', 'jane.doe@example.com', 'abcXYZ789', '0xABCDEF0987654321', TIMESTAMP '2022-03-14 12:00:00', TIMESTAMP '2022-03-14 12:00:00', 'SELLER');

INSERT INTO nft_user (nft_user_id, nft_user_name, email, password, wallet_address, registration_date, last_login, role)
VALUES (3, 'LeBron James', 'lebron.james@example.com', 'leb23JAM!', '0xABC123DEF456GHI789', TIMESTAMP '2022-03-14 12:00:00', TIMESTAMP '2022-03-14 12:00:00', 'BUYER');

INSERT INTO nft_user (nft_user_id, nft_user_name, email, password, wallet_address, registration_date, last_login, role)
VALUES (4, 'Michael Jordan', 'michael.jordan@example.com', 'jorM1k@@', '0xXYZ987ABC123DEF456', TIMESTAMP '2022-03-14 12:00:00', TIMESTAMP '2022-03-14 12:00:00', 'SELLER');

INSERT INTO nft_user (nft_user_id, nft_user_name, email, password, wallet_address, registration_date, last_login, role)
VALUES (5, 'Kareem Abdul-Jabbar', 'kareem.abduljabbar@example.com', 'KAJ$$456', '0x987GHI654JKL321MNO', TIMESTAMP '2022-03-14 12:00:00', TIMESTAMP '2022-03-14 12:00:00', 'BUYER');

INSERT INTO nft_user (nft_user_id, nft_user_name, email, password, wallet_address, registration_date, last_login, role)
VALUES (6, 'Magic Johnson', 'magic.johnson@example.com', 'magiC0ol!', '0x654PQR321STU987VWX', TIMESTAMP '2022-03-14 12:00:00', TIMESTAMP '2022-03-14 12:00:00', 'SELLER');

INSERT INTO nft_user (nft_user_id, nft_user_name, email, password, wallet_address, registration_date, last_login, role)
VALUES (7, 'Larry Bird', 'larry.bird@example.com', 'BirD3Lar!', '0x321XYZ987MNO654PQR', TIMESTAMP '2022-03-14 12:00:00', TIMESTAMP '2022-03-14 12:00:00', 'BUYER');

INSERT INTO nft_user (nft_user_id, nft_user_name, email, password, wallet_address, registration_date, last_login, role)
VALUES (8, 'Shaquille ONeal', 'shaquille.oneal@example.com', 'shaQ$$$01', '0xGHI789ABCDEF123XYZ', TIMESTAMP '2022-03-14 12:00:00', TIMESTAMP '2022-03-14 12:00:00', 'SELLER');

INSERT INTO nft_user (nft_user_id, nft_user_name, email, password, wallet_address, registration_date, last_login, role)
VALUES (9, 'Kobe Bryant', 'kobe.bryant@example.com', 'bry@nt24', '0xGHI321JKL987MNO654', TIMESTAMP '2022-03-14 12:00:00', TIMESTAMP '2022-03-14 12:00:00', 'BUYER');

INSERT INTO nft_user (nft_user_id, nft_user_name, email, password, wallet_address, registration_date, last_login, role)
VALUES (10, 'Tim Duncan', 'tim.duncan@example.com', 'DuNC@N555', '0x456DEF123ABC789GHI', TIMESTAMP '2022-03-14 12:00:00', TIMESTAMP '2022-03-14 12:00:00', 'SELLER');

INSERT INTO nft_user (nft_user_id, nft_user_name, email, password, wallet_address, registration_date, last_login, role)
VALUES (11, 'Kevin Durant', 'kevin.durant@example.com', 'durantK123', '0x789GHI456DEF123ABC', TIMESTAMP '2022-03-14 12:00:00', TIMESTAMP '2022-03-14 12:00:00', 'BUYER');

INSERT INTO nft_user (nft_user_id, nft_user_name, email, password, wallet_address, registration_date, last_login, role)
VALUES (12, 'Chris Paul', 'chris.paul@example.com', 'cPauL987', '0xJKL321MNO654PQR987', TIMESTAMP '2022-03-14 12:00:00', TIMESTAMP '2022-03-14 12:00:00', 'SELLER');



-- Inserting into nft entity.
INSERT INTO nft (nft_id, title, description, mint_date, file_url, token_id, price, status, nft_user_user_id, nft_user_id)
VALUES (1, 'Glimpse of Galaxy', 'Experience the beauty of distant galaxies with this mesmerizing digital art piece.', TIMESTAMP '2022-03-14 12:00:00', 'http://example.com/galaxy_nft.jpg', 'token667748', 300.00, 'AVAILABLE', 7, 7);

INSERT INTO nft (nft_id, title, description, mint_date, file_url, token_id, price, status, nft_user_user_id, nft_user_id)
VALUES (2, 'Mystical Mountains', 'Journey through misty peaks and hidden valleys with this enchanting landscape photograph.', TIMESTAMP '2022-03-14 12:00:00', 'http://example.com/mountain_nft.jpg', 'token667749', 280.00, 'AVAILABLE', 8, 8);

INSERT INTO nft (nft_id, title, description, mint_date, file_url, token_id, price, status, nft_user_user_id, nft_user_id)
VALUES (3, 'Dreamy Dolphins', 'Dive into the depths of the ocean.', TIMESTAMP '2022-03-14 12:00:00', 'http://example.com/dolphin_nft.jpg', 'token667750', 320.00, 'AVAILABLE', 5, 5);

INSERT INTO nft (nft_id, title, description, mint_date, file_url, token_id, price, status, nft_user_user_id, nft_user_id)
VALUES (4, 'Celestial Serenity', 'Find peace and tranquility amidst the stars with this serene celestial artwork.', TIMESTAMP '2022-03-14 12:00:00', 'http://example.com/celestial_nft.jpg', 'token667751', 340.00, 'AVAILABLE', 9, 9);

INSERT INTO nft (nft_id, title, description, mint_date, file_url, token_id, price, status, nft_user_user_id, nft_user_id)
VALUES (5, 'Whimsical Woodlands', 'Explore the magical wonders of the forest with this whimsical woodland illustration.', TIMESTAMP '2022-03-14 12:00:00', 'http://example.com/woodland_nft.jpg', 'token667752', 260.00, 'AVAILABLE', 10, 10);

INSERT INTO nft (nft_id, title, description, mint_date, file_url, token_id, price, status, nft_user_user_id, nft_user_id)
VALUES (6, 'Surreal Seascape', 'Dive into a surreal world where the sea meets the sky in harmony with this mesmerizing seascape.', TIMESTAMP '2022-03-14 12:00:00', 'http://example.com/seascape_nft.jpg', 'token667753', 290.00, 'AVAILABLE', 6, 6);

INSERT INTO nft (nft_id, title, description, mint_date, file_url, token_id, price, status, nft_user_user_id, nft_user_id)
VALUES (7, 'Whispering Water', 'Listen to the soothing whispers of cascading waterfalls.', TIMESTAMP '2022-03-14 12:00:00', 'http://example.com/waterfall_nft.jpg', 'token667754', 270.00, 'AVAILABLE', 11, 11);

INSERT INTO nft (nft_id, title, description, mint_date, file_url, token_id, price, status, nft_user_user_id, nft_user_id)
VALUES (8, 'Aurora Dreams', 'Be mesmerized by the dancing lights of the aurora borealis.', TIMESTAMP '2022-03-14 12:00:00', 'http://example.com/aurora_nft.jpg', 'token667755', 310.00, 'AVAILABLE', 12, 12);

INSERT INTO nft (nft_id, title, description, mint_date, file_url, token_id, price, status, nft_user_user_id, nft_user_id)
VALUES (9, 'Enchanted Forest', 'Step into an enchanted realm where magic and nature intertwine with this enchanting forest artwork.', TIMESTAMP '2022-03-14 12:00:00', 'http://example.com/enchanted_forest_nft.jpg', 'token667756', 330.00, 'AVAILABLE', 4, 4);

INSERT INTO nft (nft_id, title, description, mint_date, file_url, token_id, price, status, nft_user_user_id, nft_user_id)
VALUES (10, 'Serenading Songbirds', 'Listen to the sweet melodies of songbirds.', TIMESTAMP '2022-03-14 12:00:00', 'http://example.com/songbirds_nft.jpg', 'token667757', 300.00, 'AVAILABLE', 3, 3);

-- Inserting into listing entity.
INSERT INTO listing (listing_id, nft_nft_id, listing_status, listing_start_date, listing_end_date, no_of_bids, starting_bid)
VALUES (1, 1, 'ongoing', TIMESTAMP '2022-03-14 12:00:00', TIMESTAMP '2022-03-21 12:00:00', 1, 100);

INSERT INTO listing (listing_id, nft_nft_id, listing_status, listing_start_date, listing_end_date, no_of_bids, starting_bid)
VALUES (2, 2, 'closed', TIMESTAMP '2022-03-14 12:00:00', TIMESTAMP '2022-03-20 12:00:00', 3, 150);

INSERT INTO listing (listing_id, nft_nft_id, listing_status, listing_start_date, listing_end_date, no_of_bids, starting_bid)
VALUES (3, 3, 'ongoing', TIMESTAMP '2022-03-14 12:00:00', TIMESTAMP '2022-03-22 12:00:00', 2, 120);

INSERT INTO listing (listing_id, nft_nft_id, listing_status, listing_start_date, listing_end_date, no_of_bids, starting_bid)
VALUES (4, 4, 'ongoing', TIMESTAMP '2022-03-14 12:00:00', TIMESTAMP '2022-03-23 12:00:00', 0, 200);

INSERT INTO listing (listing_id, nft_nft_id, listing_status, listing_start_date, listing_end_date, no_of_bids, starting_bid)
VALUES (5, 5, 'ongoing', TIMESTAMP '2022-03-14 12:00:00', TIMESTAMP '2022-03-24 12:00:00', 4, 180);

-- Inserting into bid entity.
INSERT INTO bid (bid_id, bidder_id, bid_amount, bid_date, bid_status, nft_nft_id, listing_listing_id)
VALUES (2, 2, 120.00, TIMESTAMP '2022-03-15 12:00:00', 'Open', 3, 3);

INSERT INTO bid (bid_id, bidder_id, bid_amount, bid_date, bid_status, nft_nft_id, listing_listing_id)
VALUES (3, 3, 180.00, TIMESTAMP '2022-03-16 12:00:00', 'Open', 5, 5);

INSERT INTO bid (bid_id, bidder_id, bid_amount, bid_date, bid_status, nft_nft_id, listing_listing_id)
VALUES (4, 4, 220.00, TIMESTAMP '2022-03-17 12:00:00', 'Open', 4, 4);

INSERT INTO bid (bid_id, bidder_id, bid_amount, bid_date, bid_status, nft_nft_id, listing_listing_id)
VALUES (5, 5, 250.00, TIMESTAMP '2022-03-18 12:00:00', 'Open', 2, 2);

INSERT INTO bid (bid_id, bidder_id, bid_amount, bid_date, bid_status, nft_nft_id, listing_listing_id)
VALUES (6, 6, 190.00, TIMESTAMP '2022-03-19 12:00:00', 'Open', 1, 1);


-- Inserting into bidder entity.
INSERT INTO bidder (bidder_id, nft_user_user_id, bid_bid_id, nft_user_id)
VALUES (2, 2, 2, 2);

INSERT INTO bidder (bidder_id, nft_user_user_id, bid_bid_id, nft_user_id)
VALUES (3, 3, 3, 3);

INSERT INTO bidder (bidder_id, nft_user_user_id, bid_bid_id, nft_user_id)
VALUES (4, 4, 4, 4);

INSERT INTO bidder (bidder_id, nft_user_user_id, bid_bid_id, nft_user_id)
VALUES (5, 5, 5, 5);

INSERT INTO bidder (bidder_id, nft_user_user_id, bid_bid_id, nft_user_id)
VALUES (6, 6, 6, 6);



-- Inserting into request entity.
INSERT INTO request (request_id, request_time, request_status, nft_user_user_id, nft_nft_id, nft_user_id)
VALUES (2, DATE '2022-03-14', 'pending', 2, 2, 2);

INSERT INTO request (request_id, request_time, request_status, nft_user_user_id, nft_nft_id, nft_user_id)
VALUES (3, DATE '2022-03-14', 'pending', 3, 3, 3);

INSERT INTO request (request_id, request_time, request_status, nft_user_user_id, nft_nft_id, nft_user_id)
VALUES (4, DATE '2022-03-14', 'pending', 4, 4, 4);

INSERT INTO request (request_id, request_time, request_status, nft_user_user_id, nft_nft_id, nft_user_id)
VALUES (5, DATE '2022-03-14', 'pending', 5, 5, 5);

INSERT INTO request (request_id, request_time, request_status, nft_user_user_id, nft_nft_id, nft_user_id)
VALUES (6, DATE '2022-03-14', 'pending', 6, 6, 6);


-- Inserting into transaction entity.
INSERT INTO transaction (transcation_id, transaction_date, transaction_price, status, nft_user_user_id, transaction_hash, listing_listing_id, request_request_id, nft_user_id)
VALUES (1, TIMESTAMP '2022-03-14 12:00:00', 200.00, 'completed', 1, 'hash123', 1, 2, 1);
  
COMMIT;

