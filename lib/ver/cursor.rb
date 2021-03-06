module VER
  class Cursor < Struct.new(:buffer, :pos, :mark, :color, :meta)
    def [](key, *keys)
      keys.empty? ? meta[key] : meta.values_at(key, *keys)
    end

    def []=(key, value)
      meta[key] = value
    end

    def ==(other)
      other.buffer == buffer &&
        other.pos == pos &&
        other.mark == mark
    end

    def beginning_of_line
      self.pos = bol
    end

    def end_of_line
      self.pos = eol
    end

    def eol(pos = pos)
      buffer.index(/\n/, pos..buffer.size) || buffer.size
    end

    def bol(pos = pos)
      max = [pos - 1, 0].max
      if pos = buffer.rindex(/\n/, 0..max)
        pos + 1
      else
        0
      end
    end

    def region(range)
      cursor = buffer.new_cursor(pos)
      cursor.pos, cursor.mark = range.begin, range.end
      yield(cursor)
    end

    def buffer_line
      buffer[0..pos].count(/\n/)
    end

    # go up one line
    def up
      return if pos == 0
      bol_pos = buffer.rindex(/\n/, 0..(pos - 1))
      return unless bol_pos

      indent = pos - (bol_pos + 1)

      # now we get the length of the previous line and try to fit inside
      prev_bol_pos = buffer.rindex(/\n/, 0..(bol_pos - 1))

      if prev_bol_pos
        if bol_pos - prev_bol_pos > indent
          self.pos = prev_bol_pos + indent + 1
        else
          self.pos = bol_pos
        end
      elsif bol_pos >= indent
        self.pos = indent
      else
        self.pos = bol_pos
      end
    end

    # go down one line
    def down
      eol_pos = buffer.index(/\n/, pos..buffer.size)
      return unless eol_pos

      if pos == 0 # first line
        bol_pos = 0
        indent = pos
      elsif bol_pos = buffer.rindex(/\n/, 0..(pos - 1))
        indent = pos - (bol_pos + 1)
      else # first line
        bol_pos = 0
        indent = pos
      end

      # now we get the length of the following line and try to fit inside
      next_eol_pos = buffer.index(/\n/, (eol_pos + 1)..buffer.size)

      return unless next_eol_pos

      # length of next line
      next_length = next_eol_pos - (eol_pos + 1)

      if next_length >= indent
        self.pos = eol_pos + indent + 1
      else
        self.pos = eol_pos + next_length + 1
      end
    end

    def left(boundary = 0)
      self.pos -= 1
      self.pos = boundary if pos < boundary
    end

    def right
      self.pos += 1 if pos < (buffer.size - 1)
    end

    # TODO:
    #   * should take linewrap into account?
    #   * needs up to three matches, might be possible with only 2
    def to_pos(from_mark = false)
      return to_y(from_mark), to_x(from_mark)
    end

    def to_y(from_mark = false)
      max = from_mark ? mark : pos
      y = buffer[0...max].count("\n")
    rescue RangeError
      return 0
    end

    def to_x(from_mark = false)
      max = from_mark ? mark : pos

      bol = buffer.rindex(/\n/, 0...max)
      eol = buffer.index(/\n/, max..buffer.size)

      if not bol and not eol # only one line
        x = max
      elsif not bol # first line
        x = max
      elsif bol == eol # on newline
        if bol = buffer.rindex(/\n/, 0...pos)
          x = max - (bol + 1)
        else
          x = max
        end
      else
        x = max - (bol + 1)
      end

      return x
    rescue RangeError
      return 0
    end

    def to_s
      buffer[to_range]
    end

    def to_range
      [pos, mark].min..[pos, mark].max
    end

    def delta
      [pos, mark].max - [pos, mark].min
    end

    def insert(string)
      buffer.insert(pos, string)
      self.pos += string.size
    end

    def insert_newline
      insert("\n")
    end

    def delete_left
      return if pos == 0 or pos - 1 < 0

      self.pos -= 1
      deleted = buffer[pos, 1]
      buffer[pos, 1] = ''
      return deleted
    end

    def delete_right
      deleted = buffer[pos, 1]
      buffer[pos, 1] = ''
      return deleted
    end

    def replace(string)
      deleted = buffer[pos, string.size]
      buffer[pos, string.size] = string
      return deleted
    end

    def delete_range
      range = to_range
      range = (range.begin...range.end)

      deleted = buffer[range]
      buffer[range] = ''
      return deleted
    end

    def virtual
      old = clone
      self.mark = pos
      yield
      self.pos, self.mark = old.pos, old.mark
    end

    def invert
      clone.invert!
    end

    def invert!
      self.mark, self.pos = pos, mark
      self
    end

    def pos=(n)
      super(n > 0 ? (b = buffer.size; n < b ? n : b) : 0)
    end

    def mark=(n)
      super(n > 0 ? (b = buffer.size; n < b ? n : b) : 0)
    end

    def normalize
      from, to = [pos, mark].sort
      yield(from..to)
    end

    def rindex(pattern)
      normalize{|range| buffer.rindex(pattern, range) }
    end

    def index(pattern)
      normalize{|range| buffer.index(pattern, range) }
    end
    alias find index

    WORD = /[A-Za-z0-9'_-]+/
    LEFT_CHUNK = /#{WORD}\z/
    RIGHT_CHUNK = /\A#{WORD}/

    # FIXME:
    #   * use index/rindex?
    #   * assume default range, all the buffer is way too large
    def current_word(left_chunk = LEFT_CHUNK, right_chunk = RIGHT_CHUNK)
      left, right = buffer[0...pos], buffer[pos..-1]
      left_match, right_match = left[left_chunk], right[right_chunk]

      if left_match and right_match
        word = left_match + right_match
        range = (pos - left_match.size)...(pos + right_match.size)
      elsif word = left_match
        range = (pos - word.size)...pos
      elsif word = right_match
        range = pos...(pos + word.size)
      end

      return word, range if word
    end

    def current_line
      buffer[bol..eol]
    end

    # this is a faster version of
    #   [min, want, max].sort[1]
    # even when taking in account the method dispatch it's still a speedup
    def boundary_sort(min, want, max)
      want > min ? (want < max ? want : max) : min
    end
  end
end
