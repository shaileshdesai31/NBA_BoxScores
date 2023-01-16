--- USAGE NOTES ---

General use is to locally store a MySQL database of NBA Box Score data and the ability to view specific statistics.

First, the user should create a MySQL database and run the nba_tables.sql script to create the tables and views.

Then, the boxscore.py file can be run after adding in some details in the main. Note that not all games can be added at once due to rate limits of the
basketball reference web scraper API being used.

--- INSTALLATIONS ---

In order to create the database, the user must download the basketball-reference-web-scraper library, the mysql-connector-python library, and the pytz library.
Some additional library requirements may be under requirements for the basketball-reference-web-scraper library.

--- CREDITS ---

All files are written by Shailesh Desai. The python API basketball-reference-web-scraper library was used throughout all files.
