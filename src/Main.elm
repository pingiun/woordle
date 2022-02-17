port module Main exposing (..)

import Browser
import Browser.Events exposing (onKeyDown, onResize)
import Element
    exposing
        ( DeviceClass(..)
        , Element
        , alignBottom
        , alignLeft
        , alignRight
        , centerX
        , centerY
        , classifyDevice
        , column
        , el
        , fill
        , fromRgb
        , height
        , inFront
        , maximum
        , newTabLink
        , padding
        , paddingEach
        , paddingXY
        , paragraph
        , px
        , rgb255
        , rgba255
        , row
        , scrollbars
        , spaceEvenly
        , spacing
        , toRgb
        , width
        )
import Element.Background as Background
import Element.Border as Border exposing (rounded)
import Element.Events exposing (onClick)
import Element.Font as Font
import Element.Input exposing (button)
import Html
import Json.Decode as D
import Json.Encode as E
import Set exposing (Set)
import Task exposing (perform)
import Time exposing (Month(..), Posix, Zone, every, here, millisToPosix, posixToMillis, utc)


type alias Model =
    { board : List BoardWord
    , correctWord : List Char
    , keyboard : Keyboard
    , window : { width : Int, height : Int }
    , allWords : Set String
    , playState : PlayState
    , lastPlayed : Maybe Posix
    , lastCompleted : Maybe Posix
    , currentTime : Posix
    , currentZone : Zone
    , toasts : List Toast
    , showEndScreen : Bool
    , offset : Int
    , showHelp : Bool
    , showSettings : Bool
    , useDarkMode : Bool
    , useContrastMode : Bool
    , useLargeKeyboard : Bool
    , statistics : Statistics
    , wordSize : Int
    }


type alias BoardWord =
    List CharGuess


type CharGuess
    = New Char
    | Correct Char
    | Place Char
    | Wrong Char


type alias Keyboard =
    ( BoardWord, BoardWord, BoardWord )


type PlayState
    = Playing
    | Won
    | Lost


type alias Toast =
    { content : Element Msg, removeAt : Posix }


type alias Statistics =
    { guesses : Guesses
    , currentStreak : Int
    , maxStreak : Int
    , gamesPlayed : Int
    , gamesWon : Int
    }


type alias Guesses =
    { g1 : Int
    , g2 : Int
    , g3 : Int
    , g4 : Int
    , g5 : Int
    , g6 : Int
    , fail : Int
    }


type Msg
    = TouchKey Char
    | Keyboard Key
    | NewSize Int Int
    | NewTime Posix
    | NewZone Zone
    | Share
    | AddToast Toast
    | DismissEndScreen
    | ShowHelp Bool
    | ShowSettings Bool
    | SetDarkMode Bool
    | SetContrastMode Bool
    | SetLargeKeyboard Bool
    | None


type Key
    = Character Char
    | Control String


type alias InitialData =
    { windowSize : { width : Int, height : Int }
    , localStorage : D.Value
    , allWords : List String
    , todaysWord : String
    , offset : Int
    , wordSize : Int
    , startDarkMode : Bool
    }


init : InitialData -> ( Model, Cmd Msg )
init flags =
    let
        model =
            modelFromJson
                flags.localStorage
                flags.wordSize
                flags.todaysWord
                flags.startDarkMode
    in
    ( { model | window = flags.windowSize, allWords = Set.fromList flags.allWords, offset = flags.offset, wordSize = flags.wordSize }
    , perform NewZone here
    )


port save : String -> Cmd msg


port share : String -> Cmd msg


port makeToast : (String -> msg) -> Sub msg


view : Model -> Html.Html Msg
view model =
    Element.layout
        [ Background.color (pageBackground model)
        , Font.color (textColor model)
        , height (px model.window.height)
        , width (px model.window.width)
        , inFront (maybeViewHelp model)
        , inFront (maybeViewSettings model)
        , inFront (maybeViewEndScreen model)
        , inFront (viewToasts model)
        ]
        (viewBody model)


maybeViewHelp : Model -> Element Msg
maybeViewHelp model =
    if model.showHelp then
        viewHelp model

    else
        Element.none


exampleWords : Model -> ( BoardWord, BoardWord, BoardWord )
exampleWords model =
    case model.wordSize of
        5 ->
            ( [ Correct 'W', New 'O', New 'O', New 'R', New 'D' ]
            , [ New 'P', Place 'U', New 'P', New 'I', New 'L' ]
            , [ New 'T', New 'R', New 'O', Wrong 'E', New 'P' ]
            )

        _ ->
            ( [ Correct 'W', New 'O', New 'R', New 'D', New 'L', New 'E' ]
            , case language of
                English ->
                    [ New 'B', Place 'U', New 'R', New 'D', New 'E', New 'N' ]

                Dutch ->
                    [ New 'S', Place 'U', New 'R', New 'F', New 'E', New 'N' ]
            , case language of
                English ->
                    [ New 'A', New 'N', New 'S', New 'W', Wrong 'E', New 'R' ]

                Dutch ->
                    [ New 'C', New 'H', New 'I', New 'Q', New 'U', Wrong 'E' ]
            )


viewHelp : Model -> Element Msg
viewHelp model =
    let
        ( w, h ) =
            calcWinScreenWH model.window

        widthLeft =
            w - (2 * modalPadding model)

        ( first, second, third ) =
            exampleWords model
    in
    el [ Background.color darkened_bg, onClick (ShowHelp False), centerX, centerY, width fill, height fill ]
        (column
            [ Background.color (pageBackground model)
            , width (px w)
            , height (px h)
            , centerX
            , centerY
            , padding (modalPadding model)
            , Border.rounded 10
            , onClick None
            , inFront (el [ alignRight, padding 20 ] (button [] { onPress = Just (ShowHelp False), label = text "✕" }))
            ]
            [ column [ centerX, centerY, spacing 10, scrollbars, width fill, height fill ]
                [ el [ Font.bold, centerX ] (text "INSTRUCTIES")
                , el [ height (px 10) ] Element.none
                , paragraph [] [ text "Gok het ", el [ Font.bold ] (text (titel model)), text " in 6 keer." ]
                , paragraph [] [ text "Na elke gok zullen de kleuren van de vakjes aangeven hoe dichtbij je was." ]
                , el [ height (px 10) ] Element.none
                , el [ Border.width 1, width fill ] Element.none
                , el [ height (px 10) ] Element.none
                , el [ height (px (rowHeight model widthLeft)), width (px widthLeft) ] (viewBoardRow model (Just first))
                , paragraph [] [ text "De letter ", el [ Font.bold ] (text "W"), text " zit op de juiste plek in het woord." ]
                , el [ height (px (rowHeight model widthLeft)), width (px widthLeft) ] (viewBoardRow model (Just second))
                , paragraph [] [ text "De letter ", el [ Font.bold ] (text "U"), text " zit in het woord maar op een andere plek." ]
                , el [ height (px (rowHeight model widthLeft)), width (px widthLeft) ] (viewBoardRow model (Just third))
                , paragraph [] [ text "De letter ", el [ Font.bold ] (text "E"), text " zit helemaal niet in het woord." ]
                , el [ height (px 10) ] Element.none
                , el [ Border.width 1, width fill ] Element.none
                , el [ height (px 10) ] Element.none
                , paragraph [] [ text "Elke dag is er een nieuwe ", el [ Font.bold ] (text (titel model)), text " beschikbaar!" ]
                ]
            ]
        )


