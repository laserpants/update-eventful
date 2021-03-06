# To Do-List App Example

THIS GUIDE IS STILL WORK IN PROGRESS

#### Run this example in the browser [here](https://laserpants.github.io/elm-update-deep/examples/todo-list).

The application consists of the following modules:

```
               ┌────────────┐               |
          ┌────│    Main    │────┐          |
          │    └────────────┘    │          |   ┌───────────────────┐
 ┌─────── ▼ ───────┐       ┌──── ▼ ────┐    |   │   Data.TodoItem   │
 │  Notifications  │       │   Todos   │    |   └───────────────────┘
 └─────────────────┘       └─────┬─────┘    |   ┌───────────────────┐         
                                 │          |   │ Data.Notification │         
                         ┌────── ▼ ─────┐   |   └───────────────────┘         
                         │  Todos.Form  │   |
                         └──────────────┘   |
```

On the right, the `Data.TodoItem` module defines the `TodoItem` type

```elm
type alias TodoItem = { text : String }
```

which is just a description of the anticipated task. `Data.Notification` represents a “toast” notification shown on the screen.
These modules are not so important for this example, so let's concentrate instead on the four modules on the left side of the diagram; `Main`, `Notifications`, `Todos`, and `Todos.Form`.
Each one of these specifies its own `Msg` and `State` type, as well as `update` and `init` functions. (Subscriptions are not used in this example.)

> Note that *state* is used here to refer to (what the Elm architecture calls) a *model*, and that these two terms are used more or less interchangeably in the following.

It is useful to imagine these as instances of the following base template:

```elm
module Template exposing (..)

type Msg
    = SomeMsg
    | SomeOtherMsg
    | -- etc.

type alias State =
    { 
        -- ...
    }

init : Update State msg a
init = 
    save {}

update : Msg -> State -> Update State msg a
update msg state =
    case msg of
        -- etc.

view = ...
```

So far, the only thing that makes this different is the return types of `update` and `init`.
Here is the definition of the `Update` type alias:

```elm
type alias Update m c e =
    ( m, Cmd c, List e )
```

This is just the usual model-`Cmd` pair with an extra, third element.
As you may have guessed already, writing `save {}` in the above code, is the same as returning `( {}, Cmd.none, [] )`.
We typically manipulate these values by composing functions of the form `something -> State -> Update State msg a` in the familiar pipe-driven style:

```elm
save state
    |> andThen doSomething
    |> andThen doSomethingElse
```

```elm
state
    |> addCmd (Ports.clearSession ())
    |> andThen doSomething
```

How is this `Update` type useful then? Well, messages move down in the update tree. To pass information in the opposite direction, this library introduces a callback-based event handling mechanism. That is what the third element of the `Update` tuple is for.

In this example, there are three such event handlers involved:

```
               ┌────────────┐
               │    Main    │
               └── ▲ ─ ▲ ───┘
                   │   │
                   │   │--- onTaskAdded
     onTaskDone ---│   │
                   │   │   ┌───────────┐
                   └───┴───│   Todos   │
                           └──── ▲ ────┘
                                 │
                                 │--- onSubmit
                                 │
                         ┌───────┴──────┐
                         │  Todos.Form  │
                         └──────────────┘
```

When a task is added or completed, `Main` gets a chance to update itself, in this case so that we can show a notification (toast).
Similarly, `Todos` is told when the form is submitted, so that it can add the new `TodoItem` to its list. Let's look at `update` in `Todos.Form`:

```elm
-- src/Todos/Form.elm (line 30)

update : { onSubmit : FormData -> a } -> Msg -> State -> Update State msg a
update { onSubmit } msg state =
    case msg of
        Submit ->
            state
                |> invokeHandler (onSubmit { text = state.text })
                |> andThen (setText "")
        
        Focus ->
            -- etc.
```

An `onSubmit` callback is given as the first argument to the `update` function.
When the `Submit` message is received, this callback is “invoked” using the `invokeHandler` function, which is part of this library.

Moving up in the, in `Todos.elm` 

```elm
-- src/Todos.elm (line 52)

    let
        handleSubmit data =
            let
                item =
                    { text = data.text }
            in
            addItem item
                >> andInvokeHandler (onTaskAdded item)

-- src/Todos.elm (line 71)

    in
    case msg of
        TodosFormMsg formMsg ->
            inForm (Form.update { onSubmit = handleSubmit } formMsg)

        -- etc.
```

`addItem` adds the `TodoItem` to the list of tasks.

Finally, in `Main.elm`

```elm
-- src/Main.elm (line 59)

update : Msg -> State -> Update State Msg a
update msg =
    case msg of
        TodosMsg todosMsg ->
            inTodos (Todos.update { onTaskAdded = handleItemAdded, onTaskDone = handleTaskDone } todosMsg)

        -- etc.
```

```elm
-- src/Main.elm (line 47)

handleItemAdded : TodoItem -> State -> Update State Msg a
handleItemAdded _ =
    Notifications.addNotification "A new task was added to your list." NotificationsMsg
        |> inNotifications
```
