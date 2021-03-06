port module Main exposing (main)

{-| Single Gallery Application to display various examples of generative art.

@docs main

-}

import Example.Chords as Chords
import Example.Crescent as Crescent
import Example.Curtain as Curtain
import Example.Grid as Grid
import Example.HilbertCurve as HilbertCurve
import Example.Landscape as Landscape
import Example.ParallelRandom as ParallelRandom
import Example.Rectangles as Rectangles
import Example.Sun as Sun
import Generative exposing (..)
import Html
    exposing
        ( Html
        , a
        , article
        , button
        , div
        , input
        , main_
        , nav
        , node
        , p
        , text
        )
import Html.Attributes exposing (class, href, id, style, type_)
import Html.Events exposing (onClick)
import Json.Decode exposing (decodeString, field, string)
import Navigation exposing (Location)
import Tuple exposing (first, mapFirst, mapSecond, second)
import UrlParser
    exposing
        ( Parser
        , oneOf
        , parseHash
        , s
        , top
        )


-- MODEL --


type Action
    = RaiseLowerPen
    | DisableMotor
    | Print
    | Download


type Route
    = Crescent (Maybe Crescent.Model)
    | Grid (Maybe Grid.Model)
    | Curtain (Maybe Curtain.Model)
    | Landscape (Maybe Landscape.Model)
    | ParallelRandom (Maybe ParallelRandom.Model)
    | Sun (Maybe Sun.Model)
    | Chords (Maybe Chords.Model)
    | Rectangles (Maybe Rectangles.Model)
    | HilbertCurve (Maybe HilbertCurve.Model)


type alias Model =
    { route : Route
    , status : Maybe String
    }


type Msg
    = NavigateTo Location
    | Menu Action
    | PlotterStatus String
    | CrescentMsg Crescent.Msg
    | GridMsg Grid.Msg
    | CurtainMsg Curtain.Msg
    | LandscapeMsg Landscape.Msg
    | ParallelRandomMsg ParallelRandom.Msg
    | SunMsg Sun.Msg
    | ChordsMsg Chords.Msg
    | RectanglesMsg Rectangles.Msg
    | HilbertCurveMsg HilbertCurve.Msg


init : Location -> ( Model, Cmd Msg )
init location =
    let
        routeMsg =
            case parseLocation location of
                Crescent _ ->
                    Crescent.init
                        |> mapTuple2 (Crescent << Just) (Cmd.map CrescentMsg)

                Grid _ ->
                    Grid.init
                        |> mapTuple2 (Grid << Just) (Cmd.map GridMsg)

                Curtain _ ->
                    Curtain.init
                        |> mapTuple2 (Curtain << Just) (Cmd.map CurtainMsg)

                Landscape _ ->
                    Landscape.init
                        |> mapTuple2 (Landscape << Just) (Cmd.map LandscapeMsg)

                ParallelRandom _ ->
                    ParallelRandom.init
                        |> mapTuple2 (ParallelRandom << Just) (Cmd.map ParallelRandomMsg)

                Sun _ ->
                    Sun.init
                        |> mapTuple2 (Sun << Just) (Cmd.map SunMsg)

                Chords _ ->
                    Chords.init
                        |> mapTuple2 (Chords << Just) (Cmd.map ChordsMsg)

                Rectangles _ ->
                    Rectangles.init
                        |> mapTuple2 (Rectangles << Just) (Cmd.map RectanglesMsg)

                HilbertCurve _ ->
                    HilbertCurve.init
                        |> mapTuple2 (HilbertCurve << Just) (Cmd.map HilbertCurveMsg)
    in
    ( { route = first routeMsg
      , status = Nothing
      }
    , second routeMsg
    )



-- VIEW --


view : Model -> Html Msg
view model =
    main_
        []
        [ nav
            []
            [ p [] [ text "Repetition" ]
            , a [ href "#grid" ] [ text "Grid" ]
            , a [ href "#crescent" ] [ text "Crescent" ]
            , p [] [ text "Accumulation" ]
            , a [ href "#parallel-random" ] [ text "Parallel Random" ]
            , a [ href "#curtain" ] [ text "Curtain" ]
            , a [ href "#landscape" ] [ text "Landscape" ]
            , a [ href "#sun" ] [ text "Sun" ]
            , a [ href "#chords" ] [ text "Chords" ]
            , p [] [ text "L-Systems" ]
            , a [ href "#rectangles" ] [ text "Rectangles" ]
            , a [ href "#hilbert-curve" ] [ text "Hilbert Curve" ]
            ]
        , article
            []
            [ div
                [ class "options" ]
                [ button
                    [ onClick (Menu RaiseLowerPen) ]
                    [ text "↕️ Raise/Lower pen" ]
                , button
                    [ onClick (Menu DisableMotor) ]
                    [ text "🚫 Disable motor" ]
                , button
                    [ onClick (Menu Print) ]
                    [ text "🖊 Print" ]
                , input
                    [ id "svgFile"
                    , type_ "file"
                    , style [ ( "display", "none" ) ]
                    ]
                    []
                , button
                    [ onClick (Menu Download) ]
                    [ text "💾 Download" ]
                , div
                    [ class "status" ]
                    [ text <| Maybe.withDefault "" model.status ]
                ]
            , div
                [ class "main" ]
                [ render model.route ]
            ]
        ]


