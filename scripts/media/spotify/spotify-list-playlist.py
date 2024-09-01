#!/usr/bin/python3

import spotipy
from spotipy.oauth2 import SpotifyOAuth
import sys

with open("/home/artem/custom-setup/secrets/spotify/secret.txt", "r") as f:
    # in the secret.txt it looks like: client id=<id>=. Last = ensures that python retrieves the key without newline
    client_id = f.readline().split("=")[1]
    client_secret = f.readline().split("=")[1]
    redirect_uri = f.readline().split("=")[1]

# Scope for accessing user's playlists
scope = 'playlist-read-private'

sp = spotipy.Spotify(auth_manager=SpotifyOAuth(client_id=client_id,
                                               client_secret=client_secret,
                                               redirect_uri=redirect_uri,
                                               scope=scope))

playlist_id = sys.argv[1] 

offset = 0
while True:
    end = False
    results = sp.playlist_tracks(playlist_id, offset=offset)
    tracks = results['items']

    if len(tracks) == 0:
        end = True 
    else:
        offset += 100

    for item in tracks:
        track = item['track']
        # print(f"{track['name']} by {track['artists'][0]['name']}\n")
        print(f"{track['name']}")
    if end:
        break
