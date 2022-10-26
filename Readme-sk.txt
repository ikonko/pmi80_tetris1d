################
## LZX Packer ##
################

 (c) Busy soft & hard
 http://busy.speccy.cz

 Verzia: 02d (15.09.2021)

 Licencie:
   LzxPack / LzxList ... GPLv3
   DecLzx01 ............ MIT

 LzxPack je kompresny system umoznujuci na vykonnejsich pocitacoch
 komprimovat subory do dlzky 64kB urcene hlavne pre nejaky cielovy 8 bitovy pocitac.

 Sklada sa s tychto sucasti:

  - Packer: LzxPack
  - Depacker / lister: LzxList
  - Dekompresor napisany v assembleri pre dekompresiu suboru na cielovom pocitaci

 Obvykle pouzitie:

 Vezmeme subor, skomprimujeme ho LzxPack-om, potom prenesieme na cielovy pocitac,
 kde ho nasledne prislusnou dekompresnu rutinkou dekomprimujeme na povodny tvar.

 Kompresny system je zalozeny na LZ kompressi. Pri kompresii vstupneho suboru
 v nom hlada rovnake opakujuce sa sekvencie bajtov. Ked najde sekvenciu bajtov,
 ktora sa v subore uz predtym vyskytla, neuklada do vystupneho suboru celu sekvenciu
 znovu, ale iba informaciu o tom odkial a kolko bajtov treba skopirovat pre vytvorenie
 tejto novej sekvencie pri dekompresii.

 Nasleduje priklad objasnujuci princip LZ kompresie.

    Nech povodny subor vyzera takto:

	 abc12345678def12345678ghi

    Po kompresii bude vyzerat takto:

	 abc12345678def<opakujuca sa sekvencia: dlzka=8 offset=11>ghi

 Ked sa pri dekompresii po pismenku 'f' narazi na sekvenciu, dekompresna rutinka sa
 vrati o 11 bajtov nazad (offset) a od tejto adresy na vystup skopiruje 8 bajtov (dlzka).
 Ak informacia o dlzke a offsete zaberie (dajme tomu) 2 bajty, potom sa vysledny skomprimovany
 subor skrati o 6 bajtov, pretoze povodne 8-bajtova sekvencia bola nahradena 2-bajtovou informaciou.

 System pozna viac roznych sposobov ako zakodovat informaciu o tom odkial a kolko bajtov
 treba skopirovat a vzdy dokaze vybrat ten najuspornejsi z nich.



%%%%%%%%%%%%%
%% LzxPack %%
%%%%%%%%%%%%%

 Univerzalny LZX packer pre subory do 64kB

  - vyskusa mnozinu preddefinovanych kompresii a zvoli najlepsiu
  - do volby najlepsej kompresie je mozne zahrnut aj dlzku dekompresnej rutinky
  - umoznuje uzivatelovi obmedzit mnozinu skusanych kompresii (aj na jedinu)
  - umoznuje vypis statistiky vysledkov jednotlivych kompresii pre porovnanie

 Pouzitie: LzxPack subor <volby>

 Volby:
  -s ............ Zobraz statistiku vsetkych pouzitych typov kompressie (normalne nezobrazuje)
  -a ............ Pouzi vsetky kompresie a uloz vsetky subory (normalne pouzije len najlepsiu)
  -i ............ Generovanie *.inc suboru obsahujuceho parametre pouzitej kompresie pre depaker
  -o <subor> .... Vystupny subor pre spakovane data (normalne je to vstupny subor a koncovka .lzx)
  -d <subor> .... textovy subor s dlzkami dekompresnych rutiniek pre urcenie najlepsej kompresie
  -l <limit> .... Nastavenie maximalnej velkosti slovnika (normalne je slovnik bez obmedzenia)
  -e <cislo> .... Nastavenie dodatocneho usilia pre co najlepsi kompresny pomer (bez volby je 0)
  -tnXYcNoAoB ... Urcenie pozadovanej kompresie (bez volby plati -tn a skusa vsetky kompresie)
  -trXYcNoAoB ... Znak 'r' namiesto 'n' urcuje kompresiu a dekompresiu suboru od konca

 Vsetky volby su nepovinne.
 Parameter volby moze byt uvedeny priamo pri volbe alebo oddeleny od volby medzerou.
 Jedina vynimka je volba -t kde urcenie kompresne musi nasledovat ihned, bez medzier.


Volba -s

 Zobrazi statistiku vsetkych pouzitych typov kompressie v prehladnej tabulke.
 Vyznam jednotlivych koloniek v tabulke:

   Compression ..... typ pouzitej kompresie
   NumSek .......... pocet sekvencii ktore su pri dekompresii skopirovane
   Packed .......... pocet bajtov v tychto sekvenciach ktore budu skopirovane
   NoPck ........... pocet bajtov ktore sa nepodarilo nijak skomprimovat
   Overhead ........ pocet bajtov nutnych pre ulozenie informacii o sekvenciach
   Packed length ... vysledna dlzka skomprimovaneho suboru
   With depacker ... sucet dlzky suboru a dlzky dekompresnej rutinky


Volba -a

 LzxPack normalne vyskusa vsetky pozadovane kompresie a na vysledny skomprimovany subor
 pouzije tu ktora dava najlepsie vysledky. S volbou -a vsetky kompresie nielen vyskusa,
 ale aj realne pouzije a ich vysledky ulozi - vyslednych skomprimovanych suborov teda
 bude tolko, kolko roznych kompresii sa pouzije. Ktore kompresie budu pouzite sa da
 specifikovat volbou -t (vid nizsie).


