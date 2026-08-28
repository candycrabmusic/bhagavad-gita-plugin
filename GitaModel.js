.pragma library

var _data = null
var _chapters = []
var _totalVerses = 0

function setData(jsonText) {
  if (_data) return
  _data = JSON.parse(jsonText)
  _chapters = _data.chapters || []
  _totalVerses = 0
  for (var i = 0; i < _chapters.length; i++)
    _totalVerses += _chapters[i].verses.length
}

function isLoaded() { return _data !== null }

function totalChapters() { return _chapters.length }

function totalVerses() { return _totalVerses }

function getChapter(num) {
  if (num < 1 || num > _chapters.length) return null
  return _chapters[num - 1]
}

function getVerse(chapter, verse) {
  var ch = getChapter(chapter)
  if (!ch) return null
  for (var i = 0; i < ch.verses.length; i++) {
    if (ch.verses[i].number === verse) return ch.verses[i]
  }
  return null
}

function verseCount(chapter) {
  var ch = getChapter(chapter)
  return ch ? ch.verseCount : 0
}

function nextVerse(chapter, verse) {
  var ch = getChapter(chapter)
  if (!ch) return { chapter: 1, verse: 1 }
  for (var i = 0; i < ch.verses.length; i++) {
    if (ch.verses[i].number === verse) {
      if (i < ch.verses.length - 1)
        return { chapter: chapter, verse: ch.verses[i + 1].number }
      else if (chapter < _chapters.length)
        return { chapter: chapter + 1, verse: _chapters[chapter].verses[0].number }
      else
        return { chapter: 1, verse: _chapters[0].verses[0].number }
    }
  }
  return { chapter: chapter, verse: verse }
}

function prevVerse(chapter, verse) {
  var ch = getChapter(chapter)
  if (!ch) return { chapter: 1, verse: 1 }
  for (var i = 0; i < ch.verses.length; i++) {
    if (ch.verses[i].number === verse) {
      if (i > 0)
        return { chapter: chapter, verse: ch.verses[i - 1].number }
      else if (chapter > 1)
        return { chapter: chapter - 1, verse: _chapters[chapter - 2].verses[_chapters[chapter - 2].verses.length - 1].number }
      else
        return { chapter: _chapters.length, verse: _chapters[_chapters.length - 1].verses[_chapters[_chapters.length - 1].verses.length - 1].number }
    }
  }
  return { chapter: chapter, verse: verse }
}

function randomVerse() {
  var chIdx = Math.floor(Math.random() * _chapters.length)
  var ch = _chapters[chIdx]
  var vIdx = Math.floor(Math.random() * ch.verses.length)
  return { chapter: ch.number, verse: ch.verses[vIdx].number }
}

function dailyVerse(date) {
  var d = date || new Date()
  var seed = d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate()
  var idx = seed % _totalVerses
  var count = 0
  for (var i = 0; i < _chapters.length; i++) {
    var ch = _chapters[i]
    if (count + ch.verses.length > idx)
      return { chapter: ch.number, verse: ch.verses[idx - count].number }
    count += ch.verses.length
  }
  return { chapter: 1, verse: 1 }
}

function search(query) {
  if (!query || query.length < 2) return []
  var q = query.toLowerCase()
  var results = []
  for (var i = 0; i < _chapters.length; i++) {
    var ch = _chapters[i]
    for (var j = 0; j < ch.verses.length; j++) {
      var v = ch.verses[j]
      if ((v.sanskrit && v.sanskrit.toLowerCase().indexOf(q) >= 0) ||
          (v.transliteration && v.transliteration.toLowerCase().indexOf(q) >= 0) ||
          (v.translation && v.translation.toLowerCase().indexOf(q) >= 0) ||
          (ch.englishName && ch.englishName.toLowerCase().indexOf(q) >= 0) ||
          (ch.name && ch.name.indexOf(query) >= 0)) {
        results.push({ chapter: ch.number, verse: v.number, verseData: v, chapterName: ch.englishName })
      }
    }
  }
  return results
}
