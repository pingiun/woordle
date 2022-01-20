
function loadStorage() {
  const gameState = JSON.parse(localStorage.getItem("gameState6"));
  const statistics = JSON.parse(localStorage.getItem("statistics6"));
  const darkTheme = JSON.parse(localStorage.getItem("darkTheme"));
  const colorBlindTheme = JSON.parse(localStorage.getItem("colorBlindTheme"));
  const largeKeyboard = JSON.parse(localStorage.getItem("largeKeyboard"));
  return { "gameState": gameState, "statistics": statistics, "darkTheme": darkTheme, "colorBlindTheme": colorBlindTheme, "largeKeyboard": largeKeyboard }
}
// https://stackoverflow.com/a/11252167
function treatAsUTC(date) {
  var result = new Date(date);
  result.setMinutes(result.getMinutes() - result.getTimezoneOffset());
  return result;
}
function daysBetween(startDate, endDate) {
  var millisecondsPerDay = 24 * 60 * 60 * 1000;
  return (treatAsUTC(endDate) - treatAsUTC(startDate)) / millisecondsPerDay;
}
const start_date = new Date(2022, 0, 10);
const offset = Math.floor(daysBetween(start_date, new Date()));
const todays_word = puzzle_words[offset % puzzle_words.length];
var app = Elm.Main.init({
  node: document.getElementById('app'),
  flags: {
    windowSize: { width: window.innerWidth, height: window.innerHeight },
    localStorage: loadStorage(),
    allWords: all_words,
    todaysWord: todays_word,
    offset: offset,
    wordSize: 6,
    startDarkMode: window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches
  }
});
app.ports.save.subscribe(function (value) {
  for (const [key, val] of Object.entries(JSON.parse(value))) {
    localStorage.setItem(key, JSON.stringify(val));
  }
});
app.ports.share.subscribe(function (sharestring) {
  try {
    if (/Mobi/i.test(navigator.userAgent) && !/Android/i.test(navigator.userAgent) && navigator.share) {
      navigator.share({
        text: sharestring
      });
    } else {
      var t = document.createElement('textarea');
      t.textContent = sharestring;
      document.body.appendChild(t);
      t.select();
      document.execCommand('copy');
      document.body.removeChild(t)
      app.ports.makeToast.send("Score gekopieerd");
    }
  } catch {
    app.ports.makeToast.send("Kon niet delen");
  }
});