Volba -i

 Generovanie include suboru "<meno>.inc" pre depaker. Include subor obsahuje vsetky
 informacie o pouzitej kompresii potrebne pre depaker. Tento subor staci vlozit
 pomocou "include" do zdrojoveho textu depakera a depaker potom bude vediet dekomprimovat
 data skomprimovane pouzitou kompresiou. Viac info nizsie v casti o depakeri.


Volba -o <subor>

 Pre vystupny subor na ulozenie skomprimovanych dat sa normalne pouzije meno vstupneho
 suboru doplnene o identifikator kompresie -tnXYcNoAoB a koncovku lzx. Pri pouziti
 tejto volby sa data zapisu do suboru, ktoreho meno je explicitne zadane v tejto volbe.
 Pozor ! Ak zaroven pouzijete aj volbu -a (ulozenie vysledkov vsetkych kompresii),
 aj do explicitne zadaneho mena bude pridana identifikacia kompresie.


Volba -d <subor>

 Urcenie najlepsiej kompresie nie podla najmensej dlzky vyslednych skomprimovanych dat,
 ale podla suctu dlzky skomprimovanych dat a dlzky dekompresnej rutinky potrebnej
 na dekompresiu tychto skomprimovanych dat. Aby LzxPack vedel aka dlha bude rutinka,
 hned za pismenkom 'd' sa ocakava meno suboru, v ktorom su definovane dlzky rutiniek
 pre jednotlive typy kompresie. Priklad takehoto suboru je "spd0lens" prilozeny v balicku.

 Priklad pouzitia tohto suboru: LzxPack -d spd0lens <pakovany_subor>

 Pouzitie suboru umoznuje pruzne nastavovat rozne dlzky depakerov
 pre rozne platformy (napr. na 8080 mozu byt depakery dlhsie ako na Z80).


Volba -l <limit>

 Obmedzenie maximalnej velkosti slovnika pre LZ kompresiu.
 Tato volba umoznuje packeru explicitne urcit maximalnu velkost offsetov pouzivanych
 pre kopirovanie sekvencii. Vyuzitie to ma v specialnych pripadoch ked sa depakovane
 data zapisuju priamo na vystup a nie su spetne k dispozicii pre citanie. Vtedy musi
 depaker zapisovat data zaroven aj do specialneho buffera, ktoreho velkost musi byt
 aspon tolko ako najvecsi offset pouzity pri kompresii.


Volba -e <cislo>

 Pridanie dodatocneho usilia pre dosiahnutie lepsieho kompresneho pomeru.
 Tato volba umoznuje povedat pakeru aby venoval viac usilia hladaniu najlepsich sekvencii.
 Defaultna hodnota je 0, cim vyssia hodnota, tym je vyssia sanca, ze sa podari usetrit
 dalsich par bajtov v skomprimovanych datach, ale tiez tym viac casu zaberie kompresia.
 Rozumne hodnoty ktore sa vyplati skusat su do cca 32. Maximalna hodnota,
 ktora by este teoreticky mohla pomoct, je polovica celkovej dlzky dat.


Volba -tnXYcNoAoB

 Vyber typu pozadovanej kompresie. Jednotlive pismenka maju tento vyznam:

   n ... smer kompresie: n=odpredu (default), r=odzadu
   X ... vyber kompresie 0=pouzi lubovolnu, 1=BLX 2=BLC 3=ZX9 4=ZX8 5=BS2 6=BX1 7=BX2 8=BX3 9=SX1
   Y ... kodovanie offsetu 0=pouzi lubovolne, 1=OF1 2=OF2 3=OF3 4=OF4 6=OV1 7=OV2 8=OV3 9=OV4
   N ... bitova sirka offsetu pre komprimaciu samostatnych bajtov
   A ... bitova sirka  prveho offsetu pre komprimaciu sekvencii
   B ... bitova sirka druheho offsetu pre komprimaciu sekvencii

 Ak je ktorykolvek z tychto styroch parametrov nulovy, znamena to ze LzxPack moze
 pri vybere najlepsej kompresie vyskusat vsetky mozne rozumne hodnoty pre tento parameter.

   Vyber kompresie X

     1 ... BLX ... Jednoducha blokova kompresia s pakovanim samostatnych bajtov
     2 ... BLC ... Jednoducha blokova kompresia s pakovanim sekvencii dlhych 2 a viac bajtov
     3 ... ZX9 ... Kompresia podobna ako znamy ZX7 s pakovanim samostatnych bajtov
     4 ... ZX8 ... Kompresia podobna ako znamy ZX7 s lepsim kodovanim sekvencii dlhych 2 a viac bajtov
     5 ... BS2 ... Kompresia optimalizovana na velmi kratke sekvencie a dlhe bloky dat
     6 ... BX1 ... Kompresia vhodna pre samostatne bajty a znovupouzite offsety, dobra pre kratke sekvencie
     7 ... BX2 ... Kompresia vhodna pre samostatne bajty a znovupouzite offsety, kompromis BX1 a BX3
     8 ... BX3 ... Kompresia vhodna pre samostatne bajty a znovupouzite offsety, dobra pre samostatne bajty
     9 ... SX1 ... Specialna kompresia vhodna pre velmi riedke data (vela sekvencii, malo nepakovatelnych dat)

   Kodovanie offsetu Y

     1 ... OF1 ... Jeden offset pevnej bitovej sirky (A = bitova sirka offsetu)
     2 ... OF2 ... Dva offsety pevnej bitovej sirky (A = sirka prveho offsetu, B = sirka druheho)
     3 ... OF3 ... Tri offsety pevnej bitovej sirky (A = bitova sirka najkratsieho offsetu)
     4 ... OF4 ... Styri offsety roznej bitovej sirky (A = bitova sirka najkratsieho offsetu)
     6 ... OV1 ... Offset s variabilnou bitovou sirkou a bez obmedzenia rozsahu (netreba zadat A a B)
     7 ... OV2 ... Variabilny offset a jeden pevny offset (A = bitova sirka pevneho offsetu)
     8 ... OV3 ... Variabilny offset a dva pevne offsety (A = sirka prveho offsetu, B = sirka druheho)
     9 ... OV4 ... Variabilny offset a tri pevne offsety (A = bitova sirka najkratsieho offsetu)

 Ak sa pouzije "-o" a nie je pouzite "-a", meno vystupneho suboru je dane.
 Vo vsetkych ostatnych pripadoch bude mat vystupny subor koncovku ".lzx" a jeho meno bude
 rozsirene o cast specifikujucu pouzitu kompresiu v tvare "-tXYoAoB" (tak isto ako volba -t).
 Pri pouziti volby -a sa mena suborov budu lisit prave touto specifikaciou kompresie,
 aj ked bude zaroven pouzita volba "-o".


Tip pre urychlenie kompresneho procesu

 V zavislosti od typu dat, ich kompresia moze aj na vykonnych pocitacoch trvat dlhsi cas.
 Ak mate LzxPack ako sucast nejakeho "makefile" a kompilaciu robite velmi casto, kompresia
 moze cely proces vyrazne zdrzovat. V tomto pripade mozete kompresiu urychlit takto:

 Skuste, bez pouzitia volby -t, aka kompresia je najlepsia pre vase data.
 LzxPack najde najlepsiu kompresiu a vypise ktora kompresia -t je pouzita.
 Potom pridajte volbu -t pre tuto kompresiu do prikazoveho riadku pre LzxPack v makefile.
 S touto volbou LzxPack preskoci casovo narocne skusanie vsetkych kompresii, rovno pouzije
 tuto zvolenu kompresiu a cely proces bude ovela rychlejsi.

 Obcas, hlavne po vecsich zmenach vo vasich datach a pred finalou produkciou skuste znovu spustit
 LzxPack bez volby -t a skontrolujte, ci uz nie je nejaka ina kompresia lepsia pre vase nove data.


%%%%%%%%%%%%%
%% LzxList %%
%%%%%%%%%%%%%

 Univerzalny lister a dekompresor pre subory pakovane programom LzxPack

  - Automaticky zisti typ kompresie podla koncovky alebo typu kompresie v mene suboru  -tXYoAoB
  - Vypisuje tzv. "Pack model" - strukturu ako je subor skomprimovany a jeho kratku statistiku
  - Vypisuje podrobnu statistiku pakovanych dat - pocet a dlzky sekvencii a nepakovanych blokov
  - Umoznuje naraz specifikovat viac suborov pre dekompresiu alebo vypis Pack modelu

 Pouzitie: LzxList <volby> subor1 subor2 subor3...

 Volby:
  -l ............ Vypis pack modelu vstupnch suborov na standartny vystup
  -s ............ Vypis detailnej statistiky sekvencii na standartny vystup
  -d ............ dekompresia suboru, vysledny subor bude mat koncovku 'out' (alebo podla volby -e)
  -u ............ presne ako -d ale z mena vysledneho suboru odstrani typ kompresie -tXYoAoB
  -e <ext> ...... nastavenie koncovky pre vysledny subor (defaultne je nastavene 'out')
  -o <file> ..... Nastavenie mena vystupneho suboru pre zapis depakovanych dat
  -tnXYcNoAoB ... Nastavenie typu kompresie (ak sa neda zistit z mena vstupneho suboru)
  -trXYcNoAoB ... Znak 'r' namiesto 'n' urcuje kompresiu a dekompresiu suboru od konca

 V menach dekomprimovanych suborov je mozne pouzivat hviezdickovu konvenciu.

 LzxList tiez kontroluje datovu konzistenciu udajov  v skomprimovanych suboroch, hlavne
 ci sa dekompresne rutinky nebudu snazit kopirovat sekvencie z oblasti mimo platnych dat.



