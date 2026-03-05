import streamlit as st
import mysql.connector
import os
import pandas as pd
from dotenv import load_dotenv

# Charge les variables du fichier .env situé dans le même dossier
load_dotenv()

# CONFIGURATION
AGENCE = os.getenv("AGENCE_NAME", "Agence1")
DB_HOST = os.getenv("DB_HOST", "mysql-agence1")
# Configuration MySQL
MYSQL_ROOT_PASSWORD=os.getenv("MYSQL_ROOT_PASSWORD", "mysql")
MYSQL_DATABASE=os.getenv("MYSQL_DATABASE", "nanp_db")
MYSQL_USER=os.getenv("MYSQL_USER", "root")
MYSQL_PASSWORD=os.getenv("MYSQL_PASSWORD", "mysql")

THEME_COLOR = "#38bdf8" if "1" in AGENCE else "#fbbf24"

st.set_page_config(page_title=f"POS {AGENCE}", layout="centered")

# CSS PERSONNALISÉ
st.markdown(f"""
    <style>
    .stApp {{ background-color: #0f172a; color: white; }}
    .stButton>button {{ width: 100%; border-radius: 12px; background: {THEME_COLOR}; color: black; font-weight: bold; border: none; height: 3rem; }}
    div[data-testid="stMetricValue"] {{ color: {THEME_COLOR} !important; font-size: 2.5rem; }}
    </style>
    """, unsafe_allow_html=True)

def query_db(query, params=None, is_select=True):
    conn = mysql.connector.connect(host=DB_HOST, user=MYSQL_USER, password=MYSQL_PASSWORD, database=MYSQL_DATABASE, ssl_disabled=True)
    curr = conn.cursor(dictionary=True)
    curr.execute(query, params or ())
    res = curr.fetchall() if is_select else conn.commit()
    conn.close()
    return res

# UI
st.title(f"🏬 Terminal {AGENCE}")
st.caption(f"Connecté à {DB_HOST} • Redpanda Node Active")

# Métrique Locale
try:
    stats = query_db("SELECT SUM(montant) as total FROM ventes")[0]
    st.metric("Ventes Locales (Total)", f"{stats['total'] or 0:,.2f} €")
except:
    st.metric("Ventes Locales (Total)", "0.00 €")

# Formulaire de vente
with st.container(border=True):
    st.subheader("🛒 Nouvelle Transaction")
    prod = st.text_input("Désignation du produit", placeholder="ex: MacBook Pro M3")
    prix = st.number_input("Prix de vente (€)", min_value=0.0, step=10.0)
    
    if st.button("Encaisser 🚀"):
        if prod and prix > 0:
            query_db("INSERT INTO ventes (agence_id, produit, montant) VALUES (%s, %s, %s)", 
                     (AGENCE.lower(), prod, prix), is_select=False)
            st.toast(f'Vente de {prod} synchronisée !', icon='✅')
            st.balloons()
            st.rerun()

# Historique
st.divider()
st.subheader("🕒 Derniers Tickets")
try:
    history = query_db("SELECT produit, montant, heure_vente FROM ventes ORDER BY id DESC LIMIT 5")
    st.dataframe(pd.DataFrame(history), use_container_width=True, hide_index=True)
except:
    st.info("Aucune transaction enregistrée.")
