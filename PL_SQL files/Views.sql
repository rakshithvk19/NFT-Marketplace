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
    
    EXECUTE IMMEDIATE 'CREATE VIEW BUYER_VIEW AS
                        SELECT NFT_USER_ID, NFT_USER_NAME, WALLET_ADDRESS, ROLE 
                        FROM NFT_USER
                        WHERE ROLE LIKE (''BUYER'')';
    EXECUTE IMMEDIATE 'CREATE VIEW Active_Listings_View AS
                        SELECT l.listing_id, l.listing_status, L.NFT_NFT_ID,  l.listing_end_date, l.no_of_bids, l.starting_bid,
                               b.bid_id, b.bidder_id, b.bid_amount, b.bid_date, b.bid_status
                        FROM listing l
                        LEFT JOIN bid b ON l.listing_id = b.listing_listing_id
                        WHERE l.listing_status IN (''ongoing'', ''cancelled'')';
    EXECUTE IMMEDIATE 'CREATE VIEW Completed_Listings_View AS
                    SELECT l.listing_id, l.listing_status, l.listing_end_date, l.no_of_bids, l.starting_bid,
                           t.transcation_id, t.transaction_date, t.transaction_price, t.status
                    FROM listing l
                    JOIN transaction t ON l.listing_id = t.listing_listing_id
                    WHERE l.listing_status = ''completed''';
    EXECUTE IMMEDIATE 'CREATE VIEW User_Bids_View AS
                    SELECT b.bid_id, b.bid_amount, b.bid_date, b.bid_status,
                           l.listing_id, l.listing_status, l.listing_start_date, l.listing_end_date,
                           u.nft_user_id, u.nft_user_name, u.role 
                    FROM bid b
                    JOIN listing l ON b.listing_listing_id = l.listing_id
                    JOIN bidder bd ON b.bidder_id = bd.bidder_id
                    JOIN nft_user u ON bd.nft_user_user_id = u.nft_user_id';
    EXECUTE IMMEDIATE 'CREATE VIEW NFT_Status_View AS
                    SELECT n.nft_id, n.title, n.description, n.mint_date, n.file_url, n.token_id, n.price, n.status,
                           nu.nft_user_name, nu.email
                    FROM nft n
                    JOIN nft_user nu ON n.nft_user_user_id = nu.nft_user_id';
    EXECUTE IMMEDIATE 'CREATE VIEW Pending_Requests_View AS
                    SELECT r.request_id, r.request_time, r.request_status,
                           n.title AS nft_title, nu.nft_user_name AS requester_name, nu.email AS requester_email
                    FROM request r
                    JOIN nft n ON r.nft_nft_id = n.nft_id
                    JOIN nft_user nu ON r.nft_user_user_id = nu.nft_user_id
                    WHERE r.request_status = ''pending''';
    EXECUTE IMMEDIATE 'CREATE VIEW Top_Bidders_View AS
                    SELECT bd.nft_user_user_id, nu.nft_user_name, nu.email, SUM(b.bid_amount) AS total_spent
                    FROM bidder bd
                    JOIN bid b ON bd.bid_bid_id = b.bid_id
                    JOIN nft_user nu ON bd.nft_user_user_id = nu.nft_user_id
                    GROUP BY bd.nft_user_user_id, nu.nft_user_name, nu.email
                    ORDER BY total_spent DESC';
    EXECUTE IMMEDIATE 'CREATE VIEW Active_NFT_View AS
                    SELECT n.nft_id, n.title, n.description, n.mint_date, n.file_url, n.token_id, n.price, n.status,
                           l.listing_id, l.listing_status, l.listing_start_date, l.listing_end_date,
                           MAX(b.bid_amount) AS highest_bid
                    FROM nft n
                    JOIN listing l ON n.nft_id = l.nft_nft_id
                    LEFT JOIN bid b ON l.listing_id = b.listing_listing_id
                    WHERE l.listing_status IN (''ongoing'', ''cancelled'')
                    GROUP BY n.nft_id, n.title, n.description, n.mint_date, n.file_url, n.token_id, n.price, n.status,
                             l.listing_id, l.listing_status, l.listing_start_date, l.listing_end_date';
    EXECUTE IMMEDIATE 'CREATE VIEW Completed_Transactions_View AS
                    SELECT t.transcation_id, t.transaction_date, t.transaction_price, t.status,
                    l.listing_id, l.listing_status, l.listing_start_date, l.listing_end_date,
                    r.request_id, r.request_time, r.request_status,
                    n.title AS nft_title, nu.nft_user_name AS seller_name, nu.email AS seller_email,
                    nu2.nft_user_name AS buyer_name, nu2.email AS buyer_email
                    FROM transaction t
                    JOIN listing l ON t.listing_listing_id = l.listing_id
                    JOIN request r ON t.request_request_id = r.request_id
                    JOIN nft n ON r.nft_nft_id = n.nft_id
                    JOIN nft_user nu ON n.nft_user_user_id = nu.nft_user_id
                    JOIN nft_user nu2 ON t.nft_user_user_id = nu2.nft_user_id
                    WHERE t.status = ''completed''';
                    dbms_output.put_line('Views Recreated');
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error: ' || sqlerrm);
END;
/   
