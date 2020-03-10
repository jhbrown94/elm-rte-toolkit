module RichTextEditor.Decorations exposing (..)

import Dict
import Html
import Html.Attributes
import Html.Events
import RichTextEditor.Model.Annotation exposing (selectionAnnotation)
import RichTextEditor.Model.Editor exposing (DecoderFunc, Decorations, ElementDecoratorFunction, InternalEditorMsg(..), MarkDecoratorFunction, elementDecorators, markDecorators, withElementDecorators, withMarkDecorators)
import RichTextEditor.Model.Node
    exposing
        ( ElementParameters
        , NodePath
        , annotationsFromElementParameters
        )
import RichTextEditor.Model.Selection exposing (caretSelection)
import Set


selectableDecoration : DecoderFunc msg -> NodePath -> ElementParameters -> NodePath -> List (Html.Attribute msg)
selectableDecoration decoder editorNodePath elementParameters _ =
    (if Set.member selectionAnnotation (annotationsFromElementParameters elementParameters) then
        [ Html.Attributes.class "rte-selected" ]

     else
        []
    )
        ++ [ Html.Events.onClick
                (decoder <|
                    SelectionEvent (Just (caretSelection editorNodePath 0)) False
                )
           ]


addElementDecoration : String -> ElementDecoratorFunction msg -> Decorations msg -> Decorations msg
addElementDecoration name decorator decorations =
    let
        eleDecorators =
            elementDecorators decorations

        previousDecorations =
            Maybe.withDefault [] (Dict.get name eleDecorators)
    in
    decorations
        |> withElementDecorators (Dict.insert name (decorator :: previousDecorations) eleDecorators)


addMarkDecoration : String -> MarkDecoratorFunction msg -> Decorations msg -> Decorations msg
addMarkDecoration name decorator decorations =
    let
        mDecorators =
            markDecorators decorations

        previousDecorations =
            Maybe.withDefault [] (Dict.get name mDecorators)
    in
    decorations
        |> withMarkDecorators (Dict.insert name (decorator :: previousDecorations) mDecorators)


getMarkDecorators : String -> Decorations msg -> List (MarkDecoratorFunction msg)
getMarkDecorators name decorations =
    let
        mDecorators =
            markDecorators decorations
    in
    Maybe.withDefault [] (Dict.get name mDecorators)


getElementDecorators : String -> Decorations msg -> List (ElementDecoratorFunction msg)
getElementDecorators name decorations =
    let
        eDecorators =
            elementDecorators decorations
    in
    Maybe.withDefault [] (Dict.get name eDecorators)