%%%%%%%%%%%%%%
%% DecLzx02 %%
%%%%%%%%%%%%%%

 Univerzalna LZX dekompresna rutinka (depaker) pre Z80

 Zdrojak depakera moze byt pouzity dvomi sposobmi:

  1. Samostatny sebestacny zdrojak dekompresnej rutinky
     Do predpripravenych definicii na zaciatku zdrojaku staci podoplnat
     potrebne hodnoty parametrov (adresy a udaje o pouzitej kompresii)
     a skompilovanim zdrojaku vznikne samostatny kod volatelny napr. pomocou USR z basicu.

  2. Sucast vecsieho projektu so vsetkymi potrebnymi parametrami
     urcenymi mimo samotneho zdrojaku depakera. Tento sposob umoznuje
     pouzit zdrojak depakera tak ako je, bez akejkolvek modifikacie.

 Pred pouzitim depakera je potrebne specifikovat dve sady parametrov:

  - Uzivatelske parametre "user parameters"
    Tieto parametre musia byt nastavene uzivatelom alebo v projekte ktoreho sucastou je depaker.

        ORG  ... addresa na ktorej bude rutinka depakera pracovat
      srcadd ... zaciatok zdrojovych spakovanych dat
      dstadd ... zaciatok miesta kde sa data maju depakovat
      lzxspd ... zvolena optimalizacia na dlzku kodu (hodnota 0) alebo rychlost (hodnota 1)

  - Kompresne parametre "pack parameters"
    Hodnoty pre tieto parametre generuje komprimacny program LzxPack.

    Parametre odvodene od vybranej alebo pouzitej kompresie -tnXYcNoAoB

      Label   Hodnota  Vyznam
      =====   =======  ======
      revers .. 0/1 .. Smer kompresie: 0 = odpredu -tn... / 1 = odzadu -tr...
      typcom ... X ... Typ kompresie: 1=BLX 2=BLC 3=ZX9 4=ZX8 5=BS2 6=BX1 7=BX2 8=BX3 9=SX1
      typpos ... Y ... Kodovanie offsetu: 1=OF1 2=OF2 3=OF3 4=OF4 6=OV1 7=OV2 8=OV3 9=OV4
      bytcop ... N ... bitova sirka offsetu pre komprimaciu samostatnych bajtov
      ofset1 ... A ... bitova sirka  prveho offsetu pre komprimaciu sekvencii
      ofset2 ... B ... bitova sirka druheho offsetu pre komprimaciu sekvencii

    Pridavne parametre pre informaciu a pre "data overlay check" - kontrolu
    ci zapisovane depakovane data neprepisu este neprecitane spakovane data.

      mindst ... minimalna vzdialenost medzi pakovanymi datami a cielovym miestom pre depakovanie
      maxdct ... maximalna velkost slovnika stanovena volbou -l v LzxPack-u
      deplen ... dlzka depakera (len pre info, depaker tuto hodnotu nepotrebuje)
      pcklen ... dlzka spakovanych dat
      totlen ... dlzka depakovanych dat

    Parameter "mindst" (minimal distance) je hodnota, o kolko bajtov musi byt koniec
    spakovanych dat posunuty za koncom depakovanych dat, aby v pripade prekryvania
    tychto dat dekompresia prebehla korektne. V pripade pakovania od konca ( -tr...)
    to plati pre zaciatok dat. V pripade, ak hrozi, ze data budu prepisane,
    kompilacia depakere vyhodi chybu (tzv. data overlay check).


Nastavenie uzivatelskych parametrov
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 K dispozicii su dva sposoby ako nastavit uzivatelske parametre:

  1. Priama editacia zdrojaku depakera a doplnenie potrebnych hodnot manualne

  2. Zahrnutie zdrojaku do vecsieho projektu v ktorom su uzivatelske parametre definovane.
     V tomto pripade je potrebne zakomentovat nastavenie parametrov v zdrojaku,
     alebo vo vecsom projekte definovat symbol "declzx_user_params":

       srcadd  =  ...
       dstadd  =  ...
       lzxspd  =  0 alebo 1
         DEFINE  declzx_user_params
         INCLUDE DecLzx02.asm

     Depaker na zaciatku naplna registre HL a DE adresami "srcadd" a "dstadd".
     V pripade, ze pri volani depakera adresy su uz nastavene vo volajucom programe
     (napriklad z dovodu optimalizacie vysledneho programu), staci nastavenie adries
     v depakeri zakomentovat, alebo definovat "declzx_init_addres":

         ld      hl,srcadd
         ld      de,dstadd
         DEFINE  declzx_init_addres
         INCLUDE DecLzx02.asm

     Nezabudnite, ze pre reverznu dekompresiu (revers = 1) je potrebne do registrov HL a DE
     nastavit posledny bajt spakovanych dat a posledny bajt oblasti, do ktorej sa budu depakovat.


Nastavenie kompresnych parametrov
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Tentokrat su k dispozicii tri sposoby ako nastavit tieto parametre:

  1. Priama editacia zdrojaku depakera a doplnenie potrebnych hodnot manualne

  2. Pouzitie *.inc suboru s hodnotami parametrov generovanych priamo LzxPack-om s volbou -i.
     V tomto pripade je potrebne odstranit bodkociarky na zaciatku tychto dvoch riadkov
     v zdrojaku depakera:

         ;   INCLUDE  filename.inc
         ;   DEFINE   declzx_pack_params

  3. Pri pouziti zdrojaku depakera je mozne tieto dva riadky umiestnit v ramci
     zdrojaku tohto vecsieho projektu a nie su potrebne ziadne zasahy do samotneho depakera.
     Definicia symbolu "declzx_pack_params" sposobi nacitanie parametrov z *.inc suboru.

         DEFINE  declzx_pack_params
         INCLUDE <incfile>.inc
         INCLUDE DecLzx02.asm


Optimalizacia depakera na dlzku kodu a rychlost
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Zdrojovy text DecLzx02 umoznuje skompilovat dve verzie depakera - jednu optimalizovanu
 na dlzku kodu a druhu na rychlost. Nastavenie labelu "lzxspd" urcuje, ktora verzia sa vytvori:

   lzxspd = 0 ... verzia optimalizovana na minimalnu dlzku kodu, ale pomalsia dekompresia
   lzxspd = 1 ... verzia optimalizovana na maximalnu rychlost, ale dlhsi kod


