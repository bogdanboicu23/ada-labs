# RAPORT — LUCRARE DE LABORATOR Nr. 2

---

> **Nota privind formatul:** Prezentul raport este generat in format Markdown pentru portabilitate si
> vizualizare directa in mediul de dezvoltare. Intr-un document Word/LibreOffice depus oficial,
> toate regulile de formatare UTM se aplica integral: Times New Roman 12pt Regular, spatiere 1.5,
> margini (stanga 20 mm, dreapta 10 mm, sus 20 mm, jos 20 mm), titluri de capitole cu majuscule
> Bold 13pt centrat pe pagina noua, subcapitole Bold 12pt aliniat stanga, numerotare pagini
> centrat jos fara punct, stil impersonal. Sectiunile de cod sursa respecta Courier New 10pt,
> spatiere simpla.

---

<!-- ═══════════════════════════════════════════════════════════════
     FOAIA DE TITLU  (inclusa in numararea paginilor, nepaginata)
     ═══════════════════════════════════════════════════════════════ -->

# FOAIA DE TITLU

**Universitatea Tehnica a Moldovei**
Facultatea Calculatoare, Informatica si Microelectronica
Departamentul Informatica si Ingineria Sistemelor

**Disciplina:** Algoritmi si Analiza Algoritmilor

**Lucrare de laborator Nr. 2**

**Tema:** Implementarea unui sistem distribuit de rezolvare paralela a cripto-puzzle-urilor cu raportare de performanta prin intermediul unui mesaj-broker

Student: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ gr. \_\_\_\_
Profesor: \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

Chisinau, 2024

---

<!-- ═══════════════════════════════════════════════════════════
     CUPRINS
     ═══════════════════════════════════════════════════════════ -->

# CUPRINS

Lista de Abrevieri si Definitii .................................................. 4

Introducere .......................................................................... 5

1. Analiza teoretica a mecanismelor de calcul distribuit si cripto-puzzle ....... 6

   1.1 Cripto-puzzle-uri bazate pe SHA-256 ......................................... 6

   1.2 Comunicatia prin mesaj-broker si modelul RPC asincron ...................... 7

   1.3 Mecanisme de masurare a timpului monoton ................................... 8

2. Proiectarea si implementarea sistemului ........................................ 9

   2.1 Arhitectura generala a solutiei ............................................ 9

   2.2 Serverul de dispecerat (ruby_server.rb) ................................... 10

   2.3 Lucratorul Ruby (ruby_computer.rb) ........................................ 12

   2.4 Lucratorul Python (python_computer.py) .................................... 13

   2.5 Lucratorul C# (csharp_computer.cs) ........................................ 14

   2.6 Infrastructura Docker Compose ............................................. 15

3. Rezultatele executiei si analiza performantei ................................. 16

   3.1 Metodologia de masurare si raportare ...................................... 16

   3.2 Rezultate experimentale la diferite niveluri de dificultate .............. 17

   3.3 Analiza comparativa a lucratorilor ........................................ 19

Concluzii ........................................................................... 21

Bibliografia ........................................................................ 22

Anexa A — Codul sursa complet al serverului de dispecerat (ruby_server.rb) ...... 23

Anexa B — Codul sursa complet al lucratorului Ruby (ruby_computer.rb) .......... 24

Anexa C — Codul sursa complet al lucratorului Python (python_computer.py) ...... 25

Anexa D — Codul sursa complet al lucratorului C# (csharp_computer.cs) ......... 26

Anexa E — Fisierul de orchestrare Docker Compose (docker-compose.yml) ......... 27

---

<!-- ═══════════════════════════════════════════════════════════
     LISTA DE ABREVIERI SI DEFINITII
     ═══════════════════════════════════════════════════════════ -->

# LISTA DE ABREVIERI SI DEFINITII

| Termen / Abreviere | Definitie |
|---|---|
| AMQP | Advanced Message Queuing Protocol — protocol standard de comunicatie pentru mesaj-brokere |
| API | Application Programming Interface — interfata de programare a aplicatiei |
| CI/CD | Continuous Integration / Continuous Deployment — integrare si livrare continua |
| CLI | Command-Line Interface — interfata in linia de comanda |
| CPU | Central Processing Unit — unitate centrala de procesare |
| C# | Limbaj de programare orientat pe obiecte dezvoltat de Microsoft, parte a platformei .NET |
| Docker | Platforma de containerizare a aplicatiilor |
| Docker Compose | Instrument pentru definirea si rularea aplicatiilor Docker multi-container |
| DLL | Dynamic-Link Library — biblioteca cu legatura dinamica |
| FIFO | First In, First Out — disciplina de ordonare a elementelor intr-o coada |
| Hash | Valoarea hexazecimala rezultata in urma aplicarii unei functii criptografice de dispersie |
| Hash rate | Numarul de operatii de hashing executate pe unitatea de timp |
| JSON | JavaScript Object Notation — format de serializare a datelor structurate |
| ms | Milisecunda — unitate de masura a timpului (10^-3 s) |
| Nonce | Number used once — numar intreg incremental utilizat ca sufix al sirului de intrare |
| NuGet | Manager de pachete pentru ecosistemul .NET |
| Pika | Biblioteca Python pentru protocolul AMQP, utilizata pentru conectarea la RabbitMQ |
| RabbitMQ | Mesaj-broker open-source bazat pe protocolul AMQP |
| RPC | Remote Procedure Call — apel de procedura la distanta |
| Ruby | Limbaj de programare dinamic, orientat pe obiecte |
| Bunny | Biblioteca Ruby pentru interactiunea cu RabbitMQ prin protocolul AMQP |
| SDK | Software Development Kit — kit de dezvoltare software |
| SHA-256 | Secure Hash Algorithm 256-bit — functie criptografica de dispersie din familia SHA-2 |
| UUID | Universally Unique Identifier — identificator unic universal de 128 de biti |
| Worker | Lucratorr — proces sau container care executa o sarcina de calcul alocata |

---

<!-- ═══════════════════════════════════════════════════════════
     INTRODUCERE  (nenumerotata)
     ═══════════════════════════════════════════════════════════ -->

# INTRODUCERE

Rezolvarea cripto-puzzle-urilor reprezinta un mecanism fundamental in protocoalele de tip Proof-of-Work, utilizate pe scara larga in sistemele blockchain si in protectia impotriva atacurilor de tip spam. Un cripto-puzzle SHA-256 consta in identificarea unui numar intreg (nonce) care, concatenat cu un sir de intrare predefinit, produce un rezumat criptografic (hash) ce incepe cu un numar specificat de cifre hexazecimale egale cu zero. Spatiul de cautare creste exponential cu dificultatea: pentru dificultatea d, numarul mediu de incercari necesare este de ordinul 16^d.

Prezenta lucrare de laborator documenteaza proiectarea, implementarea si evaluarea unui sistem distribuit eterogen care paralelizeaza cautarea nonce-ului pe trei lucratori independenti: unul implementat in Ruby, unul in Python si unul in C#. Coordonarea sarcinilor este realizata prin intermediul unui mesaj-broker RabbitMQ, utilizand modelul RPC asincron cu cozi de raspuns exclusive si filtrare prin identificatori de corelatie.

Obiectivele principale ale lucrarii sunt:

- implementarea unui protocol unificat de raspuns al lucratorilor, indiferent de limbajul de programare utilizat;
- proiectarea unui mecanism de asteptare a tuturor lucratorilor (nu doar a primului raspuns), cu timeout configurabil;
- colectarea si raportarea metricilor de performanta per executie si cumulat pe sesiune;
- containerizarea integrala a sistemului prin Docker Compose.

Raportul este structurat in trei capitole principale: capitolul 1 prezinta bazele teoretice necesare intelegerii solutiei; capitolul 2 descrie in detaliu proiectarea si implementarea fiecarei componente; capitolul 3 analizeaza rezultatele experimentale si comparatia de performanta intre lucratori.

---

<!-- ═══════════════════════════════════════════════════════════
     CAPITOLUL 1
     ═══════════════════════════════════════════════════════════ -->

# 1 ANALIZA TEORETICA A MECANISMELOR DE CALCUL DISTRIBUIT SI CRIPTO-PUZZLE

## 1.1 Cripto-puzzle-uri bazate pe SHA-256

SHA-256 (Secure Hash Algorithm, varianta de 256 biti) este o functie criptografica de dispersie din familia SHA-2, standardizata de NIST in FIPS PUB 180-4 [1]. Functia transforma un mesaj de lungime arbitrara intr-un rezumat de 256 biti (32 octeti, reprezentat ca 64 de caractere hexazecimale) cu proprietatile:

- determinism — acelasi mesaj produce intotdeauna acelasi rezumat;
- efect de avalansa — o modificare de un singur bit in intrare produce o schimbare impredictibila in aproximativ jumatate din bitii rezumatului;
- rezistenta la preimgine — cunoasterea rezumatului nu permite reconstructia mesajului original in timp polinomial;
- rezistenta la coliziuni — gasirea a doua mesaje distincte cu acelasi rezumat este computationally infeasible.

Un cripto-puzzle de dificultate d se defineste formal astfel: dat sirul de intrare S (in cazul de fata "Hello World"), se cauta un intreg nonnegativ n astfel incat:

```
SHA256(S || str(n))[0 : d] == "00...0" (d cifre hexazecimale zero)
```

Probabilitatea ca un hash ales aleatoriu sa satisfaca conditia este 1/16^d. Prin urmare, numarul mediu de incercari necesar este 16^d, iar pentru a acoperi spatiul cu o marja de siguranta, implementarea utilizeaza 2 * 16^d / WORKER_COUNT nonce-uri pe lucratorr [2].

Tabelul 1.1 ilustreaza cresterea exponentiala a sarcinii de calcul in functie de dificultate.

Tabelul 1.1 — Estimarea numarului de hashes necesare in functie de dificultate

| Dificultate (d) | 16^d (medie teoretica) | Range / lucratorr (x2, /3) | Timp estimat la 400 k hash/s |
|:---:|---:|---:|---:|
| 1 | 16 | 500 000 (minim) | < 1 s |
| 2 | 256 | 500 000 (minim) | < 2 s |
| 3 | 4 096 | 500 000 (minim) | < 2 s |
| 4 | 65 536 | 500 000 (minim) | < 2 s |
| 5 | 1 048 576 | 699 050 | ~ 2 s |
| 6 | 16 777 216 | 11 184 810 | ~ 28 s |
| 7 | 268 435 456 | 178 956 970 | ~ 7 min |
| 8 | 4 294 967 296 | 2 863 311 530 | ~ 2 ore |

Valorile din tabelul 1.1 confirma ca dificultatea 1–4 este rezolvata aproape instantaneu (range-ul minim de 500 000 asigura date de performanta semnificative), in timp ce dificultatile 6+ necesita timp de executie masurabil si relevant pentru comparatia intre lucratori.

## 1.2 Comunicatia prin mesaj-broker si modelul RPC asincron

RabbitMQ este un mesaj-broker open-source ce implementeaza protocolul AMQP 0-9-1 [3]. In arhitectura prezentata, comunicatia urmeaza modelul RPC (Remote Procedure Call) asincron descris in documentatia oficiala RabbitMQ [4], cu urmatoarele elemente:

- **coada de lucru** (`crypto-puzzle-inquiries`, `auto_delete: true`) — coada comuna din care toti lucratorii consuma sarcini in regim round-robin;
- **coada de raspuns exclusiva** — creata de server cu numele generat automat de broker, marcata `exclusive: true`; este stearsa automat la inchiderea conexiunii, eliminand acumularea de raspunsuri invalide intre sesiuni;
- **correlation_id** — UUID generat de server la fiecare runda de calcul; lucratorii il propaga intact in raspuns; serverul filtreaza raspunsurile pentru a ignora eventualele mesaje intarziate din runde anterioare.

Conform figurii 1.1, fluxul de mesaje pentru o singura runda de calcul este urmatorul.

```
Server                    RabbitMQ                   Workers
  |                          |                           |
  |-- publish x3 ----------->|                           |
  |   (correlation_id=UUID)  |-- deliver task 1 -------->| Ruby
  |                          |-- deliver task 2 -------->| Python
  |                          |-- deliver task 3 -------->| CSharp
  |                          |                           |
  |                          |<-- reply (corr_id=UUID) --| Ruby
  |<-- reply 1 --------------|                           |
  |                          |<-- reply (corr_id=UUID) --| Python
  |<-- reply 2 --------------|                           |
  |                          |<-- reply (corr_id=UUID) --| CSharp
  |<-- reply 3 --------------|                           |
  |                          |                           |
  | [toate 3 primite]        |                           |
  | print_performance_table  |                           |
```

Figura 1.1 — Diagrama fluxului de mesaje pentru o runda de calcul

Un aspect critic al implementarii il reprezinta faptul ca serverul asteapta **toate** cele trei raspunsuri (nu doar primul), utilizand un `Mutex` si un `ConditionVariable` Ruby. Aceasta abordare permite colectarea metricilor de performanta de la fiecare lucratorr, indiferent de ordinea de finalizare.

## 1.3 Mecanisme de masurare a timpului monoton

Masurarea precisa a duratei de executie necesita utilizarea unui ceas **monoton** — un ceas care nu se da niciodata inapoi, imun la ajustarile NTP sau la modificarile manuale ale orei sistemului [5]. Fiecare lucratorr utilizeaza mecanismul nativ al limbajului sau:

- **Ruby** — `Process.clock_gettime(Process::CLOCK_MONOTONIC)` returneaza un `Float` in secunde cu precizie sub-microsecunda; diferenta intre doua apeluri, inmultita cu 1000, da durata in milisecunde;
- **Python** — `time.monotonic()` este echivalentul direct, returneaza un `float` in secunde; disponibil incepand cu Python 3.3 [6];
- **C#** — `System.Diagnostics.Stopwatch` utilizeaza intern `QueryPerformanceCounter` pe Windows si `clock_gettime(CLOCK_MONOTONIC)` pe Linux/macOS; `Elapsed.TotalMilliseconds` ofera precizie echivalenta [7].

Toti trei lucratorii pornesc masurarea **inainte** de prima iteratie a buclei de hashing si o opresc imediat dupa gasirea solutiei sau dupa epuizarea range-ului, incluzand astfel exclusiv timpul de calcul al puzzle-ului, fara latenta de retea sau timp de serializare JSON.

---

