# WOORDLE

Het is [Wordle] maar dan Nederlands!

[Wordle]: https://www.powerlanguage.co.uk/wordle/

## Hoe draai ik dit?

Alle interactiecode is geschreven in [Elm], een functionele programmeertaal die compileert naar ECMAScript (Javascript).
Om de Elm compilatie juist te laten verlopen heb ik een Makefile gemaakt die bedoeld is om te draaien met een GNU compatible make.

De programma's die je nodig hebt zijn (en commando's voor macOS):

- make (`brew install make`, gebruik commando `gmake`)
- bash v4+ (`brew install bash`)
- jq (`brew install jq`)
- b3sum (`brew install b3sum`)
- fswatch (`brew install fswatch`, alleen nodig voor `./preview.sh`)
- python3 (`brew install python3`, alleen nodig voor `./preview.sh`)
- elm ([installatie instructies op de Elm site][elm-install])
- npm voor uglifyjs en elm-format (`brew install nodejs`)
- uglifyjs (`npm install`)

Dan kan je de site lokaal zien door `./preview.sh` uit te voeren, deze exporteert de site automatisch opnieuw bij veranderingen.
De site zal beschikbaar zijn op http://localhost:8000

Als je klaar bent om de site te publiceren kan je `make export` draaien, en zal de `app` map de productiecode bevatten.
Ik publiceer de website zelf via [Cloudflare Pages][pages], dit is de reden waarom ik de `app` map commit en push naar GitHub.
Om te zorgen dat er geen oude of development versie op pages komt te staan gebruik ik de `pre-push-hook`, deze kan je in git
installeren met `mv pre-push-hook .git/hooks/pre-push-hook`.

[Elm]: https://elm-lang.org
[elm-install]: https://guide.elm-lang.org/install/elm.html
[pages]: https://pages.cloudflare.com


## In het nieuws

- 2022-01-07 RTL Nieuws: [Student maakt Nederlandse versie hitspel Wordle: 'In één dag gemaakt'](https://www.rtlnieuws.nl/tech/artikel/5279405/wordle-woordle-woordspel-nederlands) | [archive.is](https://archive.is/gLpHq) | [archive.org](https://web.archive.org/web/20220108101306/https://www.rtlnieuws.nl/tech/artikel/5279405/wordle-woordle-woordspel-nederlands)
- 2022-01-12 AD: [Een kloon van Lingo is ineens een razendpopulaire game](https://www.ad.nl/tech/een-kloon-van-lingo-is-ineens-een-razendpopulaire-game~a66286e0/) | [archive.is](https://archive.fo/hDPro)
- 2022-01-12 nu.nl: [Student maakt Nederlandse Wordle-variant: 'Ik dacht, iemand moet dit maken'](https://www.nu.nl/tech/6177699/student-maakt-nederlandse-wordle-variant-ik-dacht-iemand-moet-dit-maken.html) | [archive.is](https://archive.is/3KJKV)
- 2022-01-12 NRC: "De computerscience-student Jelle Besseling las het en bouwde in een dag een variant in eigen taal: Woordle. Leuk natuurlijk, maar met veel minder liefde." [artikel](https://archive.is/LQwsS#selection-1451.154-1451.307)
- 2022-01-13 NOS op 3 Tech Podcast: Ik sprak over hoe het fijn is dat de code van Woordle open beschikbaar is: https://overcast.fm/+X61Ofn5GU
- 2022-01-15 In [POM](https://overcast.fm/+GlHV8gA4Y) gaat het over Wordle en ook over Woordle, gemaakt door "Jesse Besseling"... helaas
- 2022-01-31 Trouw: [De razend populaire Lingo-reïncarnatie Wo(o)rdle trekt dagelijks 35.000 Nederlandse spelers](https://www.trouw.nl/economie/de-razend-populaire-lingo-reincarnatie-wo-o-rdle-trekt-dagelijks-35-000-nederlandse-spelers~bd964fa6/) | [archive.is](https://archive.is/srSG9)


## Licentie

Je kan de code gebruiken onder de EUPL (zie LICENSE bestand).
Deze licentie is vergelijkbaar met de AGPL, dus als je Woordle online zet met aanpassingen moet je ook de broncode online zetten met een verenigbare licentie.

Ik zou het wel fijn vinden als je in je eigen versie een andere naam dan "Woordle" of "WOORDLE" gebruikt.
