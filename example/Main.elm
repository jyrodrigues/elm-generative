port module Main exposing (main)

{-| Single Gallery Application to display various examples of generative art.

@docs main

-}

-- elm-generative examples

import Example.Curtain as Curtain
import Example.Landscape as Landscape
import Example.ParallelRandom as ParallelRandom
import Example.Sun as Sun
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


init : Location -> ( Model, Cmd Msg )
init location =
    let
        routeMsg =
            case parseLocation location of
                Curtain _ ->
                    Curtain.init
                        |> mapFirst (Curtain << Just)
                        |> mapSecond (Cmd.map CurtainMsg)

                Landscape _ ->
                    Landscape.init
                        |> mapFirst (Landscape << Just)
                        |> mapSecond (Cmd.map LandscapeMsg)

                ParallelRandom _ ->
                    ParallelRandom.init
                        |> mapFirst (ParallelRandom << Just)
                        |> mapSecond (Cmd.map ParallelRandomMsg)

                Sun _ ->
                    Sun.init
                        |> mapFirst (Sun << Just)
                        |> mapSecond (Cmd.map SunMsg)
    in
    ( { route = first routeMsg
      , status = Nothing
      }
    , second routeMsg
    )


type Msg
    = NavigateTo Location
    | Menu Action
    | PlotterStatus String
    | CurtainMsg Curtain.Msg
    | LandscapeMsg Landscape.Msg
    | ParallelRandomMsg ParallelRandom.Msg
    | SunMsg Sun.Msg


type Action
    = RaiseLowerPen
    | DisableMotor
    | Print
    | Download


type Route
    = Curtain (Maybe Curtain.Model)
    | Landscape (Maybe Landscape.Model)
    | ParallelRandom (Maybe ParallelRandom.Model)
    | Sun (Maybe Sun.Model)


type alias Model =
    { route : Route
    , status : Maybe String
    }



-- VIEW --


view : Model -> Html Msg
view model =
    main_
        []
        [ nav
            []
            [ p [] [ text "Accumulation" ]
            , a [ href "/#curtain" ] [ text "Curtain" ]
            , a [ href "/#parallel-random" ] [ text "Parallel Random" ]
            , a [ href "/#landscape" ] [ text "Landscape" ]
            , a [ href "/#sun" ] [ text "Sun" ]
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
        Curtain (Just pageModel) ->
            Curtain.view pageModel
                |> Html.map CurtainMsg

        Landscape (Just pageModel) ->
            Landscape.view pageModel
                |> Html.map LandscapeMsg

        ParallelRandom (Just pageModel) ->
            ParallelRandom.view pageModel
                |> Html.map ParallelRandomMsg

        Sun (Just pageModel) ->
            Sun.view pageModel
                |> Html.map SunMsg

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
                        ( CurtainMsg pageMsg, Curtain (Just pageModel) ) ->
                            Curtain.update pageMsg pageModel
                                |> mapFirst (Curtain << Just)
                                |> mapSecond (Cmd.map CurtainMsg)

                        ( LandscapeMsg pageMsg, Landscape (Just pageModel) ) ->
                            Landscape.update pageMsg pageModel
                                |> mapFirst (Landscape << Just)
                                |> mapSecond (Cmd.map LandscapeMsg)

                        ( ParallelRandomMsg pageMsg, ParallelRandom (Just pageModel) ) ->
                            ParallelRandom.update pageMsg pageModel
                                |> mapFirst (ParallelRandom << Just)
                                |> mapSecond (Cmd.map ParallelRandomMsg)

                        ( SunMsg pageMsg, Sun (Just pageModel) ) ->
                            Sun.update pageMsg pageModel
                                |> mapFirst (Sun << Just)
                                |> mapSecond (Cmd.map SunMsg)

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
        , UrlParser.map (Curtain Nothing) (s "curtain")
        , UrlParser.map (Landscape Nothing) (s "landscape")
        , UrlParser.map (ParallelRandom Nothing) (s "parallel-random")
        , UrlParser.map (Sun Nothing) (s "sun")
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
