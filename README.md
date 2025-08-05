Gluboom - Social Media Platform
Gluboom este o platformă social media modernă, centrată pe comunități, care combină cele mai bune elemente de pe platforme de top precum Instagram, TikTok, Discord și Facebook. Aplicația este construită pentru a oferi o experiență socială bogată, unde utilizatorii pot crea și interacționa în cadrul unor grupuri publice sau private.

✨ Funcționalități Principale
Aplicația se află în dezvoltare activă. Iată funcționalitățile implementate până acum:

👤 Autentificare și Profil:

Sistem complet de înregistrare și login cu email/parolă.

Profil de utilizator personalizabil cu poză, nume de utilizator și biografie.

Sistem de urmărire (Follow/Unfollow) cu liste de urmăritori și urmăriri.

👨‍👩‍👧‍👦 Sistem de Grupuri:

Creare de grupuri Publice (vizibile pentru toți) sau Private (doar pe bază de invitație).

Opțiune pentru administratori de a aproba manual cererile de aderare.

Pagină de management pentru administratori unde pot vizualiza și gestiona cererile.

Pagină de detalii a grupului cu design modern, tab-uri pentru conținut și buton de aderare/părăsire.

📰 Feed & Postări:

Feed principal care afișează postările din grupurile publice.

Creare de postări cu text și imagine, cu posibilitatea de a selecta grupul în care se postează.

Sistem de Like-uri cu animație de dublu-tap.

Sistem de Comentarii pentru fiecare postare.

🎬 Conținut Video (Reels):

Flux de Reels cu scroll vertical infinit și auto-play.

Posibilitatea de a posta Reels-uri în numele unui grup (doar pentru admini).

Interfață de vizualizare modernă cu butoane de Like și Comentariu.

🌀 Povești (Stories):

Sistem de story-uri efemere (valabile 24 de ore), postate de grupuri.

Vizualizator de story-uri full-screen cu bare de progres.

💬 Mesagerie Directă:

Sistem de chat între utilizatori și administratorii grupurilor.

Interfață de conversație 1-la-1.

🔴 Live Streaming:

Funcționalitate de a porni o transmisiune live (doar gazda).

Posibilitatea altor utilizatori de a se alătura ca spectatori.

Integrare cu chat în timp real în timpul transmisiunii.

🚀 Tehnologii Folosite
Frontend: Flutter - pentru o aplicație cross-platform (iOS & Android) performantă și frumoasă.

Backend (BaaS):

Firebase - pentru Autentificare, Bază de Date (Firestore) și reguli de securitate.

Supabase - pentru Stocarea fișierelor media (imagini, video).

Live Streaming: Agora.io - pentru comunicare video în timp real.

Pachete Cheie:

iconsax pentru un set de pictograme modern.

story_view pentru vizualizatorul de story-uri.

video_player & visibility_detector pentru Reels.

agora_rtc_engine pentru integrarea live streaming.

🔧 Cum se Rulează Proiectul
Pentru a rula acest proiect local, urmează pașii de mai jos:

Clonează Repository-ul:

git clone [URL-ul repository-ului tău]
cd gluboom

Instalează Dependențele:

flutter pub get

Configurează Firebase:

Urmează instrucțiunile de pe site-ul FlutterFire pentru a te conecta la contul tău Firebase.

Rulează comanda flutterfire configure pentru a genera fișierul lib/firebase_options.dart și pentru a adăuga google-services.json în folderul android/app.

Asigură-te că ai adăugat amprentele SHA-1 și SHA-256 în setările proiectului tău Firebase.

Configurează Supabase:

Mergi la fișierul lib/main.dart.

Înlocuiește placeholder-ele URL-UL_PROIECTULUI_TAU_SUPABASE și CHEIA_TA_PUBLISHABLE cu cheile tale de la Supabase.

Configurează Agora:

Mergi la fișierul lib/core/config/agora_config.dart.

Înlocuiește placeholder-ul ID-UL_TAU_DE_APLICATIE_AGORA cu App ID-ul tău de la Agora.

Rulează Aplicația:

flutter run

🎯 Planuri de Viitor (To-Do)
[ ] Implementarea sistemului de puncte și donații în timpul live-urilor.

[ ] Finalizarea secțiunii de Evenimente.

[ ] Adăugarea de roluri și permisiuni granulare în grupuri (Admin, Moderator).

[ ] Implementarea unui sistem de notificări push.

[ ] Adăugarea de filtre și opțiuni de editare la postarea de story-uri și reels.