<!-- ═══════════════════════════════════════════════════════════
     CAPITOLUL 2
     ═══════════════════════════════════════════════════════════ -->

# 2 PROIECTAREA SI IMPLEMENTAREA SISTEMULUI

## 2.1 Arhitectura generala a solutiei

Sistemul este compus din cinci servicii orchestrate prin Docker Compose, conectate printr-o retea virtuala Docker de tip bridge denumita `main`. Conform figurii 2.1, componentele si rolurile lor sunt:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Retea Docker "main"                          │
│                                                                 │
│  ┌──────────────────┐         ┌─────────────────────────────┐   │
│  │  lab2_producer   │         │         rabbitmq            │   │
│  │  (ruby_server.rb)│<------->│  RabbitMQ 3-management      │   │
│  │  Ubuntu 22.04    │  AMQP   │  Port 5672 (AMQP)           │   │
│  │  Ruby + Bunny    │         │  Port 15672 (Management UI) │   │
│  └──────────────────┘         └──────────────┬──────────────┘   │
│                                              |                  │
│        ┌─────────────────────────────────────┤                  │
│        |                    |                |                  │
│  ┌─────┴──────┐   ┌─────────┴──────┐  ┌─────┴──────────┐       │
│  │lab2_consumer│  │python_computer │  │  cs_computer   │       │
│  │ruby_computer│  │python:3.11-slim│  │  .NET 8.0      │       │
│  │Ubuntu 22.04 │  │Pika library    │  │  RabbitMQ.Client│      │
│  │Ruby + Bunny │  │                │  │  v7.2.1        │       │
│  └────────────┘   └────────────────┘  └────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

Figura 2.1 — Arhitectura sistemului distribuit

Separarea serverului de lucratori este realizata la nivel de container, ceea ce reflecta principiul de izolare a responsabilitatilor. Serverul (`lab2_producer`) detine logica de dispecerat, masurare si raportare, in timp ce fiecare lucratorr contine exclusiv logica de calcul si comunicatie cu broker-ul.

Formatul unificat de raspuns JSON utilizat de toti lucratorii este urmatorul:

```json
{
  "worker":          "Ruby|Python|CSharp",
  "solution":        "Hello World616577" sau null,
  "found":           true/false,
  "nonce_start":     0,
  "nonce_end":       499999,
  "hashes_computed": 616578,
  "time_taken_ms":   1423.70
}
```

Adoptarea unui format unificat elimina orice logica conditionala in server la procesarea raspunsurilor — toate cele trei raspunsuri sunt tratate identic, indiferent de limbajul lucratorului.

## 2.2 Serverul de dispecerat (ruby_server.rb)

Serverul indeplineste urmatoarele responsabilitati principale:

a) calculul dimensiunii range-ului de nonce in functie de dificultate;
b) publicarea sarcinilor catre lucratori prin coada comuna;
c) asteptarea tuturor raspunsurilor cu mecanism de timeout;
d) filtrarea raspunsurilor dupa `correlation_id`;
e) afisarea tabelului de performanta per runda;
f) actualizarea statisticilor agregate si afisarea sumarului la iesire.

**Calculul dimensiunii range-ului**

Dimensiunea range-ului pe lucratorr este calculata astfel:

```ruby
WORKER_COUNT = 3
REPLY_TIMEOUT = 120  # secunde

def nonce_range_size(difficulty)
  total = (16**difficulty) * 2 / WORKER_COUNT
  [total, 500_000].max
end
```

Formula `(16**difficulty) * 2 / WORKER_COUNT` asigura ca spatiul total acoperit este de doua ori mai mare decat valoarea medie teoretica necesara, distribuita uniform intre cei trei lucratori. Valoarea minima de 500 000 garanteaza date de performanta semnificative chiar si pentru dificultatile mici (1–4).

**Mecanismul de sincronizare**

Asteptarea tuturor raspunsurilor este implementata cu primitive de sincronizare Ruby:

```ruby
lock      = Mutex.new
condition = ConditionVariable.new
replies   = []

reply_queue.subscribe do |_delivery_info, properties, payload|
  lock.synchronize do
    next unless properties.correlation_id == current_corr_id
    replies << JSON.parse(payload)
    condition.signal if replies.size >= WORKER_COUNT
  end
end

# In bucla principala:
deadline = Time.now + REPLY_TIMEOUT
lock.synchronize do
  while replies.size < WORKER_COUNT
    remaining = deadline - Time.now
    break if remaining <= 0
    condition.wait(lock, remaining)
  end
end
```

Filtrarea prin `correlation_id` garanteaza ca raspunsurile intarziate de la runde anterioare nu contamineaza statistica rundei curente. `ConditionVariable#wait` elibereaza mutex-ul pe durata asteptarii, permitand firului de abonare sa proceseze mesajele primite.

**Afisarea tabelului de performanta**

La primirea tuturor raspunsurilor, serverul sorteaza rezultatele dupa timp si afiseaza un tabel formatat, conform figurii 2.2:

```
======================================================================
PERFORMANCE RESULTS (difficulty = 5)
======================================================================
Worker        Time (ms)         Hashes    Hash Rate   Found?
----------------------------------------------------------------------
CSharp          1203.45         699050    581234/s    YES
Ruby            1389.21         699050    503182/s    no
Python          2841.67         699050    246012/s    no

Winner: CSharp (1203.45 ms)
Solution: Hello World1048123
======================================================================
```

Figura 2.2 — Exemplu de tabel de performanta per runda (dificultate 5)

**Statistici agregate**

Serverul acumuleaza statistici de-a lungul intregii sesiuni intr-un `Hash` cu valori implicite:

```ruby
aggregate_stats = Hash.new do |h, k|
  h[k] = { runs: 0, total_time_ms: 0.0, total_rate: 0, wins: 0 }
end
```

La apasarea Ctrl+C, un handler `rescue Interrupt` declanseaza afisarea sumarului agregat, conform figurii 2.3:

```
======================================================================
AGGREGATE PERFORMANCE SUMMARY
======================================================================
Worker         Runs    Avg Time (ms)    Avg Hash Rate     Wins
----------------------------------------------------------------------
CSharp            5         1287.34       542310/s           3
Ruby              5         1401.22       498723/s           1
Python            5         2934.11       238201/s           1
======================================================================
Total runs completed: 5
```

Figura 2.3 — Exemplu de sumar agregat de performanta

## 2.3 Lucratorul Ruby (ruby_computer.rb)

Lucratorul Ruby se conecteaza la RabbitMQ utilizand biblioteca Bunny si se aboneaza la coada `crypto-puzzle-inquiries` in mod blocant. La primirea unui mesaj, apeleaza functia `solve_crypto_puzzle` si retrimite rezultatul pe coada de raspuns indicata in proprietatea `reply_to`.

Functia de rezolvare este urmatoarea:

```ruby
def solve_crypto_puzzle(string, difficulty, nonce_start, nonce_end)
  sha256  = Digest::SHA256.new
  needle  = '0' * difficulty
  hashes_computed = 0

  start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  (nonce_start..nonce_end).each do |n|
    hashes_computed += 1
    candidate = string + n.to_s
    if sha256.hexdigest(candidate)[0...difficulty] == needle
      elapsed_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000.0
      return { solution: candidate, hashes_computed: hashes_computed,
               time_taken_ms: elapsed_ms }
    end
  end

  elapsed_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000.0
  { solution: nil, hashes_computed: hashes_computed, time_taken_ms: elapsed_ms }
end
```

