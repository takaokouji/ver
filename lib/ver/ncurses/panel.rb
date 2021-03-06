module VER
  module Ncurses
    class Panel < Struct.new(:pointer)
      extend FFI::Library

      # use RUBY_FFI_NCURSES_LIB to specify exactly which lib you want, e.g.
      # ncursesw, XCurses (from PDCurses)
      if ENV["RUBY_FFI_PANEL_LIB"].to_s != ""
        LIB_HANDLE = ffi_lib( ENV["RUBY_FFI_PANEL_LIB"] ).first
      else
        LIB_HANDLE = ffi_lib( 'panel', 'libpanelw.so.5' ).first
      end

      functions = [
        [:new_panel,         [:pointer],             :pointer],
        [:bottom_panel,      [:pointer],             :int],
        [:top_panel,         [:pointer],             :int],
        [:show_panel,        [:pointer],             :int],
        [:update_panels,     [],                     :void],
        [:hide_panel,        [:pointer],             :int],
        [:panel_window,      [:pointer],             :pointer],
        [:replace_panel,     [:pointer, :pointer],   :int],
        [:move_panel,        [:pointer, :int, :int], :int],
        [:panel_hidden,      [:pointer],             :int],
        [:panel_above,       [:pointer],             :pointer],
        [:panel_below,       [:pointer],             :pointer],
        [:set_panel_userptr, [:pointer, :pointer],   :int],
        [:panel_userptr,     [:pointer],             :pointer],
        [:del_panel,         [:pointer],             :int],
      ]

      functions.each do |function|
        attach_function(*function)
      end

      def initialize(window)
        if window.respond_to?(:pointer)
          self.pointer = Panel.new_panel(window.pointer)
        else
          self.pointer = Panel.new_panel(window)
        end
      end

      # Puts panel below all other panels.
      def bottom_panel
        Panel.bottom_panel(pointer)
      end
      alias bottom bottom_panel

      # Put the visible panel on top of all other panels in the stack.
      #
      # To ensure compatibility across platforms, use this method instead of
      # {show_panel} when the panel is shown.
      def top_panel
        Panel.top_panel(pointer)
      end
      alias top top_panel

      # Makes hidden panel visible by placing it on the top of the stack.
      #
      # To ensure compatibility across platforms, use this method instead of
      # {top_panel} when the panel is hidden.
      def show_panel
        Panel.show_panel(pointer)
      end
      alias show show_panel

      # Removes the given panel from the panel stack and thus hides it from
      # view.
      # The PANEL structure is not lost, merely removed from the stack.
      def hide_panel
        Panel.hide_panel(pointer)
      end
      alias hide hide_panel

      # Returns a pointer to the window of the given panel.
      def panel_window
        Panel.panel_window(pointer)
      end
      alias window panel_window

      # Replace the window of the panel with the given window.
      # Useful, for example, if you want to resize a panel.
      # You can call {replace_panel} on the output of {wresize}.
      # It does not change the position of the panel in the stack.
      def replace_panel(window)
        Panel.replace_panel(pointer, window)
      end
      alias replace replace_panel

      # Move the panel window so that its upper-left corner is at
      # (+starty+,+startx+).
      # It does not change the position of the panel in the stack.
      # Be sure to use this method instead of {mvwin}, to move a panel window.
      def move_panel(starty = 0, startx = 0)
        Panel.move_panel(pointer, starty, startx)
      end
      alias move move_panel

      # Returns true if the panel is in the panel stack, false if not.
      # Returns ERR if the panel pointer is a null pointer.
      def panel_hidden
        Panel.panel_hidden(pointer) == 0
      end
      alias hidden? panel_hidden

      # Returns pointer to the panel above.
      def panel_above
        Panel.panel_above(pointer)
      end
      alias above panel_above

      # Return a pointer to the panel just below panel.
      # If the panel argument is a pointer to 0, it returns a pointer to the
      # top panel in the stack.
      def panel_below
        Panel.panel_below(pointer)
      end
      alias below panel_below

      # Returns the user pointer for a given panel.
      def panel_userptr
        Panel.panel_userptr(pointer)
      end
      alias userptr panel_userptr

      # sets the panel's user pointer.
      def set_panel_userptr(user_pointer)
        Panel.set_panel_userptr(pointer, user_pointer)
      end
      alias userptr= set_panel_userptr

      # Remove the panel from the stack and deallocate the PANEL structure.
      # Doesn't remove the associated window.
      def del_panel
        Panel.del_panel(pointer)
      end
      alias del del_panel
      alias delete del_panel
    end
  end
end