viewBody : Model -> Element Msg
viewBody model =
    column [ centerX, height fill, width (fill |> maximum 600), spacing 20 ]
        [ viewHeader model
        , viewBoard model
        , viewKeyboard model
        ]


viewHeader : Model -> Element Msg
viewHeader model =
    row
        [ height (px 60)
        , padding 15
        , width fill
        , Border.widthEach { bottom = 2, left = 0, right = 0, top = 0 }
        ]
        [ helpButton
        , el [ centerY, centerX ] (text (titel model))
        , settingsButton
        ]


helpButton : Element Msg
helpButton =
    button
        [ alignLeft
        , padding 10
        , Border.width 2
        , rounded 100
        , width (px 30)
        , height (px 30)
        , inFront (el [ width (px 30), height (px 30) ] (el [ centerX, centerY, width (px 15) ] (text "?")))
        ]
        { onPress = Just (ShowHelp True), label = Element.none }


settingsButton : Element Msg
settingsButton =
    button
        [ alignLeft
        , padding 10
        , Border.width 2
        , rounded 100
        , width (px 30)
        , height (px 30)
        , inFront (el [ width (px 30), height (px 30) ] (el [ centerX, centerY, paddingEach { bottom = 10, left = 0, top = 0, right = 3 } ] (text "...")))
        ]
        { onPress = Just (ShowSettings True), label = Element.none }


viewBoard : Model -> Element msg
viewBoard model =
    let
        ( w, h ) =
            calcBoardWH model model.window
    in
    column
        [ spacing 4
        , centerX
        , width (px w)
        , height (px h)
        , Font.size (floor (toFloat h / 7.5))
        ]
        (List.map (viewBoardRow model) (List.take 6 (fillList model.board 6)))


viewBoardRow : Model -> Maybe BoardWord -> Element msg
viewBoardRow model wordrow =
    let
        row_ =
            case wordrow of
                Nothing ->
                    []

                Just x ->
                    x
    in
    row [ spacing 4, width fill, height fill ] (List.map (viewBoardSquare model) (fillList row_ model.wordSize))


viewBoardSquare : Model -> Maybe CharGuess -> Element msg
viewBoardSquare model elem =
    let
        ( bgColor, borderColor, c ) =
            case elem of
                Nothing ->
                    ( Background.color (pageBackground model), darkgrey, Element.none )

                Just (New x) ->
                    ( Background.color (pageBackground model), lightgrey, text (charToString (Char.toUpper x)) )

                Just (Correct x) ->
                    ( Background.color (correctColor model), correctColor model, text (charToString (Char.toUpper x)) )

                Just (Place x) ->
                    ( Background.color (placeColor model), placeColor model, text (charToString (Char.toUpper x)) )

                Just (Wrong x) ->
                    ( Background.color (wrongColor model), wrongColor model, text (charToString (Char.toUpper x)) )

        fgColor =
            case elem of
                Just (New _) ->
                    newVakjeTextColor model

                _ ->
                    vakjeTextColor model
    in
    el [ width fill, height fill, Border.width 3, Border.solid, Border.color borderColor, bgColor, Font.color fgColor ]
        (el [ centerX, centerY ]
            c
        )


viewKeyboard : Model -> Element Msg
viewKeyboard model =
    let
        ( first, second, third ) =
            model.keyboard

        maxHeight =
            0.3 * toFloat model.window.height |> min 260 |> round
    in
    column [ width fill, height (fill |> maximum maxHeight), alignBottom, spacing 10, paddingXY 5 5 ]
        [ row [ width fill, height fill, spacing 5, centerX ] (first |> List.map (viewKey model))
        , row [ width fill, height fill, spacing 5, centerX ] (second |> List.map (viewKey model))
        , row [ width fill, height fill, spacing 5, centerX ]
            (el [ width (fill |> maximum 50) ]
                Element.none
                :: (third |> List.map (viewKey model))
                ++ [ el [ width (fill |> maximum 20) ] Element.none ]
            )
        ]


viewKey : Model -> CharGuess -> Element Msg
viewKey model letter =
    let
        ( bgColor, c ) =
            case letter of
                New x ->
                    ( keyColor model, x )

                Correct x ->
                    ( correctColor model, x )

                Place x ->
                    ( placeColor model, x )

                Wrong x ->
                    ( wrongColor model, x )

        ( buttontext, bwidth, fontSize ) =
            case ( c, model.useLargeKeyboard ) of
                ( '↵', False ) ->
                    ( text "ENTER", 85, 14 )

                ( '↵', True ) ->
                    ( text "ENTER"
                    , 85
                    , case (classifyDevice model.window).class of
                        Phone ->
                            14

                        _ ->
                            20
                    )

                ( x, False ) ->
                    ( text (charToString (Char.toLower x)), 55, 18 )

                ( x, True ) ->
                    ( text (charToString (Char.toUpper x))
                    , 55
                    , case (classifyDevice model.window).class of
                        Phone ->
                            22

                        _ ->
                            30
                    )
    in
    button [ Background.color bgColor, Element.mouseDown [ Background.color (darken bgColor) ], width (fill |> maximum bwidth), height fill, rounded 10, Font.size fontSize ]
        { onPress = Just (TouchKey (Char.toLower c)), label = el [ centerX, centerY ] buttontext }


boardWordToJsonString : Maybe BoardWord -> E.Value
boardWordToJsonString bw_ =
    case bw_ of
        Just bw ->
            List.map extractChar bw |> String.fromList |> E.string

        Nothing ->
            E.string ""


colorToJson : CharGuess -> E.Value
colorToJson color =
    case color of
        New _ ->
            E.null

        Correct _ ->
            E.string "correct"

        Place _ ->
            E.string "present"

        Wrong _ ->
            E.string "absent"


