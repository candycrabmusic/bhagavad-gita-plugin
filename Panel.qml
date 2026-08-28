import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui
import "GitaModel.js" as Gita

Panel {
  id: root
  moduleName: "vishakh.bhagavad-gita"
  ipcTarget: "vishakh.bhagavad-gita"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  property bool dataReady: false
  property int currentChapter: 2
  property int currentVerse: 47
  property var currentVerseData: null
  property string currentChapterName: ""

  property bool searchMode: false
  property string searchQuery: ""
  property var searchResults: []

  // Settings
  readonly property bool showSanskrit: setting("showSanskrit", true)
  readonly property bool showTransliteration: setting("showTransliteration", true)
  readonly property bool showTranslation: setting("showTranslation", true)

  // Bookmarks
  property var bookmarks: []
  property bool bookmarksLoaded: false
  property bool bookmarkMode: false

  function bookmarkKey(ch, v) { return ch + ":" + v }

  function isBookmarked() {
    var k = bookmarkKey(currentChapter, currentVerse)
    for (var i = 0; i < bookmarks.length; i++)
      if (bookmarks[i] === k) return true
    return false
  }

  function toggleBookmark() {
    var k = bookmarkKey(currentChapter, currentVerse)
    if (isBookmarked()) {
      var next = []
      for (var i = 0; i < bookmarks.length; i++)
        if (bookmarks[i] !== k) next.push(bookmarks[i])
      bookmarks = next
    } else {
      bookmarks.push(k)
      bookmarks = bookmarks.slice()
    }
    persistBookmarks()
  }

  function persistBookmarks() {
    bookmarkWriter.text = JSON.stringify(bookmarks)
  }

  FileView {
    id: bookmarkReader
    path: Color.stateHome + "/omarchy/plugins/vishakh.bhagavad-gita/bookmarks.json"
    onLoaded: {
      try { root.bookmarks = JSON.parse(text()) } catch(e) { root.bookmarks = [] }
      root.bookmarksLoaded = true
    }
    onLoadFailed: { root.bookmarks = []; root.bookmarksLoaded = true }
  }

  FileView {
    id: bookmarkWriter
    path: Color.stateHome + "/omarchy/plugins/vishakh.bhagavad-gita/bookmarks.json"
    onLoaded: {}
  }

  FileView {
    path: Qt.resolvedUrl("gita.json")
    onLoaded: {
      Gita.setData(text())
      root.dataReady = true
    }
  }

  function open() {
    if (dataReady) {
      var rv = Gita.randomVerse()
      currentChapter = rv.chapter
      currentVerse = rv.verse
      refreshVerse()
    }
    root.controller.show()
  }

  function close() {
    searchMode = false
    searchQuery = ""
    searchResults = []
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function refreshVerse() {
    currentVerseData = Gita.getVerse(currentChapter, currentVerse)
    var ch = Gita.getChapter(currentChapter)
    currentChapterName = ch ? ch.englishName : ""
  }

  function goNext() {
    if (!Gita.isLoaded()) return
    var next = Gita.nextVerse(currentChapter, currentVerse)
    currentChapter = next.chapter
    currentVerse = next.verse
    refreshVerse()
  }

  function goPrev() {
    if (!Gita.isLoaded()) return
    var prev = Gita.prevVerse(currentChapter, currentVerse)
    currentChapter = prev.chapter
    currentVerse = prev.verse
    refreshVerse()
  }

  function goRandom() {
    if (!Gita.isLoaded()) return
    var r = Gita.randomVerse()
    currentChapter = r.chapter
    currentVerse = r.verse
    refreshVerse()
  }

  function goNextChapter() {
    if (!Gita.isLoaded()) return
    if (currentChapter < Gita.totalChapters()) {
      currentChapter++
      currentVerse = Gita.getChapter(currentChapter).verses[0].number
      refreshVerse()
    }
  }

  function goPrevChapter() {
    if (!Gita.isLoaded()) return
    if (currentChapter > 1) {
      currentChapter--
      currentVerse = Gita.getChapter(currentChapter).verses[0].number
      refreshVerse()
    }
  }

  function goToVerse(ch, v) {
    currentChapter = ch
    currentVerse = v
    searchMode = false
    searchQuery = ""
    searchResults = []
    refreshVerse()
  }

  function performSearch() {
    if (searchQuery.length < 2) { searchResults = []; return }
    searchResults = Gita.search(searchQuery)
  }

  function exitSearch() {
    searchMode = false
    searchQuery = ""
    searchResults = []
    Qt.callLater(function() { if (keyCatcher) keyCatcher.forceActiveFocus() })
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(520))
    contentHeight: panel.fittedContentHeight(searchMode ? searchColumn.implicitHeight : verseColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onMoveRequested: function(dx, dy) {
        if (root.searchMode) return
        if (dx > 0) root.goNext()
        else if (dx < 0) root.goPrev()
        else if (dy > 0) root.goNextChapter()
        else if (dy < 0) root.goPrevChapter()
      }
      onTextKey: function(t) {
        if (root.searchMode) {
          if (t === "\x1b") root.exitSearch()
          return
        }
        if (t === "r" || t === "R") root.goRandom()
        else if (t === "j") root.goNextChapter()
        else if (t === "k") root.goPrevChapter()
        else if (t === "b" || t === "B") root.toggleBookmark()
        else if (t === "/" || t === "s" || t === "S") {
          root.searchMode = true
          searchField.text = ""
          Qt.callLater(function() { searchField.forceActiveFocus() })
        }
      }

      // --- Search mode ---
      Column {
        id: searchColumn
        visible: root.searchMode
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        spacing: Style.space(12)

        Text {
          width: parent.width
          text: "Search Bhagavad Gita"
          color: root.contentForeground
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.body
          font.bold: true
        }

        Rectangle {
          width: parent.width
          height: Style.space(32)
          radius: Style.cornerRadius
          color: "transparent"
          border.width: 1
          border.color: Qt.darker(root.contentForeground, 1.5)

          TextInput {
            id: searchField
            anchors.fill: parent
            anchors.margins: Style.space(8)
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.body
            clip: true
            focus: root.searchMode

            onTextChanged: {
              root.searchQuery = text
              root.performSearch()
            }

            Keys.onEscapePressed: root.exitSearch()
          }
        }

        Text {
          width: parent.width
          text: root.searchResults.length + " results"
          color: Qt.darker(root.contentForeground, 1.6)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.caption
        }

        Rectangle {
          width: parent.width
          height: Style.spacing.hairline
          color: root.contentForeground
          opacity: 0.15
        }

        Repeater {
          model: Math.min(root.searchResults.length, 30)

          Rectangle {
            required property int index
            width: searchColumn.width
            height: resultRow.implicitHeight + Style.space(12)
            radius: Style.cornerRadius
            color: resultMouse.containsMouse
              ? Style.hoverFillFor(root.contentForeground, Color.accent)
              : "transparent"

            Row {
              id: resultRow
              anchors.fill: parent
              anchors.margins: Style.space(6)
              spacing: Style.space(12)

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                  var r = root.searchResults[index]
                  return r.chapter + ":" + r.verse
                }
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                width: Style.space(50)
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Style.space(50)
                text: {
                  var r = root.searchResults[index]
                  var t = r.verseData.translation || ""
                  return t.length > 100 ? t.substring(0, 100) + "..." : t
                }
                color: Qt.darker(root.contentForeground, 1.3)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
              }
            }

            MouseArea {
              id: resultMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                var r = root.searchResults[index]
                root.goToVerse(r.chapter, r.verse)
              }
            }
          }
        }
      }

      // --- Verse display mode ---
      Flickable {
        id: verseFlick
        visible: !root.searchMode
        anchors.fill: parent
        contentWidth: verseColumn.width
        contentHeight: verseColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
          id: verseColumn
          width: keyCatcher.width
          spacing: Style.space(16)

          // Header
          Item {
            width: parent.width
            height: headerCol.implicitHeight

            Column {
              id: headerCol
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(4)

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "\u092D\u0917\u0935\u0926\u094D\u0917\u0940\u0924\u093E"
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.title
                font.bold: true
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Bhagavad Gita"
                color: Qt.darker(root.contentForeground, 1.4)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                font.letterSpacing: 1
              }
            }
          }

          Rectangle { width: parent.width; height: Style.spacing.hairline; color: root.contentForeground; opacity: 0.15 }

          // Chapter / Verse + chapter name + bookmark
          Item {
            width: parent.width
            height: verseInfoCol.implicitHeight

            Column {
              id: verseInfoCol
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(2)

              Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Style.space(6)

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "Chapter " + root.currentChapter + " \u00B7 Verse " + root.currentVerse
                  color: Qt.darker(root.contentForeground, 1.5)
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.letterSpacing: 1
                }

                Text {
                  visible: root.isBookmarked()
                  anchors.verticalCenter: parent.verticalCenter
                  text: "\u2605"
                  color: Color.accent
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.bodySmall
                }
              }

              Text {
                visible: root.currentChapterName !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.currentChapterName
                color: Qt.darker(root.contentForeground, 1.7)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                font.italic: true
              }
            }
          }

          // Sanskrit
          Text {
            visible: root.currentVerseData !== null && root.showSanskrit
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.currentVerseData ? root.currentVerseData.sanskrit : ""
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.heading
            lineHeight: 1.4
          }

          // Transliteration
          Text {
            visible: root.currentVerseData !== null && root.showTransliteration
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.currentVerseData ? root.currentVerseData.transliteration : ""
            color: Qt.darker(root.contentForeground, 1.6)
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.body
            font.italic: true
            lineHeight: 1.3
          }

          // Translation
          Text {
            visible: root.currentVerseData !== null && root.showTranslation
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.currentVerseData ? root.currentVerseData.translation : ""
            color: Qt.darker(root.contentForeground, 1.3)
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.body
            lineHeight: 1.4
          }

          Rectangle { width: parent.width; height: Style.spacing.hairline; color: root.contentForeground; opacity: 0.15 }

          // Navigation
          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(20)

            Rectangle {
              width: prevL.implicitWidth + Style.space(16)
              height: Style.space(28)
              radius: Style.cornerRadius
              color: prevM.containsMouse ? Style.hoverFillFor(root.contentForeground, Color.accent) : "transparent"
              Text {
                id: prevL; anchors.centerIn: parent
                text: "\u2190 Prev"
                color: prevM.containsMouse ? Style.hoverStateColor(root.contentForeground, Color.accent) : Qt.darker(root.contentForeground, 1.4)
                font.family: root.contentFontFamily; font.pixelSize: Style.font.caption
              }
              MouseArea { id: prevM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.goPrev() }
            }

            Rectangle {
              width: randL.implicitWidth + Style.space(16)
              height: Style.space(28)
              radius: Style.cornerRadius
              color: randM.containsMouse ? Style.hoverFillFor(root.contentForeground, Color.accent) : "transparent"
              Text {
                id: randL; anchors.centerIn: parent
                text: "\u{1F3B2} Random"
                color: randM.containsMouse ? Style.hoverStateColor(root.contentForeground, Color.accent) : Qt.darker(root.contentForeground, 1.4)
                font.family: root.contentFontFamily; font.pixelSize: Style.font.caption
              }
              MouseArea { id: randM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.goRandom() }
            }

            Rectangle {
              width: nextL.implicitWidth + Style.space(16)
              height: Style.space(28)
              radius: Style.cornerRadius
              color: nextM.containsMouse ? Style.hoverFillFor(root.contentForeground, Color.accent) : "transparent"
              Text {
                id: nextL; anchors.centerIn: parent
                text: "Next \u2192"
                color: nextM.containsMouse ? Style.hoverStateColor(root.contentForeground, Color.accent) : Qt.darker(root.contentForeground, 1.4)
                font.family: root.contentFontFamily; font.pixelSize: Style.font.caption
              }
              MouseArea { id: nextM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.goNext() }
            }
          }

          // Search hint
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Press / to search"
            color: Qt.darker(root.contentForeground, 1.8)
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }
}