Najlepsi kompresny pomer so zahrnutim dlzky depakera
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 LzxPack vie automaticky urcit kompresiu s najlepsim kompresnym pomerom,
 pricom v pomere je zahrnuta aj dlzka depakera pre danu kompresiu.
 Aby sa toto dalo dosiahnut, LzxPack potrebuje vediet dlzku depakera.

 Dlzka kodu depakera zavisi od tychto parametrov:

  - zvolena kompresia (typcom)
  - kodovanie offsetu (typpos)
  - smer kompresie (revers)
  - nastavenie optimalizacie (lzxspd)

 Pre depaker "DecLzx02" su pre tento ucel k dispozicii v balicku tieto dva subory:

   spd0lens ... dlzky depakera optmalizovaneho na dlzku kodu (nastavenie lzxspd = 0)
   spd1lens ... dlzky depakera optmalizovaneho na rychlost   (nastavenie lzxspd = 1)

 Jeden z tychto suborov moze byt pouzity pri LzxPack vo volbe -d

   LzxPack -d spd0lens <vstupny_subor>

 V tomto pripade LzxPack vyberie kompresiu, ktora najmensi sucet
 pakovanych dat a dlzky depakera, kde depaker bude optimalizovany na dlzku kodu.


Include subor
~~~~~~~~~~~~~
 Include subor obsahuje definicie labelov ktore specifikuju pouzitu kompresiu
 potrebnu pre depaker a nejake dalsie definicie labelov ktore by mohli byt uzitocne.
 Moze byt pouzity pre definovanie vsetkych potrebnych informacii pre depaker.

 Tento subor vytvara LzxPack pri pouziti volby -i.

 Definicie pouzitej kompresie -tnXYcNoAoB

      revers = 0/1  smer kompresie: 0=odpredu -tn, 1=odzadu -tr
      typcom = X    vyber kompresie: 1=BLX 2=BLC 3=ZX9 4=ZX8 5=BS2 6=BX1 7=BX2 8=BX3 9=SX1
      typpos = Y    kodovanie offsetu: 1=OF1 2=OF2 3=OF3 4=OF4 6=OV1 7=OV2 8=OV3 9=OV4
      bytcop = N    bitova sirka offsetu pre komprimaciu samostatnych bajtov
      ofset1 = A    bitova sirka  prveho offsetu pre komprimaciu sekvencii
      ofset2 = B    bitova sirka druheho offsetu pre komprimaciu sekvencii

 Dalsie uzitocne definicie

      mindst = ?    minimalna vzdialenost medzi pakovanymi datami a cielovym miestom pre depakovanie
      maxdct = ?    maximalna velkost slovnika stanovena volbou -l v LzxPack-u
      deplen = ?    dlzka depakera
      pcklen = ?    dlzka spakovanych dat
      totlen = ?    dlzka depakovanych dat

 Dlzka depakera sa berie so suboru "spd0lens" specifikovaneho pri volbe -d.
 V pripade ze sa volba -d nepouzije, deplen bude defaultne definovane na nulu.



%%%%%%%%%%%%%%%%%%%%%%%
%% Formaty kompresii %%
%%%%%%%%%%%%%%%%%%%%%%%

 Tato cast popisuje strukturu skomprimovanych dat.


Obecny format spakovaneho suboru
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  BLX a BLC:          <blok> <blok> <blok> ... <blok> <end_mark> 
  Ostatne:     <byte> <blok> <blok> <blok> ... <blok> <end_mark> 

  Ostatne kompresie (ZX9 ZX8 BS2 BX1 BX2 BX3 SX1) vzdy zacinaju
  jednym nepakovanym bajtom nezaradenym do bloku.

  Kazdy <blok> moze obsahovat nekomprimovane data alebo jednu kopirovanu sekvenciu.

    Nekomprimovane data:   <id> <data..>
    Kopirovana sekvencia:  <id> <offset>
    Kopirovany jeden bajt: <id>

  <id> je identifikacia bloku a jej format zavisi od pouziteho typu kompresie (typcom)
       V tejto identifikacii je zakodovany aj pocet nekomprimovanych bajtov, dlzka sekvencie
       alebo offset pre komprimovane samostatnych bajtov (bytcop).

  <offset> znamena o kolko bajtov sa treba vratit aby sa odtial mohla skopirovat sekvencia.
           Format zavisi od pouziteho kodovania offsetu (typpos,ofset1,ofset2).

           Pozor, offset pre kopirovanie jedneho bajtu je vzdy sucast prislusneho <id>.
           Ak <id> znamena kopirovanie jedneho bajtu, <offset> nie je v tomto pripade pouzity.

  <end_mark> urcuje koniec pakovanych dat, depaker vtedy ukonci dekomprimaciu.
             Interne je to nejake <id> v ktorom je zapisana dlzka viac ako 65535, co sposobi
             pretecenie v 16 bitoch a depaked podla toho vie ze uz nenasleduju ziadne data.

  Tieto <id> <offset> <end_mark> su vzdy ulozene v tzv. bitstreame - samostatnom prude
  bajtov, ktore sa nacitavaju postupne po bitoch, vzdy tolko bitov kolko aktualne treba.

  Nekomprimovane <data..> nie su sucastou bitstreamu, ale su ulozene v nasledujucich celych bajtoch.



Format <id>
~~~~~~~~~~~