colorsToJson : Model -> Maybe BoardWord -> E.Value
colorsToJson model bw_ =
    case ( bw_, bw_ |> Maybe.map List.length |> Maybe.withDefault 0 ) of
        ( Just bw, l ) ->
            if l == model.wordSize then
                E.list colorToJson bw

            else
                E.null

        ( _, _ ) ->
            E.null


playStateToJson : PlayState -> E.Value
playStateToJson state =
    E.string <|
        case state of
            Playing ->
                "IN_PROGRESS"

            Won ->
                "WIN"

            Lost ->
                "FAIL"


guessesToJson : Guesses -> E.Value
guessesToJson guess =
    E.object
        [ ( "1", E.int guess.g1 )
        , ( "2", E.int guess.g2 )
        , ( "3", E.int guess.g3 )
        , ( "4", E.int guess.g4 )
        , ( "5", E.int guess.g5 )
        , ( "6", E.int guess.g6 )
        , ( "fail", E.int guess.fail )
        ]


extraStats : Statistics -> { winPercentage : Int, averageGuesses : Int }
extraStats stats =
    { winPercentage = (toFloat stats.gamesWon / toFloat stats.gamesPlayed) * 100 |> round
    , averageGuesses = toFloat (stats.guesses.g1 + stats.guesses.g2 + stats.guesses.g3 + stats.guesses.g4 + stats.guesses.g5 + stats.guesses.g6) / 6 |> round
    }


statisticsToJson : Statistics -> E.Value
statisticsToJson stats =
    let
        { winPercentage, averageGuesses } =
            extraStats stats
    in
    E.object
        [ ( "currentStreak", E.int stats.currentStreak )
        , ( "maxStreak", E.int stats.maxStreak )
        , ( "gamesPlayed", E.int stats.gamesPlayed )
        , ( "gamesWon", E.int stats.gamesWon )
        , ( "guesses", guessesToJson stats.guesses )
        , ( "winPercentage", E.int winPercentage )
        , ( "averageGuesses", E.int averageGuesses )
        ]


storageSuffix : Model -> String
storageSuffix model =
    case model.wordSize of
        5 ->
            case language of
                English ->
                    "-en"

                Dutch ->
                    ""

        l ->
            let
                suffix =
                    String.fromInt l
            in
            case language of
                English ->
                    suffix ++ "-en"

                Dutch ->
                    suffix


modelToJson : Model -> String
modelToJson model =
    E.object
        [ ( "gameState" ++ storageSuffix model
          , E.object
                [ ( "boardState", E.list boardWordToJsonString (fillList model.board 6) )
                , ( "evaluations", E.list (colorsToJson model) (fillList model.board 6) )
                , ( "rowIndex", E.int (List.length model.board - 1) )
                , ( "solution", E.string (String.fromList model.correctWord) )
                , ( "restoringFromLocalStorage", E.null )
                , ( "gameStatus", playStateToJson model.playState )
                , ( "hardMode", E.bool False )
                ]
          )
        , ( "darkTheme", E.bool model.useDarkMode )
        , ( "colorBlindTheme", E.bool model.useContrastMode )
        , ( "largeKeyboard", E.bool model.useLargeKeyboard )
        , ( "statistics" ++ storageSuffix model, statisticsToJson model.statistics )
        ]
        |> E.encode 0


getBoard : D.Decoder ( List String, List (Maybe (List String)) )
getBoard =
    D.map2 Tuple.pair getBoardState getEvaluations


getBoardState : D.Decoder (List String)
getBoardState =
    D.field "boardState" (D.list D.string)


getEvaluations : D.Decoder (List (Maybe (List String)))
getEvaluations =
    D.field "evaluations" (D.list (D.nullable (D.list D.string)))


getSolution : D.Decoder String
getSolution =
    D.field "solution" D.string


createWord : String -> Maybe (List String) -> Maybe BoardWord
createWord word =
    Maybe.map
        (\status ->
            List.map2
                (\c color ->
                    case color of
                        "correct" ->
                            Correct c

                        "present" ->
                            Place c

                        "absent" ->
                            Wrong c

                        _ ->
                            New c
                )
                (String.toList word)
                status
        )


getGameStatus : D.Decoder PlayState
getGameStatus =
    D.map
        (\str ->
            case str of
                "WIN" ->
                    Won

                "FAIL" ->
                    Lost

                _ ->
                    Playing
        )
        (D.field "gameStatus" D.string)


getLastPlayed : D.Decoder (Maybe Posix)
getLastPlayed =
    D.maybe (D.map millisToPosix (D.field "lastPlayedTs" D.int))


getLastCompleted : D.Decoder (Maybe Posix)
getLastCompleted =
    D.maybe (D.map millisToPosix (D.field "lastCompletedTs" D.int))


getGuesses : D.Decoder Guesses
getGuesses =
    D.field "guesses"
        (D.map7
            (\g1 g2 g3 g4 g5 g6 fail ->
                { g1 = g1
                , g2 = g2
                , g3 = g3
                , g4 = g4
                , g5 = g5
                , g6 = g6
                , fail = fail
                }
            )
            (D.field "1" D.int)
            (D.field "2" D.int)
            (D.field "3" D.int)
            (D.field "4" D.int)
            (D.field "5" D.int)
            (D.field "6" D.int)
            (D.field "fail" D.int)
        )


getStatistics : D.Decoder Statistics
getStatistics =
    D.map5
        (\guesses currentStreak maxStreak gamesPlayed gamesWon ->
            { guesses = guesses
            , currentStreak = currentStreak
            , maxStreak = maxStreak
            , gamesPlayed = gamesPlayed
            , gamesWon = gamesWon
            }
        )
        getGuesses
        (D.field "currentStreak" D.int)
        (D.field "maxStreak" D.int)
        (D.field "gamesPlayed" D.int)
        (D.field "gamesWon" D.int)


type alias UISettings =
    { darkTheme : Maybe Bool, colorBlindTheme : Maybe Bool, largeKeyboard : Maybe Bool }


getUISettings : D.Decoder UISettings
getUISettings =
    D.map3 UISettings
        (D.maybe (D.field "darkTheme" D.bool))
        (D.maybe (D.field "colorBlindTheme" D.bool))
        (D.maybe (D.field "largeKeyboard" D.bool))


