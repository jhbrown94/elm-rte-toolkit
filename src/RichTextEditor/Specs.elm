module RichTextEditor.Specs exposing
    ( blockquote
    , bold
    , code
    , codeBlock
    , doc
    , hardBreak
    , heading
    , horizontalRule
    , image
    , italic
    , link
    , listItem
    , markdown
    , orderedList
    , paragraph
    , unorderedList
    )

import Array exposing (Array)
import RichTextEditor.Annotation exposing (selectable)
import RichTextEditor.Model.Attribute exposing (Attribute(..), findIntegerAttribute, findStringAttribute)
import RichTextEditor.Model.Element exposing (attributes, element)
import RichTextEditor.Model.HtmlNode exposing (HtmlNode(..))
import RichTextEditor.Model.Mark as Mark exposing (mark)
import RichTextEditor.Model.MarkDefinition
    exposing
        ( HtmlToMark
        , MarkDefinition
        , MarkToHtml
        , defaultHtmlToMark
        , markDefinition
        )
import RichTextEditor.Model.NodeDefinition
    exposing
        ( ElementToHtml
        , HtmlToElement
        , NodeDefinition
        , blockLeaf
        , blockNode
        , defaultElementToHtml
        , defaultHtmlToElement
        , inlineLeaf
        , nodeDefinition
        , textBlock
        )
import RichTextEditor.Model.Spec
    exposing
        ( Spec
        , emptySpec
        , withMarkDefinitions
        , withNodeDefinitions
        )
import Set


doc : NodeDefinition
doc =
    nodeDefinition "doc" "root" (blockNode [ "block" ]) docToHtml htmlToDoc


docToHtml : ElementToHtml
docToHtml _ children =
    ElementNode "div"
        [ ( "data-rte-doc", "true" ) ]
        children


htmlToDoc : HtmlToElement
htmlToDoc definition node =
    case node of
        ElementNode name attrs children ->
            if name == "div" && attrs == [ ( "data-rte-doc", "true" ) ] then
                Just <| ( element definition [] Set.empty, children )

            else
                Nothing

        _ ->
            Nothing


paragraph : NodeDefinition
paragraph =
    nodeDefinition "paragraph" "block" (textBlock [ "inline" ]) paragraphToHtml htmlToParagraph


paragraphToHtml : ElementToHtml
paragraphToHtml _ children =
    ElementNode "p" [] children


htmlToParagraph : HtmlToElement
htmlToParagraph definition node =
    case node of
        ElementNode name _ children ->
            if name == "p" then
                Just <| ( element definition [] Set.empty, children )

            else
                Nothing

        _ ->
            Nothing


blockquote : NodeDefinition
blockquote =
    nodeDefinition "blockquote" "block" (blockNode [ "block" ]) blockquoteToHtml htmlToBlockquote


blockquoteToHtml : ElementToHtml
blockquoteToHtml =
    defaultElementToHtml "blockquote"


htmlToBlockquote : HtmlToElement
htmlToBlockquote =
    defaultHtmlToElement "blockquote"


horizontalRule : NodeDefinition
horizontalRule =
    nodeDefinition "horizontal_rule" "block" blockLeaf horizontalRuleToHtml htmlToHorizontalRule


horizontalRuleToHtml : ElementToHtml
horizontalRuleToHtml =
    defaultElementToHtml "hr"


htmlToHorizontalRule : HtmlToElement
htmlToHorizontalRule def node =
    case node of
        ElementNode name _ _ ->
            if name == "hr" then
                Just ( element def [] <| Set.fromList [ selectable ], Array.empty )

            else
                Nothing

        _ ->
            Nothing


heading : NodeDefinition
heading =
    nodeDefinition "heading" "block" (textBlock [ "inline" ]) headingToHtml htmlToHeading