BLX - Jednoducha blokova kompresia s pakovanim samostatnych bajtov

  <dlzka> 1 ............ nepakovane data
  <dlzka> 0 ............ dlzka > 1 ... sekvencia aspon 2 bajty dlha
  <dlzka> 0 <offset> ... dlzka = 1 ... samostatny bajt

  Samostatny bajt je specialny pripad sekvencie dlhej 1 bajt.
  Pri kopirovani jedneho bajtu sa nepouziva standartny offset (vid kodovanie offsetu nizsie)
  ale vlastny maly offset ktory je sucastou priamo <id> polozky.
  Bitova sirka offsetu je vzdy dana parametrom "bytcop".


BLC - Jednoducha blokova kompresia s pakovanim sekvencii dlhych 2 a viac bajtov

  1 <dlzka> ...... nepakovane data
  0 <dlzka+1b> ... sekvencia aspon 2 bajty dlha

  BLC je velmi jednoducha kompresia, ktora v spojeni s Elias-Gama kodovanim offsetu
  umoznuje mat velmi kratku dekompresnu rutinku pri zachovani dobreho kompresneho pomeru.


ZX9 - Kompresia podobna ako znamy ZX7 s pakovanim samostatnych bajtov

  1 .................... jeden nekomprimovany bajt
  0 <dlzka> ............ dlzka > 1 ... sekvencia aspon 2 bajty dlha
  0 <dlzka> <offset> ... dlzka = 1 ... samostatny bajt


ZX8 - Kompresia podobna ako znamy ZX7 s lepsim kodovanim 2+ bajtov dlhych sekvencii

  1 .................... jeden nekomprimovany bajt
  0 <dlzka+1b> ......... sekvencia aspon 2 bajty dlha

  V kompresiach ZX8 a ZX9 <blok> s nekomprimovanymi datami obsahuje iba jeden jediny bajt
  a tym padom pre kazdy nekomprimovany bajt je potrebne mat samostatny blok, co znamena
  ze kazdy takyto bajt zabera vo vyslednom subore az 9 bitov.

  Kompresia ZX8 je velmi podobna tej co pouziva znamy pakovaci program ZX7, s malou zmenou v kodovani
  dlzky: pokym ZX7 dlzku inkrementuje, ZX8 pouziva modifikovany Elias-Gama format (pozri nizsie).


BS2 - Kompresia optimalizovana na velmi kratke sekvencie a dlhe bloky dat

  1 ......................... jeden nekomprimovany bajt
  01 ........................ sekvencia o dlzke 2 bajty
  001 ....................... sekvencia o dlzke 3 bajty
  0001 <dlzka+2b> ........... sekvencia o dlzke 4+ bajtov
  00001 <BAJT> <dlzka+1b> ... jeden nepakovany bajt a sekvencia so znovupouzitym offsetom
  00000 <dlzka+3b> .......... blok 10+ nepakovanych bajtov

  Kombinacia 00001 pokryva jeden nepakovany BAJT (priamo skopirovany zo vstupu na vystup)
  a ktorym nasleduje normalna sekvencia. Offset pouzity pre kopirovanie sekvencie nie je
  vzaty z nasledujucej <offset> struktury, ale je tu pouzity predchadzajuci offset.

  Nekomprinovane data az do dlzky 9 bajtov su ulozene tym istym sposobom ako pri ZX8 a ZX9,
  t.j. jeden bit na kazdy bajt. Pre udrzanie malej rezie pre velke nekomprimovane bloky je
  tu kombinacia 00000 ktora umoznuje ulozit 10 a viac nepakovanych bajtov s nizsou reziou,
  vdaka comu sa da dosiahnut lepsi kompresny pomer.

  Tieto vlastnosti - znovupouzity offset a blok viac nekomprimovanych bajtov su zahrnute
  aj vo vsetkych nasledujucich kompresiach BX1 BX2 BX3 SX1.


BX1 - Kompresia vhodna pre samostatne bajty a znovupouzite offsety, dobra pre kratke sekvencie

  1 ............................. nepakovany bajt
  01 ............................ sekvencia 2 bajty
  001 ........................... sekvencia 3 bajty
  0001 <offset> ................. skopirovany bajt
  00001 <dlzka+2b> .............. sekvencia 4+ bajtov
  000001 <BAJT> <dlzka+1b> ...... nepakovany  bajt a sekvencia so znovupouzitym offsetom
  0000001 <offset> <dlzka+1b> ... skopirovany bajt a sekvencia so znovupouzitym offsetom
  0000000 <dlzka+3b> ............ blok 12+ nepakovanych bajtov


BX2 - Kompresia vhodna pre samostatne bajty a znovupouzite offsety, kompromis BX1 a BX3

  1 ............................. nepakovany bajt
  01 ............................ sekvencia 2 bajty
  001 <offset> .................. skopirovany bajt
  0001 .......................... sekvencia 3 bajty
  00001 <dlzka+2b> .............. sekvencia 4+ bajtov
  000001 <BAJT> <dlzka+1b> ...... nepakovany  bajt a sekvencia so znovupouzitym offsetom
  0000001 <offset> <dlzka+1b> ... skopirovany bajt a sekvencia so znovupouzitym offsetom
  0000000 <dlzka+3b> ............ blok 12+ nepakovanych bajtov


BX3 - Kompresia vhodna pre samostatne bajty a znovupouzite offsety, dobra pre samostatne bajty

  1 ............................. nepakovany bajt
  01 <offset> ................... skopirovany bajt
  001 ........................... sekvencia 2 bajty
  0001 .......................... sekvencia 3 bajty
  00001 <dlzka+2b> .............. sekvencia 4+ bajtov
  000001 <BAJT> <dlzka+1b> ...... nepakovany  bajt a sekvencia so znovupouzitym offsetom
  0000001 <offset> <dlzka+1b> ... skopirovany bajt a sekvencia so znovupouzitym offsetom
  0000000 <dlzka+3b> ............ blok 12+ nepakovanych bajtov


