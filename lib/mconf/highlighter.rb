# This file is part of Mconf-Web, a web applition that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2016 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

module Mconf::Highlighter
  def self.highlight_word(text, word)
    return "" if text.blank?
    return text if word.blank?

    indexes = get_highlight_indexes(text, word)
    set_highlight_on_indexes(text, indexes)
  end

  def self.highlight(text, words)
    if words.kind_of?(Array)
      indexes = []
      words.each do |word|
        indexes.concat get_highlight_indexes(text, word)
      end
      set_highlight_on_indexes(text, indexes.sort{ |a,b| a[0] <=> b[0] })
    else
      highlight_word(text, words)
    end
  end

  private

  # Returns a list of arrays, each with the [0] position that the mark should
  # begin and [1] the length of the word being highlighted.
  def self.get_highlight_indexes(text, word)
    return [] if text.blank?
    return [] if word.blank?

    text = text.clone
    indexes = []
    tt = ActiveSupport::Inflector.transliterate(text).downcase
    tw = ActiveSupport::Inflector.transliterate(word).downcase
    overall_i = 0

    while tt && i = tt.index(/#{tw}/)
      if i
        overall_i += i
        indexes << [overall_i, tw.length]
        tt = tt[i + tw.length, tt.length - tw.length - i]
        overall_i += tw.length
      end
    end

    indexes
  end

  def self.set_highlight_on_indexes(text, indexes)
    text = text.clone
    begin_mark = "<mark>"
    end_mark = "</mark>"

    displacement = 0
    indexes.each do |index_pair|
      i = index_pair[0]
      word_length = index_pair[1]
      text.insert(i + displacement, begin_mark)
      displacement += begin_mark.length
      text.insert((i + word_length + displacement), end_mark)
      displacement += end_mark.length
    end

    #The following block splits the resulting text to make it
    #possible to escape the user input and keep the marks we
    #just added as html - the resulting text is html_safe and
    #will produce the expected marked text when we search and
    #highlight text on Manage > Spaces.
    result = ""
    textsplit = text.split(/<\/?mark>/)
    textsplit.map.with_index do |splits, i|
      result += ERB::Util.html_escape(splits)
      if i%2 == 0
        result += begin_mark if i != textsplit.size-1
      else
        result += end_mark
      end
    end

    result.html_safe

  end
end