modelDecoder : Int -> String -> D.Decoder Model
modelDecoder wordSize todaysWord =
    D.map7
        (\( bs, e ) s state lastPlayed lastCompleted uiSettings statistics ->
            let
                ( startBoard, playState ) =
                    if s == todaysWord then
                        ( List.filterMap identity (List.map2 createWord bs e), state )

                    else
                        ( [], Playing )
            in
            -- Debug.log "decoded"
            { board = startBoard ++ [ [] ]
            , correctWord = String.toList todaysWord
            , keyboard = List.foldr (\word keys -> updateKeyboard word keys) startKeyboard startBoard
            , window = { width = 0, height = 0 }
            , allWords = Set.empty
            , playState = playState
            , lastPlayed = lastPlayed
            , lastCompleted = lastCompleted
            , currentTime = millisToPosix 0
            , currentZone = utc
            , toasts = []
            , showEndScreen = True
            , offset = 0
            , showHelp = False
            , showSettings = False
            , useDarkMode = uiSettings.darkTheme |> Maybe.withDefault False
            , useContrastMode = uiSettings.colorBlindTheme |> Maybe.withDefault False
            , useLargeKeyboard = uiSettings.largeKeyboard |> Maybe.withDefault False
            , statistics = statistics |> Maybe.withDefault emptyStatistics
            , wordSize = 5
            }
        )
        (D.field "gameState" getBoard)
        (D.field "gameState" getSolution)
        (D.field "gameState" getGameStatus)
        (D.field "gameState" getLastPlayed)
        (D.field "gameState" getLastCompleted)
        getUISettings
        (D.maybe (D.field "statistics" getStatistics))


emptyStatistics : Statistics
emptyStatistics =
    { guesses =
        { g1 = 0
        , g2 = 0
        , g3 = 0
        , g4 = 0
        , g5 = 0
        , g6 = 0
        , fail = 0
        }
    , currentStreak = 0
    , maxStreak = 0
    , gamesPlayed = 0
    , gamesWon = 0
    }


startKeyboard : Keyboard
startKeyboard =
    ( List.map New (String.toList "qwertyuiop")
    , List.map New (String.toList "asdfghjkl⌫")
    , List.map New (String.toList "zxcvbnm↵")
    )


modelFromJson : D.Value -> Int -> String -> Bool -> Model
modelFromJson inp wordSize todaysWord startDarkMode =
    case D.decodeValue (modelDecoder wordSize todaysWord) inp of
        Ok model ->
            model

        Err e ->
            -- Debug.log (D.errorToString e)
            { board = [ [] ]
            , correctWord = String.toList todaysWord
            , keyboard = startKeyboard
            , window = { width = 0, height = 0 }
            , allWords = Set.empty
            , playState = Playing
            , lastPlayed = Nothing
            , lastCompleted = Nothing
            , currentTime = millisToPosix 0
            , currentZone = utc
            , toasts = []
            , showEndScreen = True
            , offset = 0
            , showHelp = True
            , showSettings = False
            , useDarkMode = startDarkMode
            , useContrastMode = False
            , useLargeKeyboard = False
            , statistics = emptyStatistics
            , wordSize = 5
            }


inTwoSeconds : Posix -> Posix
inTwoSeconds time =
    posixToMillis time + 2000 |> millisToPosix


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch <|
        [ onKeyDown keyDecoder
        , onResize NewSize
        , every 100 NewTime
        , makeToast (\msg -> AddToast { content = text msg, removeAt = inTwoSeconds model.currentTime })
        ]


keyDecoder : D.Decoder Msg
keyDecoder =
    D.map toKey (D.field "key" D.string)


toKey : String -> Msg
toKey string =
    case String.uncons string of
        Just ( char, "" ) ->
            Keyboard (Character char)

        _ ->
            Keyboard (Control string)


createShare : Model -> String
createShare model =
    let
        n =
            case model.playState of
                Won ->
                    String.fromInt (boardLength model.board)

                Lost ->
                    "X"

                Playing ->
                    "???"

        ( woordle, extraOffset ) =
            case model.wordSize of
                5 ->
                    case language of
                        English ->
                            ( "Wordle ", 0 )

                        Dutch ->
                            ( "Woordle ", 202 )

                l ->
                    case language of
                        English ->
                            ( "Wordle6 ", 1 )

                        Dutch ->
                            ( "Woordle" ++ String.fromInt l ++ " ", 1 )
    in
    woordle ++ String.fromInt (model.offset + extraOffset) ++ " " ++ n ++ "/6\n\n" ++ blokjes model model.board


blokje : Model -> CharGuess -> String
blokje model char =
    case ( char, model.useDarkMode, model.useContrastMode ) of
        ( New _, _, _ ) ->
            ""

        ( Correct _, _, False ) ->
            "🟩"

        ( Correct _, _, True ) ->
            "🟧"

        ( Place _, _, False ) ->
            "🟨"

        ( Place _, _, True ) ->
            "🟦"

        ( Wrong _, False, _ ) ->
            "⬜"

        ( Wrong _, True, _ ) ->
            "⬛"


blokjes : Model -> List BoardWord -> String
blokjes model board =
    case board of
        [] ->
            ""

        word :: [ [] ] ->
            word |> List.map (blokje model) |> String.join ""

        word :: words ->
            (word |> List.map (blokje model) |> String.join "") ++ "\n" ++ blokjes model words


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        newModel =
            case msg of
                TouchKey x ->
                    maybeHandleCharacter x model

                Keyboard (Character x) ->
                    maybeHandleCharacter x model

                Keyboard (Control "Backspace") ->
                    maybeHandleCharacter '⌫' model

                Keyboard (Control "Enter") ->
                    maybeHandleCharacter '↵' model

                Keyboard _ ->
                    model

                NewSize w h ->
                    { model | window = { width = w, height = h } }

                NewTime posix ->
                    updateToasts { model | currentTime = posix }

                NewZone zone ->
                    { model | currentZone = zone }

                Share ->
                    model

                AddToast toast ->
                    { model | toasts = toast :: model.toasts }

                DismissEndScreen ->
                    { model | showEndScreen = False }

                ShowHelp x ->
                    { model | showHelp = x }

                ShowSettings x ->
                    { model | showSettings = x }

                SetDarkMode x ->
                    { model | useDarkMode = x }

                SetContrastMode x ->
                    { model | useContrastMode = x }

                SetLargeKeyboard x ->
                    { model | useLargeKeyboard = x }

                None ->
                    model

        action =
            case ( msg, model.playState ) of
                ( TouchKey _, Playing ) ->
                    save (modelToJson newModel)

                ( Keyboard _, Playing ) ->
                    save (modelToJson newModel)

                ( SetDarkMode _, _ ) ->
                    save (modelToJson newModel)

                ( SetContrastMode _, _ ) ->
                    save (modelToJson newModel)

                ( Share, _ ) ->
                    share (createShare newModel)

                _ ->
                    Cmd.none
    in
    ( newModel, action )


updateToasts : Model -> Model
updateToasts model =
    { model | toasts = List.filter (\{ removeAt } -> posixToMillis model.currentTime < posixToMillis removeAt) model.toasts }