SX1 - Specialna kompresia vhodna pre velmi riedke data (vela sekvencii, malo nepakovatelnych dat)

  1 <dlzka+1b> ................ sekvencia 2+ bajtov
  01 .......................... nepakovany bajt
  001 <offset> ................ skopirovany bajt
  0001 <BAJT> <dlzka+1b> ...... nepakovany  bajt a sekvencia so znovupouzitym offsetom
  00001 <offset> <dlzka+1b> ... skopirovany bajt a sekvencia so znovupouzitym offsetom
  00000 <dlzka+2b> ............ blok 5+ nepakovanych bajtov


  Vo vsetkych kompresiach polozka <dlzka> je vzdy kodovana vo formate Elias-Gamma:

    <N nul> 1 <N bitov hodnoty>

  To znamena, ze najprv je N nulovych bitov, potom nasleduje jednotka, a po nej nasleduje
  N bitov hodnoty. Cielova hodnota je dana bitom 1 a N bitmi hodnoty. Nejake priklady:

  Hodnota Bity
  ======= ====
    1 .... 1
    2 .... 010
    3 .... 011
    4 .... 00100
    5 .... 00101
    6 .... 00110

  Polozka <length+Xb) je kodovana v mierne modifikovanom Elias-Gamma,
  kde nasleduje este X bitov hodnoty:

    <N nul> 1 <N+X bitov hodnoty>

  Takze cela cielova hodnota je vytvorena  bit 1 + N bitov + X bitov.
  Nejake priklady pre X=2 (dva pridavne bity):

  Hodnota Bity
  ======= ====
    4 .... 100
    5 .... 101
    6 .... 110
    7 .... 111
    8 .... 01000
    9 .... 01001

  Tato modifikovana Elias-Gamma je pouzita ak treba pouzit hodnoty 2^X a viac.
  Napriklad polozka "sekvencia 4+ bajtov" potrebuje pouzivat hodnoty od 4 viac.
  Pointa je v tom ze ak vieme ze hodnota ma aspon X bitov, staci o X uvodnych nulovych bitov menej.


Format <offset>
~~~~~~~~~~~~~~~

OF1 - Jeden offset fixnej bitovej sirky

  <A> ... A bitov hodnoty offsetu. Pocet A zodpoveda parametru "ofset1".

  Bitova hodnota offsetu je zvysena o 1 a potom pouzita ako offset v rozsahu 1 .. 2^A.
  Offsety vecsie ako 2^A nie su mozne, sekvencie s vecsimi offsetmi nie je mozne ukladat.


OF2 - Dva rozne offsety fixnej bitovej sirky

  1 <A bitov> .... kratky offset o pevnej sirke A bitov, A zodpoveda parametru "ofset1"
  0 <B bitov> ...... dlhy offset o pevnej sirke B bitov, B zodpoveda parametru "ofset2"

  Rozsahy offsetov:                     Priklad pre A=3, B=5
  Kratsi offset:      1 .. 2^A               1 .. 8
  Dlhsi  offset:  2^A+1 .. 2^A+2^B           9 .. 40


OF3 - Tri offsety s rovnomerne odstupnovanymi bitovymi sirkami

  0 <A> .......... kratky offset o sirke   A bitov
  10 <2*A> ...... stredny offset o sirke 2*A bitov
  11 <3*A> ......... dlhy offset o sirke 3*A bitov

  Pocet A zodpoveda parametru "ofset1".

  Rozsahy offsetov:                                  Priklad pre A=2
   Kratky offset:              1 .. 2^A                   1 .. 4
  Stredny offset:          2^A+1 .. 2^A+2^(2*A)           5 .. 20
     Dlhy offset:  2^A+2^(2*A)+1 .. 2^A+2^(2*A)+2^(3*A)  21 .. 84


OF4 - Styri offsety s rovnomerne odstupnovanymi bitovymi sirkami

  00 <A> ...... najkratsi offset o sirke   A bitov
  01 <2*A> ....... kratsi offset o sirke 2*A bitov
  10 <3*A> ........ dlhsi offset o sirke 3*A bitov
  11 <4*A> ..... najdlhsi offset o sirke 4*A bitov

  Pocet A zodpoveda parametru "ofset1".

  Rozsahy offsetov:                                                    Priklad pre A=2
  Najkratsi offset:                      1 .. 2^A                           1 .. 4
     kratsi offset:                  2^A+1 .. 2^A+2^(2*A)                   5 .. 20
      dlhsi offset:          2^A+2^(2*A)+1 .. 2^A+2^(2*A)+2^(3*A)          21 .. 84
   Najdlhsi offset:  2^A+2^(2*A)+2^(3*A)+1 .. 2^A+2^(2*A)+2^(3*A)+2^(4*A)  85 .. 340


OV1 - Jeden offset s plne variabilnou bitovou sirkou

  <hodnota> ... hodnota offsetu kodovana Elias-Gama systemom

  Umoznuje kodovanie akehokolvek offsetu, s dorazom na usporne
  ulozenie castejsie sa vyskytujucich malych offsetov.
  Ziadny z parametrov "ofset1" a "ofset2" nie je potrebny.
  Rozsah pokrytych offsetov: 1 .. 65535