render : Route -> Html Msg
render route =
    case route of
        Crescent (Just pageModel) ->
            Crescent.view pageModel
                |> Html.map CrescentMsg

        Grid (Just pageModel) ->
            Grid.view pageModel
                |> Html.map GridMsg

        ParallelRandom (Just pageModel) ->
            ParallelRandom.view pageModel
                |> Html.map ParallelRandomMsg

        Curtain (Just pageModel) ->
            Curtain.view pageModel
                |> Html.map CurtainMsg

        Landscape (Just pageModel) ->
            Landscape.view pageModel
                |> Html.map LandscapeMsg

        Sun (Just pageModel) ->
            Sun.view pageModel
                |> Html.map SunMsg

        Chords (Just pageModel) ->
            Chords.view pageModel
                |> Html.map ChordsMsg

        Rectangles (Just pageModel) ->
            Rectangles.view pageModel
                |> Html.map RectanglesMsg

        HilbertCurve (Just pageModel) ->
            HilbertCurve.view pageModel
                |> Html.map HilbertCurveMsg

        _ ->
            text "404 Not Found"



-- UPDATE --


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.route ) of
        ( NavigateTo location, _ ) ->
            init location

        ( Menu action, _ ) ->
            case action of
                RaiseLowerPen ->
                    ( model, raiseLowerPen "" )

                DisableMotor ->
                    ( model, disableMotor "" )

                Print ->
                    ( model, print "" )

                Download ->
                    ( model, download <| toString model.route )

        ( PlotterStatus value, _ ) ->
            ( { model | status = Just <| decodePlotterStatus value }, Cmd.none )

        ( msg, route ) ->
            let
                routeMsg =
                    case ( msg, route ) of
                        ( CrescentMsg pageMsg, Crescent (Just pageModel) ) ->
                            Crescent.update pageMsg pageModel
                                |> mapTuple2 (Crescent << Just) (Cmd.map CrescentMsg)

                        ( GridMsg pageMsg, Grid (Just pageModel) ) ->
                            Grid.update pageMsg pageModel
                                |> mapTuple2 (Grid << Just) (Cmd.map GridMsg)

                        ( ParallelRandomMsg pageMsg, ParallelRandom (Just pageModel) ) ->
                            ParallelRandom.update pageMsg pageModel
                                |> mapTuple2 (ParallelRandom << Just) (Cmd.map ParallelRandomMsg)

                        ( CurtainMsg pageMsg, Curtain (Just pageModel) ) ->
                            Curtain.update pageMsg pageModel
                                |> mapTuple2 (Curtain << Just) (Cmd.map CurtainMsg)

                        ( LandscapeMsg pageMsg, Landscape (Just pageModel) ) ->
                            Landscape.update pageMsg pageModel
                                |> mapTuple2 (Landscape << Just) (Cmd.map LandscapeMsg)

                        ( SunMsg pageMsg, Sun (Just pageModel) ) ->
                            Sun.update pageMsg pageModel
                                |> mapTuple2 (Sun << Just) (Cmd.map SunMsg)

                        ( ChordsMsg pageMsg, Chords (Just pageModel) ) ->
                            Chords.update pageMsg pageModel
                                |> mapTuple2 (Chords << Just) (Cmd.map ChordsMsg)

                        ( RectanglesMsg pageMsg, Rectangles (Just pageModel) ) ->
                            Rectangles.update pageMsg pageModel
                                |> mapTuple2 (Rectangles << Just) (Cmd.map RectanglesMsg)

                        ( HilbertCurveMsg pageMsg, HilbertCurve (Just pageModel) ) ->
                            HilbertCurve.update pageMsg pageModel
                                |> mapTuple2 (HilbertCurve << Just) (Cmd.map HilbertCurveMsg)

                        _ ->
                            ( route, Cmd.none )
            in
            ( { model | route = first routeMsg }, Cmd.none )


decodePlotterStatus : String -> String
decodePlotterStatus value =
    case decodeString (field "version" string) value of
        Ok s ->
            s

        Err e ->
            toString e



-- PORTS --


port getPlotterStatus : (String -> msg) -> Sub msg


port raiseLowerPen : String -> Cmd msg


port disableMotor : String -> Cmd msg


port print : String -> Cmd msg


port download : String -> Cmd msg



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ getPlotterStatus PlotterStatus
        ]



-- ROUTING --


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ UrlParser.map (Curtain Nothing) top
        , UrlParser.map (Grid Nothing) (s "grid")
        , UrlParser.map (Crescent Nothing) (s "crescent")
        , UrlParser.map (ParallelRandom Nothing) (s "parallel-random")
        , UrlParser.map (Curtain Nothing) (s "curtain")
        , UrlParser.map (Landscape Nothing) (s "landscape")
        , UrlParser.map (Sun Nothing) (s "sun")
        , UrlParser.map (Chords Nothing) (s "chords")
        , UrlParser.map (Rectangles Nothing) (s "rectangles")
        , UrlParser.map (HilbertCurve Nothing) (s "hilbert-curve")
        ]


parseLocation : Location -> Route
parseLocation location =
    case parseHash matchers location of
        Just route ->
            route

        Nothing ->
            Curtain Nothing


{-| Program Entry.
-}
main : Program Never Model Msg
main =
    Navigation.program NavigateTo
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
