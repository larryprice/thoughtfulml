class POSTagger
  def initialize(data_io = [])
    @corpus_parser = CorpusParser.new
    @data_io = data_io
    @trained = false
  end

  def train!
    unless @trained
      @tags = Set.new(["START"])
      @tag_combos = Hash.new(0)
      @tag_frequencies = Hash.new(0)
      @word_tag_combos = Hash.new(0)

      @data_io.each do |io|
        io.each_line do |line|
          @corpus_parser.parse(line) do |ngram|
            write(ngram)
          end
        end
      end
      @trained = true
    end
  end

  def write(ngram)
    if ngram.first.tag == 'START'
      @tag_frequencies['START'] += 1
      @word_tag_combos['START/START'] += 1
    end

    @tags << ngram.last.tag

    @tag_frequencies[ngram.last.tag] += 1
    @word_tag_combos[[ngram.last.word, ngram.last.tag].join("/")] += 1
    @tag_combos[[ngram.first.tag, ngram.last.tag].join("/")] += 1
  end

  def tag_probability(previous_tag, current_tag)
    p @tag_frequencies
    denom = @tag_frequencies[previous_tag]
    denom.zero? ? 0 : @tag_combos["#{previous_tag}/#{current_tag}"] / denom.to_f
  end

  def word_tag_probability(word, tag)
    denom = @tag_frequencies[tag]
    denom.zero? ? 0 : @word_tag_combos["#{word}/#{tag}"] / denom.to_f
  end

  def probability_of_word_tag(words, tags)
    raise 'The word and tags must be the same length!' unless words.length == tags.length

    probability = Rational(1,1)
    (1...words.length).each do |i|
      probability *= (tag_probability(tags[i-1], tags[i]) * word_tag_probability(words[i], tags[i]))
    end
    probability
  end

  def viterbi(sentence)
    parts = sentence.gsub(/[\.\?!]/) {|a| " #{a}" }.split(/\s+/)

    last_viterbi = {}
    backpointers = ["START"]

    @tags.each do |tag|
      next if tag == 'START'
      probability = tag_probability("START", tag) * word_tag_probability(parts.first, tag)
      last_viterbi[tag] = probability if probability > 0
    end
    backpointers << (last_viterbi.max_by {|k, v| v} || @tag_frequencies.max_by {|k, v| v }).first

    parts[1..-1].each do |part|
      viterbi = {}
      @tags.each do |tag|
        next if tag == "START"
        break if last_viterbi.empty?

        best_previous = last_viterbi.max_by do |prev_tag, probability|
          probability * tag_probability(prev_tag, tag) * word_tag_probability(part, tag)
        end
        best_tag = best_previous.first

        probability = last_viterbi[best_tag] * tag_probability(best_tag, tag) * word_tag_probability(part, tag)
        viterbi[tag] = probability if probability > 0
      end
      last_viterbi = viterbi
      backpointers << (last_viterbi.max_by {|k, v| v} || @tag_frequencies.max_by {|k, v| v }).first
    end
    backpointers
  end
end