OV2 - Variabilny offset a jeden pevny offset

  0 <A> ................. kratsi offset o pevnej sirke A bitov
  1 <hodnota-Abitov> .... dlhsi offset kodovany modifikovanym Elias-Gamma systemom

  A zodpoveda parametru "ofset1"
  Kedze dlhsi offset ma vzdy minimalne A bitov, postaci modifikovane
  Elias-Gamma kodovanie ktore ma o A menej uvodnych nulovych bitov.

    <N nul> 1 <N+A bitov hodnoty>

  Rozsahy offsetov:                     Priklad pre A=4
  Kratsi offset:      1 .. 2^A               1 .. 16
  Dlhsi  offset:  2^A+1 .. 65535            17 .. 65535


OV3 - Variabilny offset a dva pevne offsety

  0 <A> ............... kratky offset o sirke A bitov, A zodpoveda parametru "ofset1"
  10 <B> ............. stredny offset o sirke B bitov, B zodpoveda parametru "ofset2"
  11 <hodnota-Bbitov> ... dlhy offset kodovany modifikovanym Elias-Gamma systemom

  Kedze dlhy offset ma vzdy minimalne B bitov, postaci modifikovane
  Elias-Gamma kodovanie ktore ma o B menej uvodnych nulovych bitov.

    <N nul> 1 <N+B bitov hodnoty>

  Rozsahy offsetov:                     Priklad pre A=3 B=5
   Kratky offset:          1 .. 2^A               1 .. 16
  Stredny offset:      2^A+1 .. 2^A+2^B           9 .. 40
     Dlhy offset:  2^A+2^B+1 .. 65535            41 .. 65535


OV4 - Variabilny offset a tri pevne offsety s rovnomerne odstupnovanymi bitovymi sirkami

  00 <A> ................. najkratsi offset o sirke   A bitov
  01 <2*A> ................... dlhsi offset o sirke 2*A bitov
  10 <3*A> .............. este dlhsi offset o sirke 3*A bitov
  11 <hodnota-3*Abitov> ... najdlhsi offset kodovany modifikovanym Elias-Gamma systemom

  A zodpoveda parametru "ofset1"

  Rozsahy offsetov:                                             Priklad pre A=2
   Shortest offset:                      1 .. 2^A                    1 .. 4
    Shorder offset:                  2^A+1 .. 2^A+2^(2*A)            5 .. 20
     Longer offset:          2^A+2^(2*A)+1 .. 2^A+2^(2*A)+2^(3*A)   21 .. 84
    Longest offset:  2^A+2^(2*A)+2^(3*A)+1 .. 65535                 85 .. 65535


%%%%%%%%%%%%%%
%% Historia %%
%%%%%%%%%%%%%%

Verzia 01
~~~~~~~~~
 - Release 07.02.2017
 - Prva oficialna verzia
 - Typy kompresii: LZM LZE ZX7 BLK BS1
 - Kodovanie offsetu: OF1 OF2 OF4 OFD
 - Automaticky vyber najlepsej kompresie
 - Ulozenie vystupu zo vsetkych kompresii:  -a
 - Statistika vsetkych pouzitych kompresii:  -s
 - Moznost zahrnut dlzku depakera do statistiky:  -d <subor>
 - Depaker optimalizovany na dlzku alebo narychlost

Verzia 02a
~~~~~~~~~~
 - Release 26.01.2021
 - Vynechanie kompresii LZM a LZE
 - Uplne nove a ucinnejsie kompresie
 - Kodovanie offsetu OFD premenovane na OV1
 - Pridane uplne nove kodovania offsetu: OF3 OV2 OV3 OV4
 - Podpora oboch typov syntaxe volieb -d<file> aj -d <file>
 - Moznost pakovania/depakovania suboru naopak od konca:  -tr...
 - Moznost specifikacie presneho mena vystupneho suboru:  -o <meno>
 - Moznost stanovit maximalny limit pre offsety (velkost slovnika): -l
 - Moznost zapisu parametrov kompresie do include suboru pre depaker:  -i
 - Moznost pridat viac vypoctoveho usilia pre mozne zlepsenie kompresneho pomeru  -e
 - Vypocet minimalneho posunu dat aby depakovane data pri depaku neprepisali spakovane
 - Vypis statistik skomprimovaneho suboru (pocty a dlzky sekvencii a nepak.blokov)

Verzia 02b
~~~~~~~~~~
 - Release 01.02.2021
 - Jazykova korektura vypisovaneho helpu v prikazovom riadku

Verzia 02c
~~~~~~~~~~
 - Release 30.08.2021
 - LzxList: Korekcia statistiky nepakovanych blokov
 - LzxPack: Pridanie "deplen" dlzky depakera do include suboru

Verzia 02d
~~~~~~~~~~
 - Release 15.09.2021
 - Pridane depackery DecLzx02 (okrem Z80) aj pre 8080 a 6502
 - Novy parameter "declzx_init_addres" v depakeri pre vynechanie nastaveni HL and DE na zaciatku


%%%%%%%%%%%%%%%%%
%% Podakovanie %%
%%%%%%%%%%%%%%%%%

 Velke DAKUJEM za inspiraciu a pomoc pri tvorbe LzxPack patri tymto subjektom:

 - RM-TEAM za kompresnu utilitku QUIDO
 - Einar Saukas za kompresny program ZX7
 - Emmanuel Marty za kompresny program Apultra
 - Ped7g + baze + mborik + Loki za tipy, napady a korekcie
 - Loki za depacker DecLzx02 pre 6502
 