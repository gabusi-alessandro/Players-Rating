import cloudscraper
import time
import random
import json

# Utilizziamo cloudscraper invece di requests per bypassare le protezioni anti-bot (es. Cloudflare, 403 Forbidden)
# Impostiamo il browser per emulare Chrome su Windows
scraper = cloudscraper.create_scraper(browser={
    'browser': 'chrome',
    'platform': 'windows',
    'desktop': True
})

HEADERS = {
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'it-IT,it;q=0.9,en-US;q=0.8,en;q=0.7',
    'Cache-Control': 'max-age=0',
    'Origin': 'https://www.sofascore.com',
    'Referer': 'https://www.sofascore.com/',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'same-origin',
}

TOURNAMENT_ID = 23 # Serie A
SEASON_ID = 76457 # Stagione scorsa
TOTAL_ROUNDS = 38 # La Serie A ha 38 giornate

def get_matches_info(round_number):
    """Estrae le informazioni e gli ID di tutte le partite di una determinata giornata."""
    url = f"https://www.sofascore.com/api/v1/unique-tournament/{TOURNAMENT_ID}/season/{SEASON_ID}/events/round/{round_number}"
    
    try:
        response = scraper.get(url, headers=HEADERS)
        if response.status_code == 200:
            data = response.json()
            events = data.get('events', [])
            matches_info = []
            
            for event in events:
                match_id = event.get('id')
                home_team = event.get('homeTeam', {})
                away_team = event.get('awayTeam', {})
                
                # Punteggi (se la partita è finita)
                home_score = event.get('homeScore', {}).get('current')
                away_score = event.get('awayScore', {}).get('current')
                
                # Determiniamo l'esito
                if home_score is not None and away_score is not None:
                    if home_score > away_score:
                        outcome = 'HOME_WIN'
                    elif away_score > home_score:
                        outcome = 'AWAY_WIN'
                    else:
                        outcome = 'DRAW'
                else:
                    outcome = 'UNKNOWN'
                
                match_data = {
                    'match_id': match_id,
                    'round': round_number,
                    'home_team_id': home_team.get('id'),
                    'home_team_name': home_team.get('name'),
                    'away_team_id': away_team.get('id'),
                    'away_team_name': away_team.get('name'),
                    'home_score': home_score,
                    'away_score': away_score,
                    'outcome': outcome
                }
                matches_info.append(match_data)
                
            return matches_info
        else:
            print(f"Errore durante il recupero del round {round_number}: HTTP {response.status_code}")
            if response.status_code == 403:
                print("Il server ha bloccato la richiesta (403 Forbidden).")
            return []
    except Exception as e:
        print(f"Eccezione durante la richiesta del round {round_number}: {e}")
        return []

def get_match_lineups(match_id):
    """Estrae i dati sulle formazioni per un singolo match."""
    url = f"https://www.sofascore.com/api/v1/event/{match_id}/lineups"
    
    try:
        response = scraper.get(url, headers=HEADERS)
        if response.status_code == 200:
            return response.json()
        elif response.status_code == 404:
            return None
        else:
            print(f"Errore API formazioni per match {match_id}: HTTP {response.status_code}")
            return None
    except Exception as e:
        print(f"Eccezione durante il recupero formazioni {match_id}: {e}")
        return None

def extract_player_stats(lineups_data, match_id):
    """Estrae le statistiche e le valutazioni dei giocatori dai dati della formazione."""
    extracted_stats = []
    
    if not lineups_data:
        return extracted_stats
        
    for team in ['home', 'away']:
        if team in lineups_data:
            players = lineups_data[team].get('players', [])
            for player_entry in players:
                player_info = player_entry.get('player', {})
                stats = player_entry.get('statistics', {})
                
                player_data = {
                    'match_id': match_id,
                    'team': team,
                    'player_id': player_info.get('id'),
                    'player_name': player_info.get('name'),
                    'position': player_entry.get('position'),
                    'rating': stats.get('rating'),
                    'minutes_played': stats.get('minutesPlayed'),
                    'goals': stats.get('goals', 0),
                    'assists': stats.get('assists', 0),
                    'full_statistics': stats
                }
                extracted_stats.append(player_data)
                
    return extracted_stats

def main():
    all_matches_info = []
    all_match_ids = []
    all_player_stats = []
    
    print("--- FASE 1: Recupero informazioni e ID delle partite ---")
    for round_number in range(1, TOTAL_ROUNDS + 1):
        print(f"Ricerca partite per la giornata {round_number}...")
        matches_info = get_matches_info(round_number)
        all_matches_info.extend(matches_info)
        
        # Popoliamo anche l'array dei soli ID per la Fase 2
        match_ids = [m['match_id'] for m in matches_info]
        all_match_ids.extend(match_ids)
        
        # Aumentiamo leggermente il tempo di attesa base per sembrare più umani
        time.sleep(random.uniform(2.0, 4.0))

    print(f"\nTrovate {len(all_matches_info)} partite in totale.")
    
    if not all_matches_info:
        print("Nessuna partita trovata. Lo script termina qui.")
        return

    # Salviamo subito le informazioni sulle partite nel primo JSON
    output_matches_filename = 'serie_a_matches_info.json'
    print(f"Salvataggio delle info sulle partite in '{output_matches_filename}'...")
    with open(output_matches_filename, 'w', encoding='utf-8') as f:
        json.dump(all_matches_info, f, indent=4, ensure_ascii=False)

    print("\n--- FASE 2: Recupero statistiche giocatori ---")
    
    for i, match_id in enumerate(all_match_ids):
        print(f"Elaborazione match ID: {match_id} ({i+1}/{len(all_match_ids)})...")
        
        lineups_data = get_match_lineups(match_id)
        if lineups_data:
            stats = extract_player_stats(lineups_data, match_id)
            all_player_stats.extend(stats)
            
        time.sleep(random.uniform(2.0, 4.5))
        
    print("\nScraping completato! Salvataggio delle statistiche giocatori su file...")
    
    output_stats_filename = 'serie_a_player_stats.json'
    with open(output_stats_filename, 'w', encoding='utf-8') as f:
        json.dump(all_player_stats, f, indent=4, ensure_ascii=False)
        
    print(f"Statistiche giocatori salvate con successo in '{output_stats_filename}'.")
    print(f"Totale record giocatori estratti: {len(all_player_stats)}")

if __name__ == "__main__":
    main()