lastWord : List BoardWord -> BoardWord
lastWord ls =
    case ls of
        l :: [ [] ] ->
            l

        l :: [] ->
            l

        _ :: more ->
            lastWord more

        [] ->
            []


isCorrect : CharGuess -> Bool
isCorrect letter =
    case letter of
        Correct _ ->
            True

        _ ->
            False


allGreen : List CharGuess -> Bool
allGreen =
    List.all isCorrect


maybeHandleCharacter : Char -> Model -> Model
maybeHandleCharacter x model =
    case model.playState of
        Playing ->
            handleCharacter x model

        _ ->
            model


handleCharacter : Char -> Model -> Model
handleCharacter x model =
    case x of
        '⌫' ->
            { model | board = delLastLetter model.board }

        '↵' ->
            let
                submittedWord =
                    lastWord model.board |> List.map extractChar |> String.fromList
            in
            if Set.member submittedWord model.allWords then
                processNewWord model

            else
                { model | toasts = { content = text "Onbekend woord", removeAt = inTwoSeconds model.currentTime } :: model.toasts }

        thekey ->
            if Char.isAlpha thekey then
                { model | board = updateLastWord model (Char.toLower thekey) model.board }

            else
                model


boardLength : List BoardWord -> Int
boardLength board =
    case board of
        [] ->
            0

        _ :: [ [] ] ->
            1

        _ :: bs ->
            1 + boardLength bs


updateStatistics : List BoardWord -> Bool -> Statistics -> Statistics
updateStatistics board won oldstats =
    let
        newStreak =
            if won then
                oldstats.currentStreak + 1

            else
                0

        maxStreak =
            if won && newStreak > oldstats.maxStreak then
                newStreak

            else
                oldstats.maxStreak

        oldGuesses =
            oldstats.guesses

        guesses =
            boardLength board

        newGuesses =
            case ( guesses, won ) of
                ( _, False ) ->
                    { oldGuesses | fail = oldGuesses.fail + 1 }

                ( 1, True ) ->
                    { oldGuesses | g1 = oldGuesses.g1 + 1 }

                ( 2, True ) ->
                    { oldGuesses | g2 = oldGuesses.g2 + 1 }

                ( 3, True ) ->
                    { oldGuesses | g3 = oldGuesses.g3 + 1 }

                ( 4, True ) ->
                    { oldGuesses | g4 = oldGuesses.g4 + 1 }

                ( 5, True ) ->
                    { oldGuesses | g5 = oldGuesses.g5 + 1 }

                ( 6, True ) ->
                    { oldGuesses | g6 = oldGuesses.g6 + 1 }

                _ ->
                    -- Invalid
                    oldGuesses
    in
    { guesses = newGuesses
    , currentStreak = newStreak
    , maxStreak = maxStreak
    , gamesPlayed = oldstats.gamesPlayed + 1
    , gamesWon =
        if won then
            oldstats.gamesWon + 1

        else
            oldstats.gamesWon
    }


processNewWord : Model -> Model
processNewWord model =
    let
        newBoard =
            List.take 6 (checkLastWord model model.board)

        newKeyboard =
            updateKeyboard (lastWord newBoard) model.keyboard

        hasEnded =
            List.length (lastWord model.board) == model.wordSize && boardLength newBoard == 6

        lastWordAllGreen =
            lastWord newBoard |> allGreen

        ( playState, newStatistics ) =
            case ( hasEnded, lastWordAllGreen ) of
                ( _, True ) ->
                    ( Won, updateStatistics newBoard True model.statistics )

                ( True, False ) ->
                    ( Lost, updateStatistics newBoard False model.statistics )

                ( False, False ) ->
                    ( Playing, model.statistics )
    in
    { model | board = newBoard, keyboard = newKeyboard, playState = playState, statistics = newStatistics }


delLastLetter : List BoardWord -> List BoardWord
delLastLetter words =
    case words of
        w :: [] ->
            [ dropLast w ]

        [] ->
            [ [] ]

        w :: ws ->
            w :: delLastLetter ws


dropLast : List a -> List a
dropLast word =
    case word of
        _ :: [] ->
            []

        l :: ls ->
            l :: dropLast ls

        [] ->
            []


includes : a -> List a -> Bool
includes elem =
    List.any ((==) elem)


type alias ColorResult =
    { colors : BoardWord, leftToGuess : List Char }


remove : Char -> List Char -> List Char
remove c ls =
    case ls of
        [] ->
            []

        x :: xs ->
            if x == c then
                xs

            else
                x :: remove c xs


checkCorrect : ( CharGuess, Char ) -> ColorResult -> ColorResult
checkCorrect ( g, cor ) state =
    case g of
        New c ->
            if c == cor then
                { state | colors = Correct c :: state.colors, leftToGuess = remove c state.leftToGuess }

            else
                { state | colors = New c :: state.colors }

        _ ->
            -- Invalid
            state


checkPlace : ( CharGuess, Char ) -> ColorResult -> ColorResult
checkPlace ( g, cor ) state =
    case g of
        New c ->
            if includes c state.leftToGuess then
                { state | colors = Place c :: state.colors, leftToGuess = remove c state.leftToGuess }

            else
                { state | colors = Wrong c :: state.colors }

        x ->
            -- Already checked by checkCorrect
            { state | colors = x :: state.colors }


colorLetters_ : BoardWord -> List Char -> ColorResult
colorLetters_ guess correct =
    let
        tuples =
            List.map2 Tuple.pair guess correct

        correctLs =
            tuples |> List.foldr checkCorrect { colors = [], leftToGuess = correct }

        newTuples =
            List.map2 Tuple.pair correctLs.colors correct
    in
    List.foldr checkPlace { correctLs | colors = [] } newTuples


colorLetters : BoardWord -> List Char -> BoardWord
colorLetters guess correct =
    (colorLetters_ guess correct).colors


checkLastWord : Model -> List BoardWord -> List BoardWord
checkLastWord model words =
    case words of
        w :: [] ->
            if List.length w == model.wordSize then
                [ colorLetters
                    w
                    model.correctWord
                , []
                ]

            else
                [ w ]

        [] ->
            []

        w :: ws ->
            w :: checkLastWord model ws


updateLastWord : Model -> Char -> List BoardWord -> List BoardWord
updateLastWord model thekey words =
    case words of
        w :: [] ->
            if List.length w == model.wordSize then
                [ w ]

            else
                [ w ++ [ New thekey ] ]

        [] ->
            [ [ New thekey ] ]

        w :: ws ->
            w :: updateLastWord model thekey ws


extractChar : CharGuess -> Char
extractChar g =
    case g of
        New c ->
            c

        Correct c ->
            c

        Place c ->
            c

        Wrong c ->
            c


