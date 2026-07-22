import sqlite3
import json
import os

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

def main():
    # Nome del file del database
    db_file = 'sofascore_data.db'
    
    # NOVITA': Elimina il database se esiste già per forzare la rigenerazione dello schema.
    # Questo previene errori derivanti da vecchie esecuzioni con schemi diversi.
    if os.path.exists(db_file):
        try:
            os.remove(db_file)
            print(f"File database precedente '{db_file}' rimosso per un'installazione pulita.")
        except Exception as e:
            print(f"Attenzione: Impossibile eliminare '{db_file}'. Chiudi eventuali programmi che lo stanno usando (come DB Browser). Errore: {e}")
            return
            
    # 1. Carica i dati dai file JSON generati in precedenza
    matches_file = 'serie_a_matches_info.json'
    stats_file = 'serie_a_player_stats.json'
    
    if not os.path.exists(matches_file) or not os.path.exists(stats_file):
        print(f"Errore: I file JSON '{matches_file}' o '{stats_file}' non sono presenti nella cartella corrente.")
        return
        
    print("Caricamento dei file JSON in memoria...")
    with open(matches_file, 'r', encoding='utf-8') as f:
        matches_data = json.load(f)
        
    with open(stats_file, 'r', encoding='utf-8') as f:
        stats_data = json.load(f)
        
    # 2. Raccogli TUTTE le possibili chiavi per le statistiche in maniera dinamica
    print("Estrazione di tutte le possibili tipologie di statistiche...")
    all_stat_keys = set()
    for row in stats_data:
        full_stats = row.get('full_statistics', {})
        # Appiattiamo le statistiche perché alcuni valori possono essere altri dizionari
        flat_stats = flatten_dict(full_stats)
        for k in flat_stats.keys():
            # 'rating' lo gestiamo come campo fisso 'valutazione' richiesto
            if k != 'rating':
                all_stat_keys.add(k)
                
    # Convertiamo in lista per mantenere un ordine fisso nell'inserimento
    stat_keys_list = list(all_stat_keys)
    
    # 3. Connessione al database (creerà il file se non esiste)
    print("Connessione al database SQLite e creazione tabelle...")
    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()
    
    # --- 4. Creazione delle tabelle ---
    
    # Leghe
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS Leghe (
            ID_LEGA INTEGER PRIMARY KEY,
            nome_lega TEXT
        )
    ''')
    
    # Squadre
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS Squadre (
            ID_SQUADRA INTEGER PRIMARY KEY,
            nome_squadra TEXT,
            id_lega INTEGER,
            FOREIGN KEY(id_lega) REFERENCES Leghe(ID_LEGA)
        )
    ''')
    
    # Ruoli
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS Ruoli (
            ID_RUOLO TEXT PRIMARY KEY,
            ruolo TEXT
        )
    ''')
    
    # Giocatori
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS Giocatori (
            ID_PLAYER INTEGER PRIMARY KEY,
            nome TEXT,
            id_ruolo TEXT,
            id_squadra INTEGER,
            FOREIGN KEY(id_ruolo) REFERENCES Ruoli(ID_RUOLO),
            FOREIGN KEY(id_squadra) REFERENCES Squadre(ID_SQUADRA)
        )
    ''')
    
    # Esiti
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS Esiti (
            ID_ESITO TEXT PRIMARY KEY,
            esito TEXT
        )
    ''')
    
    # Partite
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS Partite (
            ID_MATCH INTEGER PRIMARY KEY,
            squadra_casa INTEGER,
            squadra_trasferta INTEGER,
            id_esito TEXT,
            FOREIGN KEY(squadra_casa) REFERENCES Squadre(ID_SQUADRA),
            FOREIGN KEY(squadra_trasferta) REFERENCES Squadre(ID_SQUADRA),
            FOREIGN KEY(id_esito) REFERENCES Esiti(ID_ESITO)
        )
    ''')
    
    # Statistiche - generazione dinamica delle colonne
    stats_columns_def = []
    for stat_key in stat_keys_list:
        stats_columns_def.append(f'"{stat_key}" REAL')
        
    columns_str = ",\n            ".join(stats_columns_def)
    if columns_str:
        columns_str = ",\n            " + columns_str
        
    cursor.execute(f'''
        CREATE TABLE IF NOT EXISTS Statistiche (
            id_match INTEGER,
            id_player INTEGER,
            valutazione REAL{columns_str},
            PRIMARY KEY(id_match, id_player),
            FOREIGN KEY(id_match) REFERENCES Partite(ID_MATCH),
            FOREIGN KEY(id_player) REFERENCES Giocatori(ID_PLAYER)
        )
    ''')
    
    # --- 5. Popolamento Tabelle Base ---
    print("Popolamento tabelle Leghe, Ruoli, Esiti...")
    
    ID_LEGA_SERIE_A = 23
    cursor.execute('INSERT OR IGNORE INTO Leghe (ID_LEGA, nome_lega) VALUES (?, ?)', (ID_LEGA_SERIE_A, 'Serie A'))
    
    ruoli_data = [
        ('G', 'Portiere'),
        ('D', 'Difensore'),
        ('M', 'Centrocampista'),
        ('F', 'Attaccante')
    ]
    cursor.executemany('INSERT OR IGNORE INTO Ruoli (ID_RUOLO, ruolo) VALUES (?, ?)', ruoli_data)
    
    esiti_data = [
        ('H', 'Vittoria squadra in casa'),
        ('A', 'Vittoria squadra in trasferta'),
        ('D', 'Pareggio')
    ]
    cursor.executemany('INSERT OR IGNORE INTO Esiti (ID_ESITO, esito) VALUES (?, ?)', esiti_data)
    
    # --- 6. Elaborazione Dati Partite e Squadre ---
    print("Elaborazione e popolamento tabelle Squadre e Partite...")
    match_team_map = {} 
    
    for match in matches_data:
        m_id = match['match_id']
        h_id = match['home_team_id']
        h_name = match['home_team_name']
        a_id = match['away_team_id']
        a_name = match['away_team_name']
        
        cursor.execute('INSERT OR IGNORE INTO Squadre (ID_SQUADRA, nome_squadra, id_lega) VALUES (?, ?, ?)', (h_id, h_name, ID_LEGA_SERIE_A))
        cursor.execute('INSERT OR IGNORE INTO Squadre (ID_SQUADRA, nome_squadra, id_lega) VALUES (?, ?, ?)', (a_id, a_name, ID_LEGA_SERIE_A))
        
        match_team_map[m_id] = {'home': h_id, 'away': a_id}
        
        raw_outcome = match.get('outcome')
        id_esito = None
        if raw_outcome == 'HOME_WIN':
            id_esito = 'H'
        elif raw_outcome == 'AWAY_WIN':
            id_esito = 'A'
        elif raw_outcome == 'DRAW':
            id_esito = 'D'
            
        cursor.execute('''
            INSERT OR IGNORE INTO Partite (ID_MATCH, squadra_casa, squadra_trasferta, id_esito)
            VALUES (?, ?, ?, ?)
        ''', (m_id, h_id, a_id, id_esito))
        
    # --- 7. Elaborazione Dati Giocatori e Statistiche ---
    print("Elaborazione e popolamento tabelle Giocatori e Statistiche. Potrebbe richiedere qualche istante...")
    
    for row in stats_data:
        m_id = row['match_id']
        p_id = row['player_id']
        p_name = row['player_name']
        team_side = row['team']
        ruolo = row.get('position', '')
        
        id_squadra = match_team_map.get(m_id, {}).get(team_side)
        
        cursor.execute('''
            INSERT OR REPLACE INTO Giocatori (ID_PLAYER, nome, id_ruolo, id_squadra)
            VALUES (?, ?, ?, ?)
        ''', (p_id, p_name, ruolo, id_squadra))
        
        valutazione = row.get('rating')
        full_stats = row.get('full_statistics', {})
        # Appiattiamo anche in fase di inserimento
        flat_stats = flatten_dict(full_stats)
        
        columns = ['id_match', 'id_player', 'valutazione']
        values = [m_id, p_id, valutazione]
        
        for k in stat_keys_list:
            columns.append(f'"{k}"')
            val = flat_stats.get(k, None)
            
            # Se per caso il valore è una lista, SQLite non l'accetta, quindi la stringhifichiamo in formato JSON
            if isinstance(val, (list, tuple)):
                val = json.dumps(val)
                
            values.append(val)
            
        placeholders = ', '.join(['?'] * len(values))
        cols_str = ', '.join(columns)
        
        cursor.execute(f'''
            INSERT OR REPLACE INTO Statistiche ({cols_str})
            VALUES ({placeholders})
        ''', tuple(values))

    conn.commit()
    conn.close()
    
    print(f"\n--- COMPLETATO ---")
    print(f"Database creato con successo nel file: '{db_file}'.")
    print(f"Sono state generate dinamicamente e popolate {len(stat_keys_list)} colonne specifiche per le statistiche dei giocatori.")

if __name__ == '__main__':
    main()
