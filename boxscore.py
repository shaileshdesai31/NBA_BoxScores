from basketball_reference_web_scraper import client
import mysql.connector
import datetime
from time import sleep
import pytz

team_abvs = {'BROOKLYN NETS': 'BKN', 'MILWAUKEE BUCKS': 'MIL', 'GOLDEN STATE WARRIORS': 'GSW',
             'LOS ANGELES LAKERS': 'LAL', 'INDIANA PACERS': 'IND', 'CHARLOTTE HORNETS': 'CHA',
             'CHICAGO BULLS': 'CHI', 'DETROIT PISTONS': 'DET', 'WASHINGTON WIZARDS': 'WSH',
             'TORONTO RAPTORS': 'TOR', 'BOSTON CELTICS': 'BOS', 'NEW YORK KNICKS': 'NYK',
             'CLEVELAND CAVALIERS': 'CLE', 'MEMPHIS GRIZZLIES': 'MEM', 'PHILADELPHIA 76ERS': 'PHI',
             'NEW ORLEANS PELICANS': 'NOP', 'HOUSTON ROCKETS': 'HOU', 'MINNESOTA TIMBERWOLVES': 'MIN',
             'ORLANDO MAGIC': 'ORL', 'SAN ANTONIO SPURS': 'SAS', 'OKLAHOMA CITY THUNDER': 'OKC',
             'UTAH JAZZ': 'UTA', 'SACRAMENTO KINGS': 'SAC', 'PORTLAND TRAIL BLAZERS': 'POR',
             'DENVER NUGGETS': 'DEN', 'PHOENIX SUNS': 'PHX', 'DALLAS MAVERICKS': 'DAL',
             'ATLANTA HAWKS': 'ATL', 'LOS ANGELES CLIPPERS': 'LAC', 'MIAMI HEAT': 'MIA'}

def update_db(cur, yr=2023):
    _update_standings(cur, yr=yr)
    season = _get_valid_season_sched(cur, yr=yr)
    _add_game_data(cur, season)

#gets games played that haven't been added to DB
def _get_valid_season_sched(cur, yr=2023):
    query = """select g.game_date
               from Game g
               order by 1 desc
               limit 1"""

    cur.execute(query)
    try:
        latest_date = cur.fetchall()[0][0]
    except:
        latest_date = '1950-01-01' #assuming there is no data inserted yet!
    season = client.season_schedule(season_end_year=2023)
    start_index = 0
    end_index = 0
    for i in range(len(season)):
        game_date = season[i]['start_time'].replace(tzinfo=pytz.utc).astimezone(pytz.timezone('US/Central')).date()
        if game_date > latest_date:
            start_index = i
            break
    for i in range(i, len(season)):
        if season[i]['away_team_score'] is None:
            end_index = i
            break
    return season[start_index:end_index]

def _update_standings(cur, yr=2023):
    d = client.standings(yr)
    east = []
    west = []
    for t in d:
        td = dict()
        td['team'] = team_abvs[t['team'].value]
        td['wins'] = t['wins']
        td['losses'] = t['losses']
        td['div'] = t['division'].value
        td['conf'] = t['conference'].value
        if td['conf'] == 'EASTERN':
            east.append(td)
        else:
            west.append(td)
    east.sort(key=lambda x: x['wins'] / (x['wins'] + x['losses']), reverse=True)
    west.sort(key=lambda x: x['wins'] / (x['wins'] + x['losses']), reverse=True)

    for i in range(15):
        data_team1 = east[i]
        data_team2 = west[i]
        update1 = f"""UPDATE Standings
        SET wins = '{data_team1['wins']}', losses = '{data_team1['losses']}', seed = '{i + 1}'
        WHERE team = '{data_team1['team']}';"""
        update2 = f"""UPDATE Standings
        SET wins = '{data_team2['wins']}', losses = '{data_team2['losses']}', seed = '{i + 1}'
        WHERE team = '{data_team2['team']}';"""
        cur.execute(update1)
        cur.execute(update2)

def _add_game_data(cur, season):

    add_game = "INSERT INTO Game (home, away, home_score, away_score, game_date) VALUES (%s, %s, %s, %s, %s)"
    add_player = "INSERT INTO PlayerLog (player_name, game_id, sp, pts, ast, fg, fga, ft, fta, tp, tpa, blk, drb, orb," \
                 " stl, tov, pf, team, opp, win) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s," \
                 " %s, %s, %s)"
    player_data_date = datetime.datetime.strptime('1950-01-01', '%Y-%m-%d')
    c = 0
    calls = 0
    for game in season:
        game_date = game['start_time'].replace(tzinfo=pytz.utc).astimezone(pytz.timezone('US/Central')).date()

        if player_data_date !=  game_date:
            sleep(1) #politeness
            try:
                # NOTE: ALL GAME TIMES IN NBA SCHEDULE ARE IN UTC BUT PLAYER BOX SCORE DATA IS IN LOCAL TIME
                # FOR THIS REASON, WE USE THE ALREADY LOCALIZED DATE CALCULATED ABOVE!!!
                if calls == 50:
                    print('Fifty calls to recieve player box score data have been made. To avoid rate issues, run again in at least one hour.')
                    break
                player_data = client.player_box_scores(day=game_date.day, month=game_date.month, year=game_date.year)
                calls += 1
            except:
                break
            player_data_date = game_date

        cur.execute(add_game, (team_abvs[game['home_team'].value], team_abvs[game['away_team'].value],
                               game['home_team_score'], game['away_team_score'], game_date))
        game_id = cursor.lastrowid

        for p in player_data:

            if p['team'].value == game['away_team'].value or p['team'].value == game['home_team'].value:
                pts = 2*p['made_field_goals'] + p['made_three_point_field_goals'] + p['made_free_throws']
                playerlog_data = (p['name'], game_id, p['seconds_played'], pts, p['assists'], p['made_field_goals'],
                               p['attempted_field_goals'], p['made_free_throws'], p['attempted_free_throws'],
                               p['made_three_point_field_goals'], p['attempted_three_point_field_goals'],
                               p['blocks'], p['defensive_rebounds'], p['offensive_rebounds'], p['steals'],
                               p['turnovers'], p['personal_fouls'], team_abvs[p['team'].value],
                               team_abvs[p['opponent'].value], 1 if p['outcome'].value == 'WIN' else 0)
                cur.execute(add_player, playerlog_data)

        c += 1
        print(f"Game # {c} Added: {team_abvs[game['away_team'].value]} @ {team_abvs[game['home_team'].value]} ({game_date})")


    #pprint(client.season_schedule(season_end_year=2023)[0])
    #pprint(client.player_box_scores(day=18, month=10, year=2022))

if __name__ == '__main__':
    conn = mysql.connector.connect(user='root', password='XXX',
                                   host='127.0.0.1',
                                   database='nba')
    cursor = conn.cursor(buffered=True)
    update_db(cursor, yr=2023) # This is the only method that needs to be called for normal use.
    conn.commit()
    conn.close()
