# WOORDLE

Het is [Wordle] maar dan Nederlands!

[Wordle]: https://www.powerlanguage.co.uk/wordle/

## Hoe draai ik dit?

Alle interactiecode is geschreven in [Elm], een functionele programmeertaal die compileert naar ECMAScript (Javascript).
De site wordt gebouwd met [Vite]; de Elm compiler wordt via npm geïnstalleerd, dus je hebt alleen Node.js (≥ 20.11) nodig:

```sh
npm install
npm run dev      # dev server met live reload op http://localhost:5173
npm run build    # productie-build naar dist/
npm run preview  # productie-build lokaal bekijken
```

De Engelse variant van de Elm-app wordt gegenereerd door `scripts/gen-en.js` (draait automatisch voor `dev` en `build`):
die zet de `{- English -}`-marker in `src/Main.elm` om en schrijft het resultaat naar `src-en/Main.elm`.
Pas je `src/Main.elm` aan terwijl de dev server draait, herstart die dan (of draai `npm run gen:en`) om ook de Engelse pagina's bij te werken.

De site wordt gepubliceerd via [Netlify], die draait `npm run build` en publiceert de `dist/` map (zie `netlify.toml`).

[Elm]: https://elm-lang.org
[Vite]: https://vite.dev
[Netlify]: https://www.netlify.com


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