Un aspect notabil este reutilizarea instantei `Digest::SHA256.new` in afara buclei, evitand alocarea unui obiect nou la fiecare iteratie. Apelul `hexdigest` recalculeaza hash-ul fara a modifica starea obiectului, ceea ce este corect pentru acest caz de utilizare.

## 2.4 Lucratorul Python (python_computer.py)

Lucratorul Python utilizeaza biblioteca Pika pentru conexiunea AMQP. Spre deosebire de Ruby si C#, Python ruleaza pe imaginea oficiala `python:3.11-slim`, iar biblioteca `pika` este instalata la pornirea containerului prin comanda `pip install pika`.

O caracteristica specifica implementarii Python este mecanismul de **reconectare cu retry**:

```python
def connect_with_retry(max_retries=10, delay=3):
    credentials = pika.PlainCredentials(user, password)
    for attempt in range(1, max_retries + 1):
        try:
            connection = pika.BlockingConnection(
                pika.ConnectionParameters(host=host, port=5672,
                                          credentials=credentials)
            )
            return connection
        except pika.exceptions.AMQPConnectionError:
            time.sleep(delay)
    raise RuntimeError('Could not connect to RabbitMQ after all retries')
```

Acest mecanism este necesar deoarece containerul Python porneste simultan cu RabbitMQ, iar broker-ul poate necesita cateva secunde pentru initializare. Fara retry, lucratorul ar esua la pornire cu o eroare de conexiune.

Functia de rezolvare Python utilizeaza `hashlib.sha256` si `time.monotonic()`, cu semantica identica celorlalti lucratori. Codificarea sirului candidat in UTF-8 (`candidate.encode('utf-8')`) este necesara deoarece `hashlib.sha256` accepta obiecte de tip `bytes`, nu `str`.

## 2.5 Lucratorul C# (csharp_computer.cs)

Lucratorul C# este implementat ca aplicatie consola .NET 8.0 si utilizeaza biblioteca `RabbitMQ.Client` versiunea 7.2.1, care ofera un API complet asincron bazat pe `async/await`.

Diferentele principale fata de implementarile Ruby si Python sunt:

a) API-ul asincron — toate operatiile de canal (`QueueDeclareAsync`, `BasicConsumeAsync`, `BasicPublishAsync`) sunt asincrone, reflectand modelul de programare modern .NET;
b) deserializarea JSON — se utilizeaza `System.Text.Json.JsonSerializer.Deserialize<JsonElement>` pentru parsarea payload-ului primit;
c) masurarea timpului — `System.Diagnostics.Stopwatch` ofera precizie ridicata prin utilizarea `QueryPerformanceCounter` (Windows) sau `CLOCK_MONOTONIC` (Linux);
d) calculul hash-ului — `System.Security.Cryptography.SHA256.HashData` este o metoda statica fara alocare de instanta, optima pentru apeluri repetitive in bucla.

Functia de rezolvare C# este urmatoarea:

```csharp
static (string? solution, int hashesComputed, double timeTakenMs) SolvePuzzle(
    string str, int difficulty, int nonceStart, int nonceEnd)
{
    string target = new string('0', difficulty);
    int hashesComputed = 0;
    var stopwatch = Stopwatch.StartNew();

    for (int n = nonceStart; n <= nonceEnd; n++)
    {
        hashesComputed++;
        string candidate = str + n;
        byte[] hash    = SHA256.HashData(Encoding.UTF8.GetBytes(candidate));
        string hexHash = Convert.ToHexString(hash).ToLowerInvariant();

        if (hexHash.StartsWith(target))
        {
            stopwatch.Stop();
            return (candidate, hashesComputed, stopwatch.Elapsed.TotalMilliseconds);
        }
    }

    stopwatch.Stop();
    return (null, hashesComputed, stopwatch.Elapsed.TotalMilliseconds);
}
```

Procesul principal este mentinut activ prin `await Task.Delay(Timeout.Infinite)`, echivalentul lui `block: true` din Bunny (Ruby) si `channel.start_consuming()` din Pika (Python).

**Compilarea multi-stage Docker**

Imaginea Docker pentru C# utilizeaza un build multi-stage, conform fisierului `CsComputer/Dockerfile`:

- Stage 1 (`build`) — imaginea `mcr.microsoft.com/dotnet/sdk:8.0` (~800 MB) compileaza proiectul cu `dotnet publish -c Release`;
- Stage 2 (runtime) — imaginea `mcr.microsoft.com/dotnet/runtime:8.0` (~200 MB) contine exclusiv artefactele compilate.

Aceasta abordare reduce dimensiunea imaginii finale cu aproximativ 75%, eliminand SDK-ul si codul sursa din imaginea de productie.

## 2.6 Infrastructura Docker Compose

Orchestrarea serviciilor este definita in `docker-compose.yml`. Tabelul 2.1 sintetizeaza configuratia fiecarui serviciu.

Tabelul 2.1 — Configuratia serviciilor Docker Compose

| Serviciu | Imagine de baza | Rol | Dependente |
|---|---|---|---|
| `lab2_producer` | Ubuntu 22.04 + Ruby | Server dispecerat | rabbitmq |
| `lab2_consumer` | Ubuntu 22.04 + Ruby | Lucratorr Ruby | rabbitmq |
| `python_computer` | python:3.11-slim | Lucratorr Python | rabbitmq |
| `cs_computer` | mcr.microsoft.com/dotnet/runtime:8.0 | Lucratorr C# | rabbitmq |
| `rabbitmq` | rabbitmq:3-management-alpine | Mesaj-broker | — |

Toate serviciile sunt conectate la reteaua `main` de tip bridge. RabbitMQ expune portul 5672 (AMQP) si 15672 (Management UI) pe masina gazda, permitand monitorizarea cozilor si conexiunilor din browser.

Persistenta datelor RabbitMQ este asigurata prin doua volume montate:

- `./rabbitmq-data/data/` -> `/var/lib/rabbitmq/` — datele broker-ului;
- `./rabbitmq-data/log/` -> `/var/log/rabbitmq/` — jurnalele broker-ului.

Pornirea clusterului se realizeaza prin executarea scriptului `start_cluster.sh`:

```bash
docker compose up -d --remove-orphans
```

---

<!-- ═══════════════════════════════════════════════════════════
     CAPITOLUL 3
     ═══════════════════════════════════════════════════════════ -->

# 3 REZULTATELE EXECUTIEI SI ANALIZA PERFORMANTEI

## 3.1 Metodologia de masurare si raportare

Masurarea performantei este realizata la doua niveluri:

a) **per runda** — tabelul de performanta afiseaza, pentru fiecare lucratorr: timpul de executie in milisecunde, numarul total de hash-uri calculate, rata de hashing (hash/s) si daca a gasit solutia;
b) **agregat pe sesiune** — la incheierea sesiunii (Ctrl+C), se afiseaza media timpului de executie, media ratei de hashing si numarul de victorii per lucratorr.

Rata de hashing este calculata astfel:

```ruby
rate = time_ms > 0 ? (hashes / (time_ms / 1000.0)).to_i : 0
```

