import cloudscraper
import sqlite3
import json
import time
import random

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURAZIONE
# ─────────────────────────────────────────────────────────────────────────────

# Cloudscraper per bypassare le protezioni anti-bot (Cloudflare, 403 Forbidden)
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

TOURNAMENT_ID = 17
SEASON_ID = 76986
TOTAL_ROUNDS = 10

DB_FILE = 'sofascore_data.db'

# Nomi dei file JSON di output
OUTPUT_MATCHES_JSON = 'test_matches_info.json'
OUTPUT_PLAYERS_JSON = 'test_player_stats.json'


# ─────────────────────────────────────────────────────────────────────────────
# FUNZIONI HELPER — SCRAPING (da scrape_sofascore.py)
# ─────────────────────────────────────────────────────────────────────────────

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
            print(f"Formazioni non trovate per il match {match_id} (404).")
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


# ─────────────────────────────────────────────────────────────────────────────
# FUNZIONI HELPER — PULIZIA E DB (da scrape_nuova_partita.py)
# ─────────────────────────────────────────────────────────────────────────────

def flatten_dict(d, parent_key='', sep='_'):
    """
    Appiattisce dizionari annidati per espandere le sotto-statistiche in colonne separate.
    Esempio: {'duels': {'won': 1, 'total': 2}} diventa {'duels_won': 1, 'duels_total': 2}
    """
    items = []
    for k, v in d.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        else:
            items.append((new_key, v))
    return dict(items)


def get_statistiche_columns(cursor):
    """
    Legge lo schema della tabella Statistiche e restituisce la lista ordinata
    dei nomi delle colonne (escluse id_match e id_player).
    """
    cursor.execute("PRAGMA table_info(Statistiche)")
    columns_info = cursor.fetchall()
    # Restituiamo tutte le colonne tranne le chiavi primarie (id_match, id_player)
    stat_columns = [col[1] for col in columns_info if col[1] not in ('id_match', 'id_player')]
    return stat_columns


def ricrea_tabella_test(cursor, stat_columns):
    """
    Elimina e ricrea la tabella test con la stessa struttura
    della tabella Statistiche, aggiungendo anche la colonna 'ruolo'.
    """
    cursor.execute("DROP TABLE IF EXISTS test")

    # Costruiamo le colonne delle statistiche come nella tabella Statistiche (tutte REAL)
    stats_columns_def = ",\n            ".join([f'"{col}" REAL' for col in stat_columns])

    create_sql = f'''
        CREATE TABLE test (
            id_match INTEGER,
            id_player INTEGER,
            nome_giocatore TEXT,
            ruolo TEXT,
            risultato TEXT,
            {stats_columns_def},
            PRIMARY KEY(id_match, id_player)
        )
    '''
    cursor.execute(create_sql)