headingToHtml : ElementToHtml
headingToHtml parameters children =
    let
        level =
            Maybe.withDefault 1 <| findIntegerAttribute "level" (attributes parameters)
    in
    ElementNode ("h" ++ String.fromInt level) [] children


htmlToHeading : HtmlToElement
htmlToHeading def node =
    case node of
        ElementNode name _ children ->
            let
                maybeLevel =
                    case name of
                        "h1" ->
                            Just 1

                        "h2" ->
                            Just 2

                        "h3" ->
                            Just 3

                        "h4" ->
                            Just 4

                        "h5" ->
                            Just 5

                        "h6" ->
                            Just 6

                        _ ->
                            Nothing
            in
            case maybeLevel of
                Nothing ->
                    Nothing

                Just level ->
                    Just <|
                        ( element def
                            [ IntegerAttribute "level" level ]
                            Set.empty
                        , children
                        )

        _ ->
            Nothing


codeBlock : NodeDefinition
codeBlock =
    nodeDefinition
        "code_block"
        "block"
        (textBlock [ "text", "hard_break" ])
        codeBlockToHtmlNode
        htmlNodeToCodeBlock


codeBlockToHtmlNode : ElementToHtml
codeBlockToHtmlNode _ children =
    ElementNode "pre"
        []
        (Array.fromList [ ElementNode "code" [] children ])


htmlNodeToCodeBlock : HtmlToElement
htmlNodeToCodeBlock def node =
    case node of
        ElementNode name _ children ->
            if name == "pre" && Array.length children == 1 then
                case Array.get 0 children of
                    Nothing ->
                        Nothing

                    Just n ->
                        case n of
                            ElementNode _ _ childChildren ->
                                Just ( element def [] Set.empty, childChildren )

                            _ ->
                                Nothing

            else
                Nothing

        _ ->
            Nothing


image : NodeDefinition
image =
    nodeDefinition "image" "inline" inlineLeaf imageToHtmlNode htmlNodeToImage


imageToHtmlNode : ElementToHtml
imageToHtmlNode parameters _ =
    let
        attr =
            filterAttributesToHtml
                [ ( "src", Just <| Maybe.withDefault "" (findStringAttribute "src" (attributes parameters)) )
                , ( "alt", findStringAttribute "alt" (attributes parameters) )
                , ( "title", findStringAttribute "title" (attributes parameters) )
                ]
    in
    ElementNode "img"
        attr
        Array.empty


htmlNodeToImage : HtmlToElement
htmlNodeToImage def node =
    case node of
        ElementNode name attributes _ ->
            if name == "img" then
                let
                    elementNodeAttributes =
                        List.filterMap
                            (\( k, v ) ->
                                case k of
                                    "src" ->
                                        Just <| StringAttribute "src" v

                                    "alt" ->
                                        Just <| StringAttribute "alt" v

                                    "title" ->
                                        Just <| StringAttribute "title" v

                                    _ ->
                                        Nothing
                            )
                            attributes
                in
                if findStringAttribute "src" elementNodeAttributes /= Nothing then
                    Just
                        ( element
                            def
                            elementNodeAttributes
                          <|
                            Set.fromList [ selectable ]
                        , Array.empty
                        )

                else
                    Nothing

            else
                Nothing

        _ ->
            Nothing


hardBreak : NodeDefinition
hardBreak =
    nodeDefinition "hard_break" "inline" inlineLeaf hardBreakToHtml htmlToHardBreak


hardBreakToHtml : ElementToHtml
hardBreakToHtml =
    defaultElementToHtml "br"


htmlToHardBreak : HtmlToElement
htmlToHardBreak =
    defaultHtmlToElement "br"


filterAttributesToHtml : List ( String, Maybe String ) -> List ( String, String )
filterAttributesToHtml attrs =
    List.filterMap
        (\( p, v ) ->
            case v of
                Nothing ->
                    Nothing

                Just tv ->
                    Just ( p, tv )
        )
        attrs



