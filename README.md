# vita
Projekt CDT
===========
Constant Database Table = jedna tabulka konstantní (neměnitelné) databáze
Databáze o několika relačně propojených databázových tabulkách uložených v souborech.
Cílené na rychlou práci většinou přímo v paměti.
Omezení na desítky úzkých sloupců, statisíce řádků.

Poznámky k použití
------------------
 - Pro uložení memo-polí nebo rozsáhlých doprovodných textů použijte své vlastní soubory,
   do cdt-záznamu uložte pouze např. seek do svého souboru.
   Pravděpodobně vznikne volně navazující projekt pro uložení rozsáhlých hypertextů.
 - Pro uložení malých doprovodných textů (vysvětlivek, částí "sql" apod. použijte např.
   ini-soubory apod.
 - Vstupní data mohou být v csv (vysoká kompatibilita, snadný přenos a zálohování - git)
 - Vstupní data mohou být v seq-souborech (pevná šířka polí, popis v souboru .seh)
   Volně navazující projekt seqJobs (mainly reSeq)

Krátké shrnutí
--------------
 - konstantní databáze (do kterých uživatel nemá zasahovat)
 - minimalistické uložení (malé na disku i v paměti)
 - uložené co tabulka, to jeden soubor (snadný výběr, co se načte)
 - rychlé použití (ideálně načtení celého souboru do paměti najednou)
 - možnost data uzamknout a hlídat jejich použití
 - ukládání, třídění/hledání nestandardních číselníků (i binárních)
 - případně zvláštní třídění a hledání (case insensitiv, bez hacku)
 - sloupce, kterým rozumí jen třetí strany (link na code-decode)
 - zhoršené podmínky přenosu (lze kontrolovat vnitřní malé crc)
Limitace:
 - chceme uvnitř držet jednobytové kódování textů (případně UTF-8)
 - není možné ukládat do buňky větší data
   (ta lze uložit mimo a sem dát např. adresu do jiného souboru)
 - poměrně málo datových typů

Programovací jazyk
------------------
Vývoj je souběžně v C a pas:
 - záměrně bez použití objektů a tříd
 - záměrně v jednodušších dialektech
 - nechceme od začátku zanášet kód nadbytkem přepínačů
   (lze je kdykoli přidat podle potřeby)
Z takto okleštěných jazyků bude snazší případný přenos do jiných

Licence (like BSD)
------------------
Pomozte nám, prosím, především opravovat chyby.
Pište náměty na vylepšení.
Až budete spokojeni, klidně projekt převezměte.
Lze bez problémů zalinkovat přímo toto repozitory do uzavřených projektů.


Popis řešení
============
1.
Soubor lze načíst celý najednou, nebo jeho části do paměti.
Předpokládá se vždy načtení celého jádra tabulky (dále main).
2.
Soubor má hned po minimalistické hlavičce seznam dalších bloků.
3.
Prvním dalším blokem bývá popis sloupců.
4.
Volitelným blokem je popis uzamčení na uživatele/stroj.
5.
Blok main nese v pevné délce věty všechny datové záznamy za sebou.
Položky číselné mohou být uloženy v BCD, binárně (přímo / pozpátku)
na různý počet bajtů. Lze přidat další šikovná pakování.
Pro tříditelné se ukládají bajty vždy od nejvýznamnějšího (endian).
6.
Obsahy všech sloupců, které jsou delší / opakující se / proměnné délky
jsou uloženy zvlášť - každý sloupec ve svém bloku. V main je uložena
adresa (relativní) začátku obsahu buňky v jejím bloku.
7.
Tatáž adresa se používá pro případný pomocný hledací blok (cesky incase).
(V případě kratší délky (originál v utf-8) je zbytek vyplněn 0x00.)
Je případně možné dodefinovat jiná třídící/hledací hlediska.
8.
Pro často používaná hledání jsou v jiných blocích uloženy pořadníky.
(Hledá se půlením nad pořadníkem, který odkazuje na větu v main,
která může odkazovat na obsah buňky v jiném bloku.)
9.
Lze mírně pomaleji hledat slova v buňkách / uvnitř slov v buňkách
(prohledáním bloku dané buňky, nalezením nejbližšího začátku v main).
Pro malá množství různých obsahů buněk lze dokonce hledat začátek
obsahu buňky půlením či přímým hledáním v hledacím bloku (cesky incase).
Uživateli lze zobrazit původní obsah ze stejné adresy v původním bloku.
10.
Je možné vytvořit blok začátků skupin záznamů, pokud se databáze podle
obsahu některého sloupce dělí na malé množství zajímavých velkých částí
(pro shodný obsah buňky nebo jen zadaný začátek obsahu buňky).
11.
Bloky začínají na násobcích 4, datové bloky končí alespoň dvěma 0x00.

Schéma uložení
--------------
 Hlavička (pevná velikost 16)
 Seznam bloků (početBloků x 12), neobsahuje Hlavičku a sám sebe
 Popis sloupců (početSloupců x 8)
 Podpis dat (lze si předefinovat)
 Main (početZáznamů x délkaPakovaného)
 Pořadník #1 (např. podle číselného klíčového sloupce #1)
 Vyjmuté texty #1 (např. od sloupce #3)
 ceske texty #1 (kopie vyjmutých textů)
 Pořadník #2 (např. právě pro sloupec #3)
 Vyjmuté texty #2 (např. od sloupce #5)
 Vyjmuté texty #3 (např. od sloupce #6)
 Pořadník #3 (pro sloupec #6 - nemusí být ceska kopie, pokud není potřeba)
 ...


Tvorba souborů
==============
Lze na vstupu použít běžný csv soubor.
Raději používáme vlastní soubory seq - řádky s pevnou délkou.
(Popis sloupců je uložen v souboru seh.) Snadnější předpříprava dat.
Binární data jsou v csv a seq uložena jako čísla nebo úsporněji v Y64.
Datum je uložen vždy v pořadí rok-měsíc-den - kvůli třídění.
Pro úsporu může být uložen yymd, v upraveném "hex" - řada až do V
(případně poslední den v měsíci jako Z).