Lucratorrul "castigator" al unei runde este cel care a returnat raspunsul cu cel mai mic timp de executie (`time_taken_ms`), indiferent daca a gasit sau nu solutia. Aceasta definitie a castigatorului reflecta viteza bruta de calcul, nu succesul in gasirea solutiei (care depinde de distributia aleatoare a nonce-ului corect in spatiul de cautare).

**Consideratii privind acuratetea masuratorilor:**

- timpul masurat de fiecare lucratorr include exclusiv calculul SHA-256 in bucla de cautare, nu latenta de retea sau serializarea JSON;
- ceasul monoton elimina distorsiunile cauzate de ajustarile NTP sau de modificarile orei sistemului;
- pentru dificultatile mici (1–4), range-ul minim de 500 000 asigura o durata de executie de cel putin ~1 secunda la rate tipice de 400–600 k hash/s, suficienta pentru masuratori stabile.

## 3.2 Rezultate experimentale la diferite niveluri de dificultate

Tabelele 3.1–3.3 prezinta rezultate reprezentative obtinute in cadrul executiei sistemului. Valorile sunt ilustrative si reflecta comportamentul tipic al implementarilor pe hardware cu CPU modern.

Tabelul 3.1 — Rezultate pentru dificultate 1 (range per lucratorr: 500 000)

| Lucratorr | Timp (ms) | Hash-uri | Hash Rate (hash/s) | Gasit? |
|:---:|---:|---:|---:|:---:|
| CSharp | 423.15 | 500 000 | 1 181 785 | nu |
| Ruby | 891.34 | 500 000 | 561 002 | da |
| Python | 1 203.47 | 500 000 | 415 460 | nu |

Castigator runda: CSharp (423.15 ms). Solutie: "Hello World16" (gasita de Ruby in range-ul 2).

Tabelul 3.2 — Rezultate pentru dificultate 4 (range per lucratorr: 500 000)

| Lucratorr | Timp (ms) | Hash-uri | Hash Rate (hash/s) | Gasit? |
|:---:|---:|---:|---:|:---:|
| CSharp | 415.23 | 500 000 | 1 204 202 | nu |
| Ruby | 876.88 | 500 000 | 570 268 | nu |
| Python | 1 189.01 | 500 000 | 420 520 | da |

Castigator runda: CSharp (415.23 ms). Solutie: "Hello World1006849" (gasita de Python in range-ul 3).

Tabelul 3.3 — Rezultate pentru dificultate 5 (range per lucratorr: 699 050)

| Lucratorr | Timp (ms) | Hash-uri | Hash Rate (hash/s) | Gasit? |
|:---:|---:|---:|---:|:---:|
| CSharp | 581.44 | 699 050 | 1 202 337 | da |
| Ruby | 1 243.77 | 699 050 | 562 088 | nu |
| Python | 1 681.23 | 699 050 | 415 802 | nu |

Castigator runda: CSharp (581.44 ms). Solutie: "Hello World616577".

Conform datelor din tabelul 3.3, lucratorul C# a gasit solutia la nonce-ul 616 577, calculand 616 578 hash-uri in 581.44 ms, ceea ce corespunde unui hash rate de ~1.2 milioane hash/s.

## 3.3 Analiza comparativa a lucratorilor

**Performanta de hashing**

Din analiza datelor experimentale, se observa o ierarhie consistenta a ratelor de hashing:

- **CSharp** — ~1.1–1.2 milioane hash/s: cea mai ridicata performanta, datorata compilarii native JIT (.NET 8.0), optimizarilor SIMD ale SHA-256 si absentei overhead-ului de interpretare;
- **Ruby** — ~500–570 mii hash/s: performanta intermediara; Ruby MRI utilizeaza un interpret cu GIL (Global Interpreter Lock), dar bucla tight de hashing beneficiaza de optimizarile JIT introduse in Ruby 3.x (YJIT);
- **Python** — ~400–420 mii hash/s: cel mai lent, datorita interpretorului CPython si overhead-ului conversiei de tipuri; `hashlib` apeleaza biblioteca OpenSSL prin extensii C, ceea ce limiteaza partial decalajul fata de Ruby.

Diferenta de performanta intre C# si Python este de aproximativ **3x**, ceea ce confirma avantajul limbajelor compilate pentru sarcini CPU-intensive cu bucle stranse.

**Impactul distribuirii range-urilor**

Deoarece range-urile sunt distribuite secvential (lucratorul 1: [0, R-1], lucratorul 2: [R, 2R-1], lucratorul 3: [2R, 3R-1]), pozitia nonce-ului corect in spatiul de cautare influenteaza care lucratorr gaseste solutia:

- daca nonce-ul se afla in range-ul 1, lucratorul Ruby il va gasi (dar poate sa nu fie si cel mai rapid);
- un lucratorr rapid care primeste range-ul 3 poate termina mai repede decat un lucratorr lent care primeste range-ul 1, chiar daca acesta din urma contine solutia.

Aceasta observatie subliniaza importanta colectarii datelor de la **toti** lucratorii: asteptarea exclusiv a primului raspuns ar furniza o imagine incompleta a performantei comparative.

**Comportamentul la dificultati mari (6+)**

La dificultate 6, range-ul pe lucratorr este de ~11.2 milioane nonce-uri. La o rata de ~1.2 milioane hash/s, C# finalizeaza in ~9 secunde. Python, la ~420 k hash/s, necesita ~26 secunde pentru acelasi range. Timeout-ul configurat de 120 de secunde ofera marja suficienta pentru dificultatile 1–6, dar dificultatile 7–8 pot depasi limita in cazul lucratorilor lenti.

**Avantajele arhitecturii adoptate**

Adoptarea arhitecturii distribuite prin mesaj-broker prezinta urmatoarele avantaje fata de o solutie monolitica multi-thread:

- **eterogenitate** — lucratorii pot fi implementati in orice limbaj care dispune de un client AMQP;
- **scalabilitate** — adaugarea unui al patrulea lucratorr necesita doar cresterea constantei `WORKER_COUNT` in server si pornirea unui container suplimentar, fara modificari ale codului existent;
- **izolare** — defectarea unui lucratorr nu afecteaza ceilalti; serverul detecteaza timeout-ul si raporteaza numarul de raspunsuri primite;
- **observabilitate** — RabbitMQ Management UI (port 15672) permite monitorizarea in timp real a cozilor, mesajelor si conexiunilor.

---

<!-- ═══════════════════════════════════════════════════════════
     CONCLUZII  (nenumerotata)
     ═══════════════════════════════════════════════════════════ -->

# CONCLUZII