--- List node definitions


orderedList : NodeDefinition
orderedList =
    nodeDefinition
        "ordered_list"
        "block"
        (blockNode [ "list_item" ])
        orderedListToHtml
        htmlToOrderedList


orderedListToHtml : ElementToHtml
orderedListToHtml _ children =
    ElementNode "ol" [] children


htmlToOrderedList : HtmlToElement
htmlToOrderedList =
    defaultHtmlToElement "ol"


unorderedList : NodeDefinition
unorderedList =
    nodeDefinition
        "unordered_list"
        "block"
        (blockNode [ "list_item" ])
        unorderedListToHtml
        htmlToUnorderedList


unorderedListToHtml : ElementToHtml
unorderedListToHtml _ children =
    ElementNode "ul" [] children


htmlToUnorderedList : HtmlToElement
htmlToUnorderedList =
    defaultHtmlToElement "ul"


listItem : NodeDefinition
listItem =
    nodeDefinition
        "list_item"
        "list_item"
        (blockNode [ "block" ])
        listItemToHtml
        htmlToListItem


listItemToHtml : ElementToHtml
listItemToHtml _ children =
    ElementNode "li" [] children


htmlToListItem : HtmlToElement
htmlToListItem =
    defaultHtmlToElement "li"



-- Mark definitions


link : MarkDefinition
link =
    markDefinition "link" linkToHtmlNode htmlNodeToLink


linkToHtmlNode : MarkToHtml
linkToHtmlNode mark children =
    let
        attributes =
            filterAttributesToHtml
                [ ( "href", Just <| Maybe.withDefault "" (findStringAttribute "href" (Mark.attributes mark)) )
                , ( "title", findStringAttribute "title" (Mark.attributes mark) )
                ]
    in
    ElementNode "a"
        attributes
        children


htmlNodeToLink : HtmlToMark
htmlNodeToLink def node =
    case node of
        ElementNode name attributes children ->
            if name == "a" then
                let
                    elementNodeAttributes =
                        List.filterMap
                            (\( k, v ) ->
                                case k of
                                    "href" ->
                                        Just <| StringAttribute "src" v

                                    "title" ->
                                        Just <| StringAttribute "title" v

                                    _ ->
                                        Nothing
                            )
                            attributes
                in
                if findStringAttribute "href" elementNodeAttributes /= Nothing then
                    Just
                        ( mark
                            def
                            elementNodeAttributes
                        , children
                        )

                else
                    Nothing

            else
                Nothing

        _ ->
            Nothing


bold : MarkDefinition
bold =
    markDefinition "bold" boldToHtmlNode htmlNodeToBold


boldToHtmlNode : MarkToHtml
boldToHtmlNode _ children =
    ElementNode "b" [] children


htmlNodeToBold : HtmlToMark
htmlNodeToBold =
    defaultHtmlToMark "b"


italic : MarkDefinition
italic =
    markDefinition "italic" italicToHtmlNode htmlNodeToItalic


italicToHtmlNode : MarkToHtml
italicToHtmlNode _ children =
    ElementNode "i" [] children


htmlNodeToItalic : HtmlToMark
htmlNodeToItalic =
    defaultHtmlToMark "i"


code : MarkDefinition
code =
    markDefinition "code" codeToHtmlNode htmlNodeToCode


codeToHtmlNode : MarkToHtml
codeToHtmlNode _ children =
    ElementNode "code" [] children


htmlNodeToCode : HtmlToMark
htmlNodeToCode =
    defaultHtmlToMark "code"


markdown : Spec
markdown =
    emptySpec
        |> withNodeDefinitions
            [ doc
            , paragraph
            , blockquote
            , horizontalRule
            , heading
            , codeBlock
            , image
            , hardBreak
            , unorderedList
            , orderedList
            , listItem
            ]
        |> withMarkDefinitions
            [ link
            , bold
            , italic
            , code
            ]