updateRow : CharGuess -> BoardWord -> BoardWord
updateRow c row =
    case row of
        [] ->
            []

        r :: rs ->
            let
                char_k =
                    extractChar r

                char_g =
                    extractChar c
            in
            case ( c, r, char_k == char_g ) of
                ( _, x, False ) ->
                    x :: updateRow c rs

                ( Correct c_, _, True ) ->
                    Correct c_ :: updateRow c rs

                ( Place _, Correct r_, True ) ->
                    Correct r_ :: updateRow c rs

                ( Place c_, _, True ) ->
                    Place c_ :: updateRow c rs

                ( Wrong c_, New _, True ) ->
                    Wrong c_ :: updateRow c rs

                ( _, New r_, True ) ->
                    New r_ :: updateRow c rs

                ( _, Correct r_, True ) ->
                    Correct r_ :: updateRow c rs

                ( _, Place r_, True ) ->
                    Place r_ :: updateRow c rs

                ( _, Wrong r_, True ) ->
                    Wrong r_ :: updateRow c rs


updateKeyboard : BoardWord -> Keyboard -> Keyboard
updateKeyboard word (( first, second, third ) as keyboard_) =
    case word of
        [] ->
            keyboard_

        x :: xs ->
            updateKeyboard xs ( updateRow x first, updateRow x second, updateRow x third )


titel : Model -> String
titel model =
    case model.wordSize of
        5 ->
            "WOORDLE"

        l ->
            "WOORDLE" ++ String.fromInt l


modalPadding : Model -> Int
modalPadding model =
    case (classifyDevice model.window).class of
        Element.Phone ->
            20

        _ ->
            60


rowHeight : Model -> Int -> Int
rowHeight model width =
    round <| (toFloat width - 4 * toFloat (model.wordSize - 1)) / toFloat model.wordSize


maybeViewSettings : Model -> Element Msg
maybeViewSettings model =
    if model.showSettings then
        viewSettings model

    else
        Element.none


onOffButton : Model -> msg -> Bool -> Element msg
onOffButton model msg state =
    let
        ( bgColor, txt ) =
            if state then
                ( buttonOn model, "AAN" )

            else
                ( buttonOff model, "UIT" )
    in
    button
        [ Background.color bgColor
        , Element.mouseDown [ Background.color (darken bgColor) ]
        , padding 10
        , rounded 10
        , Font.size 18
        ]
        { label = text txt, onPress = Just msg }


viewSettings : Model -> Element Msg
viewSettings model =
    let
        ( w, h ) =
            calcWinScreenWH model.window

        linkToOther =
            case language of
                English ->
                    Element.none

                Dutch ->
                    if model.wordSize == 5 then
                        paragraph [ Font.size 16 ]
                            [ text "Ook al "
                            , newTabLink [ Font.color linkColor ] { label = text "WOORDLE6", url = "/woordle6" }
                            , text " geprobeerd?"
                            ]

                    else
                        paragraph [ Font.size 16 ]
                            [ text "Ook al "
                            , newTabLink [ Font.color linkColor ] { label = text "gewone WOORDLE", url = "/" }
                            , text " geprobeerd?"
                            ]
    in
    el [ Background.color darkened_bg, centerX, centerY, width fill, height fill ]
        (column
            [ Background.color (pageBackground model)
            , width (px w)
            , height (px h)
            , centerX
            , centerY
            , padding (modalPadding model)
            , Border.rounded 10
            , onClick None
            , inFront (el [ alignRight, padding 20 ] (button [] { onPress = Just (ShowSettings False), label = text "✕" }))
            ]
            [ column [ centerX, centerY, spacing 10, scrollbars, width fill, height fill ]
                [ el [ Font.bold, centerX ] (text "INSTELLINGEN")
                , el [ height (px 10) ] Element.none
                , row [ width fill, spaceEvenly ] [ paragraph [] [ text "Donker thema" ], onOffButton model (SetDarkMode (not model.useDarkMode)) model.useDarkMode ]
                , el [ height (px 10) ] Element.none
                , el [ Border.width 1, width fill ] Element.none
                , el [ height (px 10) ] Element.none
                , row [ width fill, spaceEvenly ] [ paragraph [] [ text "Hoog contrast vakjes" ], onOffButton model (SetContrastMode (not model.useContrastMode)) model.useContrastMode ]
                , el [ height (px 10) ] Element.none
                , el [ Border.width 1, width fill ] Element.none
                , el [ height (px 10) ] Element.none
                , row [ width fill, spaceEvenly ] [ paragraph [] [ text "Grotere toetsenbord letters" ], onOffButton model (SetLargeKeyboard (not model.useLargeKeyboard)) model.useLargeKeyboard ]
                , el [ height (px 10) ] Element.none
                , el [ Border.width 1, width fill ] Element.none
                , el [ height (px 10) ] Element.none
                , paragraph [] [ text "Feedback: ", newTabLink [ Font.color linkColor ] { url = "https://twitter.com/pingiun_", label = text "yele op Twitter" } ]
                , case language of
                    English ->
                        paragraph [] [ Element.text "Based on ", newTabLink [ Font.color linkColor ] { url = "https://www.powerlanguage.co.uk/wordle/", label = Element.text "WORDLE by Josh Wardle" } ]

                    Dutch ->
                        Element.none
                , paragraph [] [ text "Code is beschikbaar ", newTabLink [ Font.color linkColor ] { url = "https://github.com/pingiun/woordle/", label = text "op GitHub" } ]
                , linkToOther
                ]
            ]
        )


viewToasts : Model -> Element Msg
viewToasts model =
    column [ spacing 20, centerX, padding 20 ] <|
        List.map
            (\{ content } ->
                el
                    [ centerX
                    , Background.color white
                    , Border.width 2
                    , Border.color (textColor model)
                    , Font.color (textColor model)
                    , Background.color (pageBackground model)
                    , Border.rounded 10
                    , padding 20
                    ]
                    content
            )
            model.toasts


maybeViewEndScreen : Model -> Element Msg
maybeViewEndScreen model =
    case ( model.playState, model.showEndScreen ) of
        ( Playing, _ ) ->
            Element.none

        ( _, False ) ->
            Element.none

        ( Won, True ) ->
            viewEndScreen model

        ( Lost, True ) ->
            viewEndScreen model


calcWinScreenWH : { a | width : Int, height : Int } -> ( Int, Int )
calcWinScreenWH { width, height } =
    let
        w =
            List.minimum [ 600, toFloat width * 0.95 ] |> Maybe.withDefault 600

        h =
            List.minimum [ 800, toFloat height * 0.95, w * 8 / 5 ] |> Maybe.withDefault 800
    in
    ( floor (h * 5 / 8), floor h )


