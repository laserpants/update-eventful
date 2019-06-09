module Main exposing (Flags, Msg(..), State, handleItemAdded, handleTaskDone, inNotifications, inTodos, init, main, update, view)

import Browser exposing (Document)
import Data.TodoItem exposing (TodoItem)
import Html exposing (..)
import Html.Attributes exposing (class, href, style)
import Html.Events exposing (..)
import Notifications
import Todos
import Update.Deep exposing (..)
import Update.Deep.Browser as Deep


type alias Flags =
    ()


type Msg
    = TodosMsg Todos.Msg
    | NotificationsMsg Notifications.Msg


type alias State =
    { todos : Todos.State
    , notifications : Notifications.State
    }


inTodos : In State Todos.State msg a
inTodos =
    inState { get = .todos, set = \state todos -> { state | todos = todos } }


inNotifications : In State Notifications.State msg a
inNotifications =
    inState { get = .notifications, set = \state notifs -> { state | notifications = notifs } }


init : Flags -> Update State Msg a
init flags =
    save State
        |> andMap (Todos.init TodosMsg)
        |> andMap (Notifications.init NotificationsMsg)


handleItemAdded : TodoItem -> State -> Update State Msg a
handleItemAdded _ =
    Notifications.addNotification "A new task was added to your list." NotificationsMsg
        |> inNotifications


handleTaskDone : TodoItem -> State -> Update State Msg a
handleTaskDone item =
    Notifications.addNotification ("The following task was completed: " ++ item.text) NotificationsMsg
        |> inNotifications


update : Msg -> State -> Update State Msg a
update msg =
    case msg of
        TodosMsg todosMsg ->
            inTodos (Todos.update { onTaskAdded = handleItemAdded, onTaskDone = handleTaskDone } todosMsg)

        NotificationsMsg notificationsMsg ->
            inNotifications (Notifications.update notificationsMsg NotificationsMsg)


view : State -> Document Msg
view { notifications, todos } =
    { title = ""
    , body =
        [ nav [ class "navbar is-primary" ]
            [ div [ class "navbar-brand" ]
                [ a [ href "#", class "title is-5 navbar-item" ]
                    [ text "trollo" ]
                ]
            ]
        , div [ class "columns is-centered" ]
            [ div [ class "column is-two-thirds" ]
                [ Notifications.view notifications NotificationsMsg
                , Todos.view todos TodosMsg
                ]
            ]
        ]
    }


main : Program () State Msg
main =
    Deep.document
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }
