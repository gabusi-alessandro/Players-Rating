# Json to DB ---> File fatto da me a mano solamente per provare

import sqlite3
import json

# Importiamo i dati
path = "serie_a_player_stats.json"

try:
    with open(path, 'r', encoding = 'utf-8') as file:
        dati_json = json.load(file)
        print(f"File '{path}' caricato con successo")
except FileNotFoundError:
    print(f"File '{path}' non è stato trovato.")
    exit()
except json.JSONDecodeError:
    print(f"Errore: Il file '{path}' non è un JSON valido")
    exit()

# Creazione e connessiamo al database
connessione = sqlite3.connect("Jstats_db.db")

cursore = connessione.cursor()

# Creazione della tabella
nuova_tabella = '''
CREATE TABLE IF NOT EXISTS player_stats (
    id INTEGER PRIMARY KEY,
    id_player INTEGER,
    match_id INTEGER,
    giocatore TEXT,
    ruolo TEXT,
    minuti_giocati INTEGER,
    goal INTEGER,
    assist INTEGER
)
'''

cursore.execute(nuova_tabella)

# Inserimento dati nel DB

insert_instruction = '''
INSERT INTO player_stats (
    match_id, giocatore, ruolo, minuti_giocati,goal, assist
    ) VALUES (?,?,?,?,?,?)
'''

print("Inzio l'inserimento dei dati nel database...")

# Cicliamo per ogni giocatore
for record in dati_json:
    valori = (
        record["match_id"],
        record["player_name"],
        record["position"],
        record["minutes_played"],
        record["goals"],
        record["assists"]
    )

    cursore.execute(insert_instruction, valori)


# Salvataggio e chiusura
connessione.commit()

connessione.close()

print("Dati salvati con successo")