def gestisci_valori_mancanti(cursor):
    """
    Gestisce i valori mancanti (NULL) nella tabella test:
    - Per TUTTE le variabili numeriche tranne topSpeed: sostituisce NULL con 0.
    - Per topSpeed: sostituisce NULL con la media di topSpeed calcolata sui
      giocatori con lo stesso ruolo.
    """
    # 1. Recupera le colonne numeriche (REAL) della tabella
    cursor.execute("PRAGMA table_info(test)")
    columns_info = cursor.fetchall()
    numeric_columns = [col[1] for col in columns_info
                       if col[2] == 'REAL' and col[1] != 'topSpeed']

    # 2. Sostituisci NULL con 0 per tutte le colonne tranne topSpeed
    for col in numeric_columns:
        cursor.execute(f'UPDATE test SET "{col}" = 0 WHERE "{col}" IS NULL')

    # 3. Per topSpeed: calcola la media per ruolo e sostituisci i NULL
    cursor.execute("""
        SELECT ruolo, AVG(topSpeed)
        FROM test
        WHERE topSpeed IS NOT NULL
        GROUP BY ruolo
    """)
    medie_per_ruolo = dict(cursor.fetchall())

    if medie_per_ruolo:
        for ruolo, media in medie_per_ruolo.items():
            cursor.execute("""
                UPDATE test
                SET topSpeed = ?
                WHERE topSpeed IS NULL AND ruolo = ?
            """, (media, ruolo))

    # Se un ruolo non ha alcun valore di topSpeed (tutti NULL), usiamo la media globale
    cursor.execute("""
        SELECT AVG(topSpeed)
        FROM test
        WHERE topSpeed IS NOT NULL
    """)
    media_globale = cursor.fetchone()[0]

    if media_globale is not None:
        cursor.execute("""
            UPDATE test
            SET topSpeed = ?
            WHERE topSpeed IS NULL
        """, (media_globale,))


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main():
    # =====================================================================
    # FASE 1: Scraping di tutte le partite e salvataggio in JSON
    # =====================================================================
    all_matches_info = []
    all_match_ids = []
    all_player_stats = []

    print("=" * 60)
    print("  SCRAPE TEST — Estrazione dati per modelli statistici")
    print("=" * 60)

    print(f"\nTorneo ID: {TOURNAMENT_ID} | Stagione ID: {SEASON_ID} | Giornate: {TOTAL_ROUNDS}")

    print("\n--- FASE 1a: Recupero informazioni e ID delle partite ---")
    for round_number in range(1, TOTAL_ROUNDS + 1):
        print(f"Ricerca partite per la giornata {round_number}...")
        matches_info = get_matches_info(round_number)
        all_matches_info.extend(matches_info)

        # Popoliamo anche l'array dei soli ID per la Fase 1b
        match_ids = [m['match_id'] for m in matches_info]
        all_match_ids.extend(match_ids)

        time.sleep(random.uniform(2.0, 4.0))

    print(f"\nTrovate {len(all_matches_info)} partite in totale.")

    if not all_matches_info:
        print("Nessuna partita trovata. Lo script termina qui.")
        return

    # Salvataggio info partite nel primo JSON
    print(f"Salvataggio delle info sulle partite in '{OUTPUT_MATCHES_JSON}'...")
    with open(OUTPUT_MATCHES_JSON, 'w', encoding='utf-8') as f:
        json.dump(all_matches_info, f, indent=4, ensure_ascii=False)

    print("\n--- FASE 1b: Recupero statistiche giocatori ---")
    for i, match_id in enumerate(all_match_ids):
        print(f"Elaborazione match ID: {match_id} ({i+1}/{len(all_match_ids)})...")

        lineups_data = get_match_lineups(match_id)
        if lineups_data:
            stats = extract_player_stats(lineups_data, match_id)
            all_player_stats.extend(stats)

        time.sleep(random.uniform(2.0, 4.5))

    # Salvataggio statistiche giocatori nel secondo JSON
    print(f"\nSalvataggio delle statistiche giocatori in '{OUTPUT_PLAYERS_JSON}'...")
    with open(OUTPUT_PLAYERS_JSON, 'w', encoding='utf-8') as f:
        json.dump(all_player_stats, f, indent=4, ensure_ascii=False)

    print(f"Totale record giocatori estratti: {len(all_player_stats)}")

    # =====================================================================
    # FASE 2: Pulizia dati e inserimento nella tabella 'test' del DB
    # =====================================================================
    print("\n" + "=" * 60)
    print("  FASE 2: Pulizia dati e inserimento nel database")
    print("=" * 60)

    # Rilettura dei JSON appena salvati
    print(f"\nLettura dei file JSON...")
    with open(OUTPUT_MATCHES_JSON, 'r', encoding='utf-8') as f:
        matches_data = json.load(f)
    with open(OUTPUT_PLAYERS_JSON, 'r', encoding='utf-8') as f:
        players_data = json.load(f)

    print(f"  Partite caricate: {len(matches_data)}")
    print(f"  Giocatori caricati: {len(players_data)}")

    # Creiamo un dizionario match_id -> outcome per lookup rapido
    match_outcomes = {}
    for match in matches_data:
        match_outcomes[match['match_id']] = match['outcome']

    # Connessione al database
    print(f"\nConnessione al database '{DB_FILE}'...")
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

    # Lettura schema tabella Statistiche
    stat_columns = get_statistiche_columns(cursor)
    print(f"Trovate {len(stat_columns)} colonne nella tabella Statistiche.")

    # Ricreazione della tabella test
    print("Ricreazione della tabella 'test'...")
    ricrea_tabella_test(cursor, stat_columns)

    # Inserimento dati nella tabella test
    print("Inserimento dati dei giocatori...")

    inserted_count = 0
    for row in players_data:
        p_id = row['player_id']
        m_id = row['match_id']
        nome = row.get('player_name', '')
        ruolo = row.get('position', '')
        team_side = row.get('team', '')
        full_stats = row.get('full_statistics', {})
        flat_stats = flatten_dict(full_stats)

        # Calcolo dell'esito dal punto di vista del giocatore
        match_outcome = match_outcomes.get(m_id, 'UNKNOWN')

        if match_outcome == 'HOME_WIN':
            risultato = 'W' if team_side == 'home' else 'L'
        elif match_outcome == 'AWAY_WIN':
            risultato = 'W' if team_side == 'away' else 'L'
        elif match_outcome == 'DRAW':
            risultato = 'D'
        else:
            risultato = None

        # Prepariamo le colonne e i valori
        columns = ['id_match', 'id_player', 'nome_giocatore', 'ruolo', 'risultato']
        values = [m_id, p_id, nome, ruolo, risultato]

        for col in stat_columns:
            columns.append(f'"{col}"')
            if col == 'valutazione':
                # Il campo valutazione corrisponde a 'rating' nell'API
                val = flat_stats.get('rating', None)
            else:
                val = flat_stats.get(col, None)

            # Se il valore è una lista, convertiamolo in stringa JSON
            if isinstance(val, (list, tuple)):
                val = json.dumps(val)

            values.append(val)

        placeholders = ', '.join(['?'] * len(values))
        cols_str = ', '.join(columns)

        cursor.execute(f'''
            INSERT OR REPLACE INTO test ({cols_str})
            VALUES ({placeholders})
        ''', tuple(values))
        inserted_count += 1

    print(f"Inseriti {inserted_count} record nella tabella 'test'.")

    # Gestione valori mancanti
    print("\nGestione dei valori mancanti...")
    gestisci_valori_mancanti(cursor)
    print("Valori mancanti gestiti con successo.")

    # Commit
    conn.commit()

    # Riepilogo finale
    cursor.execute("SELECT COUNT(*) FROM test")
    count = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM test WHERE topSpeed IS NOT NULL")
    count_topspeed = cursor.fetchone()[0]

    cursor.execute("SELECT risultato, COUNT(*) FROM test GROUP BY risultato")
    esiti_riepilogo = dict(cursor.fetchall())

    print(f"\n{'=' * 60}")
    print(f"  COMPLETATO")
    print(f"{'=' * 60}")
    print(f"  Torneo ID:             {TOURNAMENT_ID}")
    print(f"  Stagione ID:           {SEASON_ID}")
    print(f"  Giornate analizzate:   {TOTAL_ROUNDS}")
    print(f"  Partite trovate:       {len(matches_data)}")
    print(f"  Giocatori inseriti:    {count}")
    print(f"  Esiti:                 {esiti_riepilogo}")
    print(f"  topSpeed disponibili:  {count_topspeed}/{count}")
    print(f"  Tabella:               test (in '{DB_FILE}')")
    print(f"{'=' * 60}")

    conn.close()


if __name__ == '__main__':
    main()