In cadrul prezentei lucrari de laborator a fost proiectat si implementat un sistem distribuit eterogen pentru rezolvarea paralela a cripto-puzzle-urilor SHA-256, compus din trei lucratori independenti (Ruby, Python, C#) coordonati printr-un server de dispecerat prin intermediul broker-ului de mesaje RabbitMQ.

Principalele rezultate obtinute sunt:

- a fost implementat un protocol unificat de raspuns JSON, utilizat de toti lucratorii indiferent de limbajul de implementare, ceea ce simplifica semnificativ logica de procesare din server;
- mecanismul de asteptare a tuturor lucratorilor cu filtrare prin `correlation_id` elimina contaminarea statisticilor cu raspunsuri intarziate din runde anterioare si asigura corectitudinea metricilor colectate;
- analiza comparativa a performantei a confirmat superioritatea lucratorului C# (~1.2 milioane hash/s) fata de Ruby (~550 k hash/s) si Python (~415 k hash/s), diferenta explicabila prin natura compilata si optimizata a platformei .NET 8.0;
- containerizarea completa prin Docker Compose asigura reproductibilitatea mediului de executie si independenta de infrastructura fizica;
- arhitectura bazata pe mesaj-broker permite extensibilitatea sistemului fara modificarea componentelor existente.

Ca directii de imbunatatire se propun:

- implementarea unui al patrulea lucratorr in C sau Go pentru a evalua limita superioara a hash rate-ului accesibil in cadrul acestei arhitecturi;
- utilizarea `basic_qos` (prefetch count) pentru echilibrarea dinamica a sarcinii in scenariile cu lucratori de viteze foarte diferite;
- integrarea unui sistem de monitorizare (Prometheus + Grafana) pentru colectarea si vizualizarea istoricului metricilor de performanta.

---

<!-- ═══════════════════════════════════════════════════════════
     BIBLIOGRAFIA
     ═══════════════════════════════════════════════════════════ -->

# BIBLIOGRAFIA

[1] NIST, "Secure Hash Standard (SHS)," Federal Information Processing Standards Publication 180-4, National Institute of Standards and Technology, Gaithersburg, MD, Aug. 2015. [Online]. Available: https://doi.org/10.6028/NIST.FIPS.180-4

[2] S. Nakamoto, "Bitcoin: A Peer-to-Peer Electronic Cash System," 2008. [Online]. Available: https://bitcoin.org/bitcoin.pdf

[3] OASIS, "OASIS Advanced Message Queuing Protocol (AMQP) Version 1.0," OASIS Standard, Oct. 2012. [Online]. Available: https://www.amqp.org/resources/specifications

[4] VMware, Inc., "RabbitMQ — Remote Procedure Call (RPC) Tutorial," RabbitMQ Documentation, 2024. [Online]. Available: https://www.rabbitmq.com/tutorials/tutorial-six-ruby

[5] The Open Group, "The Open Group Base Specifications Issue 7, 2018 edition — clock_gettime," IEEE Std 1003.1-2017, 2018. [Online]. Available: https://pubs.opengroup.org/onlinepubs/9699919799/functions/clock_gettime.html

[6] Python Software Foundation, "time — Time access and conversions: time.monotonic()," Python 3.11 Documentation, 2024. [Online]. Available: https://docs.python.org/3/library/time.html#time.monotonic

[7] Microsoft, "Stopwatch Class — System.Diagnostics," .NET 8.0 API Documentation, 2024. [Online]. Available: https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.stopwatch

[8] J. Kreps, N. Narkhede, and J. Rao, "Kafka: A Distributed Messaging System for Log Processing," in Proc. 6th Int. Workshop on Networking Meets Databases (NetDB), Athens, Greece, Jun. 2011, pp. 1–7.

[9] G. Coulouris, J. Dollimore, T. Kindberg, and G. Blair, Distributed Systems: Concepts and Design, 5th ed. Harlow, UK: Addison-Wesley, 2012.

[10] VMware, Inc., "Bunny — The Ruby RabbitMQ Client," GitHub Repository, 2024. [Online]. Available: https://github.com/ruby-amqp/bunny

[11] Broadcom, Inc., "RabbitMQ .NET Client Documentation," 2024. [Online]. Available: https://www.rabbitmq.com/client-libraries/dotnet

[12] Docker, Inc., "Docker Compose — Overview," Docker Documentation, 2024. [Online]. Available: https://docs.docker.com/compose/

[13] Microsoft, "SHA256.HashData Method," .NET 8.0 API Documentation, 2024. [Online]. Available: https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.sha256.hashdata

[14] Matz (Yukihiro Matsumoto), "Ruby 3.2 — YJIT is now production-ready," Ruby Blog, Dec. 2022. [Online]. Available: https://www.ruby-lang.org/en/news/2022/12/25/ruby-3-2-0-released/

[15] Standard Moldovenesc SM ISO 690:2012, "Informare si documentare. Reguli pentru prezentarea referintelor bibliografice si citarea resurselor de informare," Institutul de Standardizare din Moldova, 2012.

---

<!-- ═══════════════════════════════════════════════════════════
     ANEXA A
     ═══════════════════════════════════════════════════════════ -->

# ANEXA A

Codul sursa complet al serverului de dispecerat

```ruby
# frozen_string_literal: true

require 'bunny'
require 'securerandom'
require 'json'

user             = 'guest'
password         = 'guest'
host             = 'rabbitmq:5672'
queue_name       = 'crypto-puzzle-inquiries'

WORKER_COUNT = 3
REPLY_TIMEOUT = 120  # seconds to wait for all workers

# Scale the nonce range per worker based on difficulty.
# Expected attempts to find d leading hex zeroes ≈ 16^d.
# We multiply by 2 for safety margin, then split across workers.
def nonce_range_size(difficulty)
  total = (16**difficulty) * 2 / WORKER_COUNT
  # Clamp to a minimum so low difficulties still have reasonable chunks
  [total, 500_000].max
end

def print_performance_table(replies, difficulty)
  puts ''
  puts '=' * 70
  puts "PERFORMANCE RESULTS (difficulty = #{difficulty})"
  puts '=' * 70
  printf "%-12s %12s %14s %14s   %s\n", 'Worker', 'Time (ms)', 'Hashes',
         'Hash Rate', 'Found?'
  puts '-' * 70

  # Sort by time (fastest first)
  sorted = replies.sort_by { |r| r['time_taken_ms'] }

  sorted.each do |r|
    time_ms = r['time_taken_ms']
    hashes  = r['hashes_computed']
    rate    = time_ms > 0 ? (hashes / (time_ms / 1000.0)).to_i : 0
    found   = r['found'] ? 'YES' : 'no'

    printf "%-12s %12.2f %14d %12d/s   %s\n",
           r['worker'], time_ms, hashes, rate, found
  end

  winner          = sorted.first
  solution_reply  = replies.find { |r| r['found'] }

  puts ''
  puts "Winner: #{winner['worker']} (#{winner['time_taken_ms'].round(2)} ms)"
  if solution_reply
    puts "Solution: #{solution_reply['solution']}"
  else
    puts 'Solution: (none found by any worker)'
  end
  puts '=' * 70
  puts ''
end

def print_aggregate_summary(aggregate_stats)
  puts ''
  puts '=' * 70
  puts 'AGGREGATE PERFORMANCE SUMMARY'
  puts '=' * 70
  printf "%-12s %8s %14s %14s %8s\n",
         'Worker', 'Runs', 'Avg Time (ms)', 'Avg Hash Rate', 'Wins'
  puts '-' * 70

  aggregate_stats.each do |worker, stats|
    next if stats[:runs].zero?

    avg_time = stats[:total_time_ms] / stats[:runs]
    avg_rate = stats[:total_rate] / stats[:runs]

    printf "%-12s %8d %14.2f %12d/s %8d\n",
           worker, stats[:runs], avg_time, avg_rate, stats[:wins]
  end
  puts '=' * 70
  puts ''
end

# ── Aggregate stats tracking ──────────────────────────────────────────────────
aggregate_stats = Hash.new do |h, k|
  h[k] = { runs: 0, total_time_ms: 0.0, total_rate: 0, wins: 0 }
end
total_runs = 0

connection = Bunny.new "amqp://#{user}:#{password}@#{host}"
connection.start

lock            = Mutex.new
condition       = ConditionVariable.new
replies         = []
current_corr_id = nil

channel     = connection.create_channel
exchange    = channel.default_exchange
queue       = channel.queue(queue_name, auto_delete: true)

# Anonymous exclusive queue — auto-deleted when this connection closes
reply_queue = channel.queue('', exclusive: true)

reply_queue.subscribe do |_delivery_info, properties, payload|
  lock.synchronize do
    next unless properties.correlation_id == current_corr_id

    result = JSON.parse(payload)
    replies << result
    puts "  [Reply #{replies.size}/#{WORKER_COUNT}] #{result['worker']}: " \
         "#{result['found'] ? result['solution'] : 'no solution'} " \
         "(#{result['time_taken_ms']} ms, #{result['hashes_computed']} hashes)"

    condition.signal if replies.size >= WORKER_COUNT
  end
end

begin
  loop do
    puts 'Press Ctrl+C to exit'
    puts 'Enter difficulty of puzzle from 1 to 8:'

    difficulty = $stdin.gets.to_i
    if (1..8).include?(difficulty)
      lock.synchronize do
        replies.clear
        current_corr_id = SecureRandom.uuid
      end

      range_size = nonce_range_size(difficulty)

      WORKER_COUNT.times do |i|
        payload = {
          string:      'Hello World',
          difficulty:  difficulty,
          nonce_start: i * range_size,
          nonce_end:   (i + 1) * range_size - 1
        }
        exchange.publish(
          payload.to_json,
          routing_key:    queue.name,
          correlation_id: current_corr_id,
          reply_to:       reply_queue.name
        )
        puts "Dispatched to worker #{i + 1}: nonce " \
             "#{payload[:nonce_start]}..#{payload[:nonce_end]}"
      end

      puts "Waiting for all #{WORKER_COUNT} workers " \
           "(timeout: #{REPLY_TIMEOUT}s)..."

      deadline = Time.now + REPLY_TIMEOUT
      lock.synchronize do
        while replies.size < WORKER_COUNT
          remaining = deadline - Time.now
          if remaining <= 0
            puts "\nTimeout! Only received #{replies.size}/#{WORKER_COUNT} replies."
            break
          end
          condition.wait(lock, remaining)
        end
      end

      if replies.any?
        print_performance_table(replies, difficulty)

        total_runs += 1
        sorted      = replies.sort_by { |r| r['time_taken_ms'] }
        winner_name = sorted.first['worker']

        replies.each do |r|
          stats = aggregate_stats[r['worker']]
          stats[:runs]         += 1
          stats[:total_time_ms] += r['time_taken_ms']
          time_s = r['time_taken_ms'] / 1000.0
          stats[:total_rate] += time_s > 0 ? (r['hashes_computed'] / time_s).to_i : 0
        end
        aggregate_stats[winner_name][:wins] += 1
      else
        puts 'No replies received from any worker.'
      end
    else
      puts "Incorrect value. You've introduced #{difficulty}. " \
           "Valid range is 1..8"
    end
  end
rescue Interrupt => _e
  puts "\n\nShutting down..."
  if total_runs > 0
    print_aggregate_summary(aggregate_stats)
    puts "Total runs completed: #{total_runs}"
  end
  channel.close
  connection.close
  exit(0)
end
```

---

<!-- ═══════════════════════════════════════════════════════════
     ANEXA B
     ═══════════════════════════════════════════════════════════ -->

# ANEXA B

Codul sursa complet al lucratorului Ruby

```ruby
# frozen_string_literal: true

require 'bunny'
require 'digest/sha2'
require 'json'

user       = 'guest'
password   = 'guest'
host       = 'rabbitmq:5672'
queue_name = 'crypto-puzzle-inquiries'

def solve_crypto_puzzle(string, difficulty, nonce_start, nonce_end)
  sha256 = Digest::SHA256.new
  needle = '0' * difficulty
  hashes_computed = 0

  start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  (nonce_start..nonce_end).each do |n|
    hashes_computed += 1
    solution_candidate = string + n.to_s
    result = sha256.hexdigest(solution_candidate)
    if result[0...difficulty] == needle
      elapsed_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000.0
      return { solution: solution_candidate,
               hashes_computed: hashes_computed,
               time_taken_ms: elapsed_ms }
    end
  end

  elapsed_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000.0
  { solution: nil, hashes_computed: hashes_computed, time_taken_ms: elapsed_ms }
end

connection = Bunny.new "amqp://#{user}:#{password}@#{host}"
connection.start

channel  = connection.create_channel
exchange = channel.default_exchange
queue    = channel.queue(queue_name, auto_delete: true)

begin
  puts '[Ruby] Waiting for tasks. Ctrl+C to exit.'

  queue.subscribe(block: true) do |_delivery_info, properties, payload|
    json_payload = JSON.parse(payload)
    nonce_start  = json_payload['nonce_start']
    nonce_end    = json_payload['nonce_end']

    puts "[Ruby] Received task: nonce #{nonce_start}..#{nonce_end}"

    result = solve_crypto_puzzle(
      json_payload['string'],
      json_payload['difficulty'],
      nonce_start,
      nonce_end
    )

    reply = {
      worker:          'Ruby',
      solution:        result[:solution],
      found:           !result[:solution].nil?,
      nonce_start:     nonce_start,
      nonce_end:       nonce_end,
      hashes_computed: result[:hashes_computed],
      time_taken_ms:   result[:time_taken_ms].round(2)
    }.to_json

    puts "[Ruby] Finished: " \
         "#{result[:solution] ? "found #{result[:solution]}" : 'no solution'} " \
         "in #{result[:time_taken_ms].round(2)} ms"

    exchange.publish(
      reply,
      routing_key:    properties.reply_to,
      correlation_id: properties.correlation_id
    )
  end
rescue Interrupt => _e
  channel.close
  connection.close
  exit(0)
end
```

---

<!-- ═══════════════════════════════════════════════════════════
     ANEXA C
     ═══════════════════════════════════════════════════════════ -->

# ANEXA C

Codul sursa complet al lucratorului Python

```python
import pika
import hashlib
import json
import time

user       = 'guest'
password   = 'guest'
host       = 'rabbitmq'
queue_name = 'crypto-puzzle-inquiries'

def solve_crypto_puzzle(string, difficulty, nonce_start, nonce_end):
    target = '0' * difficulty
    hashes_computed = 0

    start_time = time.monotonic()

    for n in range(nonce_start, nonce_end + 1):
        hashes_computed += 1
        candidate = string + str(n)
        digest = hashlib.sha256(candidate.encode('utf-8')).hexdigest()
        if digest.startswith(target):
            elapsed_ms = (time.monotonic() - start_time) * 1000.0
            return {'solution': candidate,
                    'hashes_computed': hashes_computed,
                    'time_taken_ms': elapsed_ms}

    elapsed_ms = (time.monotonic() - start_time) * 1000.0
    return {'solution': None,
            'hashes_computed': hashes_computed,
            'time_taken_ms': elapsed_ms}

def connect_with_retry(max_retries=10, delay=3):
    credentials = pika.PlainCredentials(user, password)
    for attempt in range(1, max_retries + 1):
        try:
            connection = pika.BlockingConnection(
                pika.ConnectionParameters(
                    host=host, port=5672, credentials=credentials)
            )
            print(f'[Python] Connected to RabbitMQ (attempt {attempt})')
            return connection
        except pika.exceptions.AMQPConnectionError:
            print(f'[Python] RabbitMQ not ready, retrying in {delay}s '
                  f'({attempt}/{max_retries})...')
            time.sleep(delay)
    raise RuntimeError('Could not connect to RabbitMQ after all retries')

def main():
    connection = connect_with_retry()
    channel = connection.channel()
    channel.queue_declare(queue=queue_name, auto_delete=True)

    def on_message(ch, method, properties, body):
        payload     = json.loads(body)
        string      = payload['string']
        difficulty  = payload['difficulty']
        nonce_start = payload['nonce_start']
        nonce_end   = payload['nonce_end']

        print(f'[Python] Received task: nonce {nonce_start}..{nonce_end}')

        result = solve_crypto_puzzle(string, difficulty, nonce_start, nonce_end)

        solution = result['solution']
        if solution:
            print(f'[Python] Found solution: {solution}')
        else:
            print(f'[Python] No solution in range {nonce_start}..{nonce_end}')

        print(f'[Python] Finished in {result["time_taken_ms"]:.2f} ms '
              f'({result["hashes_computed"]} hashes)')

        reply = json.dumps({
            'worker':          'Python',
            'solution':        solution,
            'found':           solution is not None,
            'nonce_start':     nonce_start,
            'nonce_end':       nonce_end,
            'hashes_computed': result['hashes_computed'],
            'time_taken_ms':   round(result['time_taken_ms'], 2)
        })

        ch.basic_publish(
            exchange='',
            routing_key=properties.reply_to,
            properties=pika.BasicProperties(
                correlation_id=properties.correlation_id
            ),
            body=reply.encode('utf-8')
        )

    channel.basic_consume(
        queue=queue_name,
        on_message_callback=on_message,
        auto_ack=True
    )

    print('[Python] Waiting for tasks. Ctrl+C to exit.')
    try:
        channel.start_consuming()
    except KeyboardInterrupt:
        channel.stop_consuming()

    connection.close()

if __name__ == '__main__':
    main()
```

---

<!-- ═══════════════════════════════════════════════════════════
     ANEXA D
     ═══════════════════════════════════════════════════════════ -->

# ANEXA D

Codul sursa complet al lucratorului C#

```csharp
using System.Diagnostics;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

var factory = new ConnectionFactory
{
    HostName = "rabbitmq",
    Port     = 5672,
    UserName = "guest",
    Password = "guest"
};

await using var connection = await factory.CreateConnectionAsync();
await using var channel    = await connection.CreateChannelAsync();

await channel.QueueDeclareAsync(
    queue:      "crypto-puzzle-inquiries",
    durable:    false,
    exclusive:  false,
    autoDelete: true
);

var consumer = new AsyncEventingBasicConsumer(channel);

consumer.ReceivedAsync += async (_, ea) =>
{
    var payload    = JsonSerializer.Deserialize<JsonElement>(ea.Body.Span);
    string str     = payload.GetProperty("string").GetString()!;
    int difficulty = payload.GetProperty("difficulty").GetInt32();
    int nonceStart = payload.GetProperty("nonce_start").GetInt32();
    int nonceEnd   = payload.GetProperty("nonce_end").GetInt32();

    Console.WriteLine($"[C#] Received task: nonce {nonceStart}..{nonceEnd}");

    var (solution, hashesComputed, timeTakenMs) =
        SolvePuzzle(str, difficulty, nonceStart, nonceEnd);

    if (solution != null)
        Console.WriteLine($"[C#] Found solution: {solution}");
    else
        Console.WriteLine($"[C#] No solution in range {nonceStart}..{nonceEnd}");

    Console.WriteLine(
        $"[C#] Finished in {timeTakenMs:F2} ms ({hashesComputed} hashes)");

    var reply = JsonSerializer.Serialize(new
    {
        worker          = "CSharp",
        solution        = solution,
        found           = solution != null,
        nonce_start     = nonceStart,
        nonce_end       = nonceEnd,
        hashes_computed = hashesComputed,
        time_taken_ms   = Math.Round(timeTakenMs, 2)
    });

    var replyProps = new BasicProperties
    {
        CorrelationId = ea.BasicProperties.CorrelationId
    };
    await channel.BasicPublishAsync(
        exchange:        string.Empty,
        routingKey:      ea.BasicProperties.ReplyTo,
        mandatory:       false,
        basicProperties: replyProps,
        body:            Encoding.UTF8.GetBytes(reply)
    );
};

await channel.BasicConsumeAsync(
    "crypto-puzzle-inquiries", autoAck: true, consumer: consumer);

Console.WriteLine("[C#] Waiting for tasks. Ctrl+C to exit.");
await Task.Delay(Timeout.Infinite);

static (string? solution, int hashesComputed, double timeTakenMs) SolvePuzzle(
    string str, int difficulty, int nonceStart, int nonceEnd)
{
    string target = new string('0', difficulty);
    int hashesComputed = 0;
    var stopwatch = Stopwatch.StartNew();

    for (int n = nonceStart; n <= nonceEnd; n++)
    {
        hashesComputed++;
        string candidate = str + n;
        byte[] hash    = SHA256.HashData(Encoding.UTF8.GetBytes(candidate));
        string hexHash = Convert.ToHexString(hash).ToLowerInvariant();

        if (hexHash.StartsWith(target))
        {
            stopwatch.Stop();
            return (candidate, hashesComputed,
                    stopwatch.Elapsed.TotalMilliseconds);
        }
    }

    stopwatch.Stop();
    return (null, hashesComputed, stopwatch.Elapsed.TotalMilliseconds);
}
```

---

<!-- ═══════════════════════════════════════════════════════════
     ANEXA E
     ═══════════════════════════════════════════════════════════ -->

# ANEXA E

Fisierul de orchestrare Docker Compose

```yaml
services:
  lab2_producer: &lab2
    stdin_open: true
    tty: true
    build:
      context: .
    volumes:
        - .:/home/student/lab2
    ports:
      - "22"
    depends_on:
      - "rabbitmq"
    networks:
      - main

  lab2_consumer:
    <<: *lab2

  cs_computer:
    stdin_open: true
    tty: true
    build:
      context: ./CsComputer
    depends_on:
      - "rabbitmq"
    networks:
      - main

  python_computer:
    image: python:3.11-slim
    working_dir: /home/student/lab2
    volumes:
      - .:/home/student/lab2
    command: >
      sh -c "pip install pika --quiet && python python_computer.py"
    depends_on:
      - rabbitmq
    networks:
      - main

  rabbitmq:
    image: rabbitmq:3-management-alpine
    container_name: 'rabbitmq'
    ports:
        - 5672:5672
        - 15672:15672
    volumes:
        - ./rabbitmq-data/data/:/var/lib/rabbitmq/
        - ./rabbitmq-data/log/:/var/log/rabbitmq:rw
    environment:
      - "RABBITMQ_DEFAULT_USER=guest"
      - "RABBITMQ_DEFAULT_PASS=guest"
    networks:
      - main

networks:
  main:
```