endText : Model -> String
endText model =
    case model.playState of
        Won ->
            "Je hebt gewonnen!!"

        Lost ->
            "Je hebt verloren..."

        Playing ->
            "Dit kan niet"


pad : Char -> Int -> Int -> String
pad with width num_ =
    let
        num =
            String.fromInt num_

        pad_ padding upTo =
            case upTo of
                0 ->
                    num

                n ->
                    String.cons padding (pad_ padding (n - 1))
    in
    pad_ with (max 0 width - String.length num)


nextWordle : Model -> String
nextWordle model =
    let
        hours =
            (23 - Time.toHour model.currentZone model.currentTime)
                |> pad '0' 2

        minutes =
            (59 - Time.toMinute model.currentZone model.currentTime)
                |> pad '0' 2

        seconds =
            (59 - Time.toSecond model.currentZone model.currentTime)
                |> pad '0' 2
    in
    hours ++ ":" ++ minutes ++ ":" ++ seconds


viewEndScreen : Model -> Element Msg
viewEndScreen model =
    let
        ( w, h ) =
            calcWinScreenWH model.window

        linkToOther =
            case language of
                English ->
                    paragraph [ Font.size 16 ]
                        [ Element.text "Already done the regular "
                        , newTabLink [ Font.color linkColor ] { label = Element.text "WORDLE", url = "https://www.powerlanguage.co.uk/wordle/" }
                        , Element.text " today?"
                        ]

                Dutch ->
                    if model.wordSize == 5 then
                        paragraph [ Font.size 16 ]
                            [ text "Ook al "
                            , newTabLink [ Font.color linkColor ] { label = text "WOORDLE6", url = "/woordle6" }
                            , text " geprobeerd?"
                            ]

                    else
                        paragraph [ Font.size 16 ]
                            [ text "Ook al "
                            , newTabLink [ Font.color linkColor ] { label = text "gewone WOORDLE", url = "/" }
                            , text " geprobeerd?"
                            ]
    in
    el [ Background.color darkened_bg, centerX, centerY, width fill, height fill ]
        (column
            [ Background.color (pageBackground model)
            , width (px w)
            , height (px h)
            , centerX
            , centerY
            , padding (modalPadding model)
            , Border.rounded 10
            , inFront (el [ alignRight, padding 20 ] (button [] { onPress = Just DismissEndScreen, label = text "✕" }))
            ]
            [ column [ centerX, centerY, spacing 10, scrollbars, height fill ]
                [ el [ centerX ] (text (endText model))
                , el [ centerX ] (text "Het woord was: ")
                , el [ centerX, Font.bold, Font.size 45 ] (Element.text (model.correctWord |> List.map Char.toUpper |> String.fromList))
                , el [ height (px 40) ] Element.none
                , row [ width fill, spaceEvenly ]
                    [ column [ spacing 4 ] [ paragraph [ centerX, Font.center ] [ text ("Volgende " ++ titel model) ], el [ centerX, Font.family [ Font.monospace ], Font.size 28 ] (Element.text (nextWordle model)) ]
                    , button [ Background.color greenColor, Element.mouseDown [ Background.color (darken greenColor) ], padding 20, rounded 20 ] { label = text "Delen", onPress = Just Share }
                    ]
                , el [ height (px 40) ] Element.none
                , viewStatitics model
                , case language of
                    Dutch ->
                        paragraph [ Font.size 16 ]
                            [ text ("Kan je niet wachten op de volgende " ++ titel model ++ "? Probeer ook de ")
                            , newTabLink [ Font.color linkColor ] { label = text "originele WORDLE", url = "https://www.powerlanguage.co.uk/wordle/" }
                            , text " (in het Engels)!"
                            ]

                    English ->
                        Element.none
                , linkToOther
                ]
            ]
        )


viewStatitics : Model -> Element Msg
viewStatitics model =
    let
        extra =
            extraStats model.statistics

        -- modal width minus padding and first number
        widthLeft =
            (calcWinScreenWH model.window |> Tuple.first) - (2 * modalPadding model) - 25

        maxGuesses =
            List.maximum [ model.statistics.guesses.g1, model.statistics.guesses.g2, model.statistics.guesses.g3, model.statistics.guesses.g4, model.statistics.guesses.g5, model.statistics.guesses.g6 ] |> Maybe.withDefault 1

        bar i guesses =
            let
                bgColor =
                    if i == boardLength model.board && model.playState == Won then
                        correctColor model

                    else
                        wrongColor model
            in
            el
                [ Background.color bgColor
                , height (px 18)
                , width (px (max 20 (round (toFloat widthLeft / toFloat maxGuesses * toFloat guesses))))
                , inFront (el [ alignRight, paddingXY 5 0, Font.color (vakjeTextColor model) ] <| text (String.fromInt guesses))
                ]
                Element.none
    in
    column [ width fill, spacing 10 ]
        [ el [ Font.bold, centerX ] (text "STATISTIEK")
        , row [ width fill, spacing 10 ]
            [ column [ centerX ] [ el [ centerX, Font.size 28 ] <| Element.text (String.fromInt model.statistics.gamesPlayed ++ "×"), el [ centerX, Font.size 14 ] <| text "gespeeld" ]
            , column [ centerX ] [ el [ centerX, Font.size 28 ] <| Element.text (String.fromInt extra.winPercentage), el [ centerX, Font.size 14 ] <| text "Win %" ]
            , column [ centerX ] [ el [ centerX, Font.size 28 ] <| Element.text (String.fromInt model.statistics.currentStreak), el [ centerX, Font.size 14 ] <| text "Huidige reeks" ]
            , column [ centerX ] [ el [ centerX, Font.size 28 ] <| Element.text (String.fromInt model.statistics.maxStreak), el [ centerX, Font.size 14 ] <| text "Max reeks" ]
            ]
        , el [ height (px 10) ] Element.none
        , el [ Font.bold, centerX ] (text "VERDELING")
        , column [ spacing 5 ]
            [ row [ Font.size 18, spacing 5 ] [ text "1", bar 1 model.statistics.guesses.g1 ]
            , row [ Font.size 18, spacing 5 ] [ text "2", bar 2 model.statistics.guesses.g2 ]
            , row [ Font.size 18, spacing 5 ] [ text "3", bar 3 model.statistics.guesses.g3 ]
            , row [ Font.size 18, spacing 5 ] [ text "4", bar 4 model.statistics.guesses.g4 ]
            , row [ Font.size 18, spacing 5 ] [ text "5", bar 5 model.statistics.guesses.g5 ]
            , row [ Font.size 18, spacing 5 ] [ text "6", bar 6 model.statistics.guesses.g6 ]
            ]
        , el [ height (px 10) ] Element.none
        , el [ Border.width 1, width fill ] Element.none
        , el [ height (px 10) ] Element.none
        ]


