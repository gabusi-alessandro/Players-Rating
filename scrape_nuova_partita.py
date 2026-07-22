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

DB_FILE = 'sofascore_data.db'

# ─────────────────────────────────────────────────────────────────────────────
# FUNZIONI HELPER
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


def get_match_info(match_id):
    """Recupera le informazioni dell'evento (punteggi, squadre) per determinare l'esito."""
    url = f"https://www.sofascore.com/api/v1/event/{match_id}"

    try:
        response = scraper.get(url, headers=HEADERS)
        if response.status_code == 200:
            event = response.json().get('event', {})
            home_score = event.get('homeScore', {}).get('current')
            away_score = event.get('awayScore', {}).get('current')

            if home_score is not None and away_score is not None:
                if home_score > away_score:
                    outcome = 'HOME_WIN'
                elif away_score > home_score:
                    outcome = 'AWAY_WIN'
                else:
                    outcome = 'DRAW'
            else:
                outcome = 'UNKNOWN'

            return {
                'home_score': home_score,
                'away_score': away_score,
                'outcome': outcome
            }
        else:
            print(f"Errore API evento per match {match_id}: HTTP {response.status_code}")
            return None
    except Exception as e:
        print(f"Eccezione durante il recupero info match {match_id}: {e}")
        return None


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
                    'full_statistics': stats
                }
                extracted_stats.append(player_data)

    return extracted_stats


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


