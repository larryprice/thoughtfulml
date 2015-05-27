require 'spec_helper'
require 'stringio'

describe POSTagger do
  let(:stream) { "A/B C/D C/D A/D A/B ./." }

  let (:pos_tagger) {
    pos_tagger = POSTagger.new([StringIO.new(stream)])
    pos_tagger.train!
    pos_tagger
  }

  it 'calculates tag transition probablities' do
    pos_tagger.tag_probability("Z", "Z").must_equal 0

    pos_tagger.tag_probability("D", "D").must_equal Rational(2, 3)
    pos_tagger.tag_probability("START", "B").must_equal 1
    pos_tagger.tag_probability("B", "D").must_equal Rational(1, 2)
    pos_tagger.tag_probability(".", "D").must_equal 0
  end

  it 'calculates the probability of a word given a tag' do
    pos_tagger.word_tag_probability("Z", "Z").must_equal 0
    pos_tagger.word_tag_probability("A", "B").must_equal 1
    pos_tagger.word_tag_probability("A", "D").must_equal Rational(1,3)
    pos_tagger.word_tag_probability("START", "START").must_equal 1
    pos_tagger.word_tag_probability(".", ".").must_equal 1
  end

  it 'calculates probability of words and tags' do
    words = %w[START A C A A .]
    tags = %w[START B D D B .]
    tagger = pos_tagger

    tag_probabilities = [
      tagger.tag_probability("B", "D"),
      tagger.tag_probability("D", "D"),
      tagger.tag_probability("D", "B"),
      tagger.tag_probability("B", "."),
    ].reduce(&:*)

    word_probabilities = [
      tagger.word_tag_probability("A", "B"),
      tagger.word_tag_probability("C", "D"),
      tagger.word_tag_probability("A", "D"),
      tagger.word_tag_probability("A", "B"),
    ].reduce(&:*)

    expected = word_probabilities * tag_probabilities
    pos_tagger.probability_of_word_tag(words, tags).must_equal expected
  end

  describe 'viterbi' do
    let(:training) { "I/PRO want/V to/TO race/V ./. I/PRO like/V cats/N ./."}
    let(:sentence) { 'I want to race.' }
    let (:pos_tagger) {
      pos_tagger = POSTagger.new([StringIO.new(training)])
      pos_tagger.train!
      pos_tagger
    }

    it 'will calculate the best viterbi sequence for I want to race' do
      pos_tagger.viterbi(sentence).must_equal %w[START PRO V TO V .]
    end
  end
end