calcBoardWH : Model -> { a | width : Int, height : Int } -> ( Int, Int )
calcBoardWH model { width, height } =
    let
        heightRatio =
            case (classifyDevice model.window).class of
                Phone ->
                    0.5

                _ ->
                    0.8

        ( wMinimum, hMinimum ) =
            case ( (classifyDevice model.window).class, model.wordSize ) of
                ( Phone, _ ) ->
                    ( 300, 360 )

                ( _, 5 ) ->
                    ( 300, 360 )

                ( _, _ ) ->
                    ( 400, 480 )

        w =
            List.minimum [ wMinimum, toFloat width * 0.8 ] |> Maybe.withDefault wMinimum

        h =
            List.minimum [ hMinimum, toFloat height * heightRatio, w * 6 / toFloat model.wordSize ] |> Maybe.withDefault hMinimum
    in
    ( floor (h * toFloat model.wordSize / 6), floor h )


fillList : List a -> Int -> List (Maybe a)
fillList list to =
    case ( list, to ) of
        ( [], 0 ) ->
            []

        ( [], n ) ->
            Nothing :: fillList [] (n - 1)

        ( x :: xs, 0 ) ->
            Just x :: fillList xs 0

        ( x :: xs, n ) ->
            Just x :: fillList xs (n - 1)


charToString : Char -> String
charToString =
    List.singleton >> String.fromList


white : Element.Color
white =
    rgb255 255 255 255


darkened_bg : Element.Color
darkened_bg =
    rgba255 100 100 100 0.3


grey : Element.Color
grey =
    rgb255 200 200 200


darkgrey : Element.Color
darkgrey =
    rgb255 100 100 100


greenColor : Element.Color
greenColor =
    rgb255 60 218 68


buttonOn : Model -> Element.Color
buttonOn model =
    if model.useContrastMode then
        orangeColor

    else
        greenColor


buttonOff : Model -> Element.Color
buttonOff model =
    if model.useContrastMode then
        lightgrey

    else
        lightgrey


correctColor : Model -> Element.Color
correctColor model =
    if model.useContrastMode then
        orangeColor

    else
        greenColor


placeColor : Model -> Element.Color
placeColor model =
    if model.useContrastMode then
        lightBlueColor

    else
        yellow


wrongColor : Model -> Element.Color
wrongColor model =
    if model.useDarkMode then
        darken darkgrey

    else
        darkgrey


redColor : Element.Color
redColor =
    rgb255 196 29 0


linkColor : Element.Color
linkColor =
    rgb255 0 0 245


lightBlueColor : Element.Color
lightBlueColor =
    rgb255 153 182 209


yellow : Element.Color
yellow =
    rgb255 230 205 23


orangeColor : Element.Color
orangeColor =
    rgb255 255 73 51


lightgrey : Element.Color
lightgrey =
    rgb255 200 200 200


pageBackground : Model -> Element.Color
pageBackground model =
    if model.useDarkMode then
        darkBackground

    else
        white


darkBackground : Element.Color
darkBackground =
    rgb255 21 23 20


textColor : Model -> Element.Color
textColor model =
    if model.useDarkMode then
        lightText

    else
        black


vakjeTextColor : Model -> Element.Color
vakjeTextColor model =
    if model.useDarkMode then
        lightText

    else
        white


newVakjeTextColor model =
    if model.useDarkMode then
        lightText

    else
        black


lightText =
    rgb255 240 240 240


black =
    rgb255 0 0 0


keyColor : Model -> Element.Color
keyColor model =
    if model.useDarkMode then
        darken lightgrey

    else
        lightgrey


darken : Element.Color -> Element.Color
darken c =
    let
        { red, green, blue, alpha } =
            toRgb c
    in
    fromRgb { red = red * 0.8, green = green * 0.8, blue = blue * 0.8, alpha = alpha }


type Language
    = English
    | Dutch


language : Language
language =
    {- The line below is replaced with in export.html such that Dutch is commented and the end of the comment ends up below -}
    {- English -}
    Dutch



-- -}


text : String -> Element msg
text str =
    case language of
        Dutch ->
            Element.text str

        English ->
            Element.text <|
                case str of
                    "ENTER" ->
                        "ENTER"

                    "..." ->
                        "..."

                    "WOORDLE6" ->
                        "WORDLE6"

                    "INSTELLINGEN" ->
                        "SETTINGS"

                    "AAN" ->
                        "ON"

                    "UIT" ->
                        "OFF"

                    "Donker thema" ->
                        "Dark Theme"

                    "Hoog contrast vakjes" ->
                        "Color Blind Mode"

                    "Feedback: " ->
                        "Feedback: "

                    "yele op Twitter" ->
                        "yele on Twitter"

                    "INSTRUCTIES" ->
                        "INSTRUCTIONS"

                    "Je hebt gewonnen!!" ->
                        "You won!!"

                    "Je hebt verloren..." ->
                        "You lost..."

                    "Het woord was: " ->
                        "The word was"

                    "Volgende WOORDLE6" ->
                        "Next WORDLE6"

                    "Delen" ->
                        "Share"

                    "STATISTIEK" ->
                        "STATISTICS"

                    "VERDELING" ->
                        "GUESS DISTRIBUTION"

                    "gespeeld" ->
                        "played"

                    "Win %" ->
                        "Win %"

                    "Huidige reeks" ->
                        "Current Streak"

                    "Max reeks" ->
                        "Max Streak"

                    "Gok het " ->
                        "Try to guess the "

                    " in 6 keer." ->
                        " within 6 guesses."

                    "Na elke gok zullen de kleuren van de vakjes aangeven hoe dichtbij je was." ->
                        "After every guess the colors of the squares will tell you how close you were."

                    "De letter " ->
                        "The letter "

                    " zit op de juiste plek in het woord." ->
                        " is in the correct place."

                    "Elke dag is er een nieuwe " ->
                        "Every day there will be a new "

                    " beschikbaar!" ->
                        " available."

                    " zit in het woord maar op een andere plek." ->
                        " is in the word, but at a different place."

                    " zit helemaal niet in het woord." ->
                        " is not in the word at any place."

                    "Code is beschikbaar " ->
                        "Code is available "

                    "op GitHub" ->
                        "on GitHub"

                    "Onbekend woord" ->
                        "Unknown word"

                    "Copied to clipboard" ->
                        "Copied to clipboard"

                    "Can't share" ->
                        "Can't share"

                    other ->
                        if String.length other == 1 then
                            other

                        else
                            other


main : Program InitialData Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