def ricrea_tabella_nuovi_dati(cursor, stat_columns):
    """
    Elimina e ricrea la tabella nuovi_dati con la stessa struttura
    della tabella Statistiche, aggiungendo anche la colonna 'ruolo'.
    """
    cursor.execute("DROP TABLE IF EXISTS nuovi_dati")

    # Costruiamo le colonne delle statistiche come nella tabella Statistiche (tutte REAL)
    stats_columns_def = ",\n            ".join([f'"{col}" REAL' for col in stat_columns])

    create_sql = f'''
        CREATE TABLE nuovi_dati (
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
    Gestisce i valori mancanti (NULL) nella tabella nuovi_dati:
    - Per TUTTE le variabili numeriche tranne topSpeed: sostituisce NULL con 0.
    - Per topSpeed: sostituisce NULL con la media di topSpeed calcolata sui
      giocatori con lo stesso ruolo.
    """
    # 1. Recupera le colonne numeriche (REAL) della tabella
    cursor.execute("PRAGMA table_info(nuovi_dati)")
    columns_info = cursor.fetchall()
    numeric_columns = [col[1] for col in columns_info
                       if col[2] == 'REAL' and col[1] != 'topSpeed']

    # 2. Sostituisci NULL con 0 per tutte le colonne tranne topSpeed
    for col in numeric_columns:
        cursor.execute(f'UPDATE nuovi_dati SET "{col}" = 0 WHERE "{col}" IS NULL')

    # 3. Per topSpeed: calcola la media per ruolo e sostituisci i NULL
    # Calcoliamo la media di topSpeed raggruppata per ruolo (solo sui valori non NULL)
    cursor.execute("""
        SELECT ruolo, AVG(topSpeed)
        FROM nuovi_dati
        WHERE topSpeed IS NOT NULL
        GROUP BY ruolo
    """)
    medie_per_ruolo = dict(cursor.fetchall())

    if medie_per_ruolo:
        for ruolo, media in medie_per_ruolo.items():
            cursor.execute("""
                UPDATE nuovi_dati
                SET topSpeed = ?
                WHERE topSpeed IS NULL AND ruolo = ?
            """, (media, ruolo))

    # Se un ruolo non ha alcun valore di topSpeed (tutti NULL), usiamo la media globale
    cursor.execute("""
        SELECT AVG(topSpeed)
        FROM nuovi_dati
        WHERE topSpeed IS NOT NULL
    """)
    media_globale = cursor.fetchone()[0]

    if media_globale is not None:
        cursor.execute("""
            UPDATE nuovi_dati
            SET topSpeed = ?
            WHERE topSpeed IS NULL
        """, (media_globale,))


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main():
    # 1. Input dell'utente: ID della partita
    print("=" * 60)
    print("  SCRAPING NUOVA PARTITA - Sofascore Serie A")
    print("=" * 60)
    match_id_input = input("\nInserisci l'ID della partita da estrarre: ").strip()

    try:
        match_id = int(match_id_input)
    except ValueError:
        print("Errore: L'ID della partita deve essere un numero intero.")
        return

    # 2. Recupero informazioni sulla partita (punteggi per calcolare l'esito)
    print(f"\nRecupero informazioni sulla partita {match_id}...")
    time.sleep(random.uniform(1.0, 2.0))

    match_info = get_match_info(match_id)
    if not match_info:
        print("Impossibile recuperare le informazioni della partita. Lo script termina qui.")
        return

    match_outcome = match_info['outcome']
    print(f"Risultato: {match_info['home_score']} - {match_info['away_score']} ({match_outcome})")

    # 3. Scraping delle formazioni e statistiche
    print(f"Recupero formazioni e statistiche...")
    time.sleep(random.uniform(1.0, 2.0))

    lineups_data = get_match_lineups(match_id)
    if not lineups_data:
        print("Impossibile recuperare le formazioni. Lo script termina qui.")
        return

    player_stats = extract_player_stats(lineups_data, match_id)

    if not player_stats:
        print("Nessuna statistica giocatore trovata per questa partita.")
        return

    print(f"Estratte statistiche per {len(player_stats)} giocatori.")

    # 4. Connessione al database e lettura schema Statistiche
    print(f"\nConnessione al database '{DB_FILE}'...")
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

    stat_columns = get_statistiche_columns(cursor)
    print(f"Trovate {len(stat_columns)} colonne nella tabella Statistiche.")

    # 5. Ricrea la tabella nuovi_dati
    print("Ricreazione della tabella 'nuovi_dati'...")
    ricrea_tabella_nuovi_dati(cursor, stat_columns)

    # 6. Inserimento dati nella tabella nuovi_dati
    print("Inserimento dati dei giocatori...")

    for row in player_stats:
        p_id = row['player_id']
        m_id = row['match_id']
        nome = row.get('player_name', '')
        ruolo = row.get('position', '')
        team_side = row.get('team', '')
        full_stats = row.get('full_statistics', {})
        flat_stats = flatten_dict(full_stats)

        # Calcolo dell'esito dal punto di vista del giocatore
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
            INSERT OR REPLACE INTO nuovi_dati ({cols_str})
            VALUES ({placeholders})
        ''', tuple(values))

    print(f"Inseriti {len(player_stats)} record nella tabella 'nuovi_dati'.")

    # 7. Gestione valori mancanti
    print("\nGestione dei valori mancanti...")
    gestisci_valori_mancanti(cursor)
    print("Valori mancanti gestiti con successo.")

    # 8. Commit e chiusura
    conn.commit()

    # 9. Stampa riepilogo finale
    cursor.execute("SELECT COUNT(*) FROM nuovi_dati")
    count = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM nuovi_dati WHERE topSpeed IS NOT NULL")
    count_topspeed = cursor.fetchone()[0]

    cursor.execute("SELECT risultato, COUNT(*) FROM nuovi_dati GROUP BY risultato")
    esiti_riepilogo = dict(cursor.fetchall())

    print(f"\n{'=' * 60}")
    print(f"  COMPLETATO")
    print(f"{'=' * 60}")
    print(f"  Partita ID:            {match_id}")
    print(f"  Risultato:             {match_info['home_score']} - {match_info['away_score']}")
    print(f"  Giocatori inseriti:    {count}")
    print(f"  Esiti:                 {esiti_riepilogo}")
    print(f"  topSpeed disponibili:  {count_topspeed}/{count}")
    print(f"  Tabella:               nuovi_dati (in '{DB_FILE}')")
    print(f"{'=' * 60}")

    conn.close()


if __name__ == '__main__':
    main()
