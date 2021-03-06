chars_regex = VER::Keyboard::PRINTABLE_REGEX

VER.let :general_movement do
  # Movement
  map('up'){ go_line_up }
  map('down'){ go_line_down }
  map('left'){ go_char_left }
  map('right'){ go_char_right }
end

VER.let :general => :general_movement do
  map(/^(C-f|npage)$/){ page_down }
  map(/^(C-b|ppage)$/){ page_up }

  # Function keys

  map('F1'){ VER.help }
  map('F2'){ VER.doc(/ver/) }

  # seems to be triggered only on events, not the actual resize
  map(/^(C-l|resize)$/){ VER::View.resize }

  # Switching buffers real fast
  map(/^M-(\d)$/){ switch_to_buffer_number(@arg) }
  map('C-^'){ switch_to_previous_buffer }
end

VER.let :control_movement => :general_movement do
  map('0'){ go_beginning_of_line }
  map('$'){ go_end_of_line }

  map('w'){ go_word_right } # jump_right(/[\w-]+/) }
  map('b'){ go_word_left } # jump_left(/[^\w-]+/) }
  map('W'){ go_chunk_right } # jump_right(/\S+/) }
  map('B'){ go_chunk_left } # jump_left(/\s+/) }

  macro('h',       'left')
  macro('j',       'down')
  macro('k',       'up')
  macro('l',       'right')
  macro('home',    '0')
  macro('end',     '$')
  macro('C-right', 'W')
  macro('C-left',  'B')

  # optimized countmaps for basic movement
  count_map(7, /^down|j$/){ @count.times{ cursor.down } }
  count_map(7, /^up|k$/){ @count.times{ cursor.up } }
  count_map(7, /^left|h$/){ @count.times{ cursor.left } }
  count_map(7, /^right|l$/){ @count.times{ cursor.right } }

  count_map(7, /^[wbWB]$/){ press(@trigger, @count) }
end

VER.let :control => [:general, :control_movement] do
  map(/^q (#{chars_regex})$/){ start_macro(@arg) }
  map(/^q (#{chars_regex})$/){ play_macro(@arg) }

  map('C-g'){ VER::View::AskGrep.open }
  map('C-o'){ VER::View::AskFile.open }
  map('C-q'){ VER.stop }
  map('C-s'){ VER.info("Saved to: #{buffer.save_file}") }
  map('M-s'){ save_as_ask }
  map('C-w'){ buffer_close }
  map('C-x'){ execute_ask }

  map('M-b'){ buffer_ask }
  map('M-o'){ VER::View::AskFuzzyFile.open }

  map('G'){
    cursor.pos = buffer.size - 1
    cursor.beginning_of_line
  }

  # TODO: should take other mode as list of mappings after prefix key
  movement = /^(up|down|left|right|[0wbWBhjkl$])$/
  map(['d', movement]){
    cursor.virtual{
      start_selection
      press(@arg)
      VER.clipboard.copy cut
    }
  }
  map(['c', movement]){
    press 'd'
    press @arg
    press 'i'
  }

  count_map(7, 'g'){ goto_line(@count) }
  count_map(2, '%'){ goto_percent(@count) }

  map(/^(x|dc)$/){ VER.clipboard.copy cursor.delete_right }
  map('X'){        VER.clipboard.copy cursor.delete_left }

  map(['r', /^[[:print:]]$/]){ cursor.replace(@arg) }
  map(['r', 'return']){ cursor.replace("\n") }

  map('~'){ toggle_case }

  map('>'){ indent_line }
  map('<'){ unindent_line }

  map('v'){   start_selection }
  map('V'){   start_selection(:linewise) }
  map('C-v'){ start_selection(:block) }

  map('Y'){ press('V'); copy }
  map(['y', movement]){ press('v'); press(@arg); press('y') }

  map('p'){ paste_after }
  map('P'){ paste_before }

  map('/'){ search_ask }
  map('n'){ search_next }
  map('N'){ search_previous }
  map('*'){ search_word }

  map('i'){ view.mode = :insert }
  map('I'){ cursor.beginning_of_line; view.mode = :insert }

  map('!'){ press('V'); filter_selection_ask }

  map('u'){ undo }
  map('C-r'){ self.redo }

  map('C-e'){ eval_current_line }

  map('C-n'){ open_new_file }

  macro('a', 'l i')
  macro('A', '$ i')
  macro('o', '$ i return')
  macro('O', '0 i return up')
  macro('D', 'd $')
  macro('C', 'd $ i')
  macro('y y', 'Y')
  macro('d d', '0 d $')
  macro('g g', '1 g')
end

VER.let :selection => :control do
  map('v'){   selection[:selecting] = nil }
  map('V'){   selection[:selecting] = :linewise }
  map('C-v'){ selection[:selecting] = :block }

  map(/^[dxX]$/){ cut }
  map('y'){ copy }
  map('Y'){ press('V'); press('y') }
  map(/^(C-c|C-q|esc)$/){ view.selection = nil }

  map('~'){ toggle_selection_case }
  map('>'){ indent_selection }
  map('<'){ unindent_selection }
  map('!'){ filter_selection_ask }
  map('C-e'){ eval_selection }
end

VER.let :insert => :general do
  map(/^(#{chars_regex})$/){ insert(@arg) }
  map('backspace'){ VER.clipboard.copy cursor.delete_left }
  map('dc'){        VER.clipboard.copy cursor.delete_right }
  map('return'){    insert_newline; auto_indent }
  map('space'){     insert(' ') }
  map(/^(C-c|C-q|esc)$/){    view.mode = :control }

  map('C-e'){ eval_current_line }

  # should be smart and stick to last chosen completion
  map('tab'){ complete }
end

VER.let :ask => [:insert, :general_movement] do
  map('backspace'){ cursor.delete_left }
  map('dc'){ cursor.delete_right }
  map('return'){ pick }
  map('tab'){ view.update_choices; view.try_completion }
  map('up'){ history_backward }
  map('down'){ history_forward }
  map(/^(C-g|C-q|C-c|esc)$/){ view.close }
end

VER.let :ask_choice => [:insert, :general_movement] do
  map('backspace'){ cursor.delete_left }
  map('dc'){ cursor.delete_right }
  map(/^(C-g|C-q|C-c|esc)$/){ view.close }
  map('return'){ pick }
end

VER.let :ask_large => :ask do
  map('up'){   view.select_above }
  map('down'){ view.select_below }
  map('tab'){  view.expand_input }

  after(/^(#{chars_regex})$/, 'backspace', 'space', 'dc'){ view.update_choices }
end

VER.let :ask_file => :ask_large
VER.let :ask_fuzzy_file => :ask_large
VER.let :ask_grep => :ask_large
VER.let :ask_doc => :ask_large

VER.let :complete => :ask_large do
  map(/^C-(p|k)$/){ select_above }
  map(/^C-(n|j)$/){ select_below }
  map('tab'){ select_below }

  map(/^(C-g|C-q|C-c|esc|left|right)$/){
    view.close
  }
end

completions = {
  'C-w' => :word,
  'C-l' => :line,
  'C-o' => :omni,
  'C-f' => :file,
  'C-s' => :spell,
}

completions.each do |key, value|
  VER.let(:insert){
    map(['C-x', key]){ complete(value) }
  }
  VER.let("complete_#{value}".to_sym => :complete){
    map(['C-x', key]){ select_below }
  }
end
