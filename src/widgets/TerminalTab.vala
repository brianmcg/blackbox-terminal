/* TerminalTab.vala
 *
 * Copyright 2021-2022 Paulo Queiroz
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * The content of a tab: a tree of split panes. The child of this widget is
 * either a single {@link TerminalPane} or a {@link Gtk.Paned} whose two
 * children are, recursively, panes or further Gtk.Paned.
 */
public class Terminal.TerminalTab : Adw.Bin {
  // This signal is emitted when the TerminalTab is asking to be closed.
  public signal void close_request();

  public TerminalPane focused_pane   { get; private set; }
  public string? title_override { get; private set; default = null; }

  // The focused pane's terminal
  public Terminal terminal {
    get { return this.focused_pane.terminal; }
  }

  public string title {
    get { return this.title_override ?? this.focused_pane.title; }
  }

  public bool is_split {
    get { return !(this.child is TerminalPane); }
  }

  // Whether any pane's terminal wants the user's attention
  public bool needs_attention {
    get {
      foreach (var pane in this.get_panes()) {
        if (pane.terminal.needs_attention) { return true; }
      }
      return false;
    }
  }

  private weak Window window;
  private string default_title;
  private ulong  focused_pane_title_handler = 0;

  public TerminalTab (
    Window window,
    uint tab_id,
    string? command,
    string? cwd
  ) {
    this.window = window;
    this.default_title = command ?? "%s %u".printf(_("tab"), tab_id);

    var pane = this.create_pane(command, cwd);
    this.child = pane;
    this.on_pane_focused(pane);

    this.notify["title-override"].connect(() => {
      this.notify_property("title");
    });

    pane.terminal.spawn_failed.connect(() => {
      this.override_title(_("Error"));
    });
  }

  private TerminalPane create_pane(string? command, string? cwd) {
    // Tabs can be moved between windows; prefer the one we are in now.
    var win = (this.get_root() as Window) ?? this.window;
    var pane = new TerminalPane(win, this.default_title, command, cwd);

    pane.focused.connect(this.on_pane_focused);
    pane.close_request.connect(this.close_pane);
    pane.terminal.notify["needs-attention"]
    .connect(this.on_pane_needs_attention_changed);

    return pane;
  }

  private void on_pane_needs_attention_changed() {
    this.notify_property("needs-attention");
  }

  private void on_focused_pane_title_changed() {
    this.notify_property("title");
  }

  private void on_pane_focused(TerminalPane pane) {
    if (pane == this.focused_pane) { return; }

    if (this.focused_pane_title_handler != 0) {
      this.focused_pane.disconnect(this.focused_pane_title_handler);
    }

    this.freeze_notify();
    this.focused_pane = pane;
    this.focused_pane_title_handler = pane.notify["title"]
      .connect(this.on_focused_pane_title_changed);
    this.notify_property("terminal");
    this.notify_property("title");
    this.thaw_notify();
  }

  /**
   * Split the focused pane in two and focus the new pane.
   * HORIZONTAL puts the new pane to the right, VERTICAL puts it below.
   */
  public void split(Gtk.Orientation orientation) {
    var target = this.focused_pane;
    var cwd = Terminal
      .get_current_working_directory_for_new_session(target.terminal);
    var new_pane = this.create_pane(null, cwd);

    var paned = new Gtk.Paned(orientation) {
      resize_start_child = true,
      resize_end_child = true,
      shrink_start_child = false,
      shrink_end_child = false,
    };

    // Divide the space the target pane currently occupies evenly
    var size = orientation == Gtk.Orientation.HORIZONTAL
      ? target.get_width()
      : target.get_height();
    if (size > 0) {
      paned.position = size / 2;
    }

    // Put the splitter where the target pane was, then the panes inside it
    this.replace_widget(target, paned);
    paned.start_child = target;
    paned.end_child = new_pane;

    this.notify_property("is-split");
    new_pane.terminal.grab_focus();
  }

  /**
   * Focus the next (or previous) pane in layout order, wrapping around.
   */
  public void focus_pane(bool forward) {
    var panes = this.get_panes();
    if (panes.size < 2) { return; }

    var i = panes.index_of(this.focused_pane);
    var next = forward
      ? (i + 1) % panes.size
      : (i - 1 + panes.size) % panes.size;

    panes[next].terminal.grab_focus();
  }

  /**
   * Remove a pane (no confirmation). The other side of its divider takes its
   * place. Closing the last pane asks for the whole tab to be closed.
   */
  public void close_pane(TerminalPane pane) {
    var paned = pane.parent as Gtk.Paned;

    if (paned == null) {
      this.close_request();
      return;
    }

    pane.on_before_close();

    Gtk.Widget sibling = (paned.start_child == pane)
      ? paned.end_child
      : paned.start_child;

    paned.start_child = null;
    paned.end_child = null;
    this.replace_widget(paned, sibling);
    this.notify_property("is-split");

    if (pane == this.focused_pane) {
      var next = first_pane_in(sibling);
      this.on_pane_focused(next);
      next.terminal.grab_focus();
    }

    this.notify_property("needs-attention");
  }

  // Put `replacement` where `old` currently is in the split tree
  private void replace_widget(Gtk.Widget old, Gtk.Widget replacement) {
    var parent = old.parent;

    if (parent == this) {
      this.child = replacement;
    } else {
      var paned = (Gtk.Paned) parent;
      if (paned.start_child == old) {
        paned.start_child = replacement;
      } else {
        paned.end_child = replacement;
      }
    }
  }

  // The first pane in layout order inside `widget`
  private static TerminalPane first_pane_in(Gtk.Widget widget) {
    var w = widget;
    while (w is Gtk.Paned) {
      w = ((Gtk.Paned) w).start_child;
    }
    return (TerminalPane) w;
  }

  /**
   * All panes in layout order (top/left before bottom/right).
   */
  public Gee.List<TerminalPane> get_panes() {
    var list = new Gee.ArrayList<TerminalPane> ();
    collect_panes(this.child, list);
    return list;
  }

  private static void collect_panes(
    Gtk.Widget? widget,
    Gee.List<TerminalPane> list
  ) {
    if (widget is TerminalPane) {
      list.add((TerminalPane) widget);
    } else if (widget is Gtk.Paned) {
      var paned = (Gtk.Paned) widget;
      collect_panes(paned.start_child, list);
      collect_panes(paned.end_child, list);
    }
  }

  public void search() {
    this.focused_pane.search();
  }

  public void override_title(string? _title) {
    this.title_override = _title;
  }

  /**
   * Make the pane holding the terminal with this id the focused pane.
   * Returns false if no pane in this tab holds that terminal.
   */
  public bool focus_terminal(uint terminal_id) {
    foreach (var pane in this.get_panes()) {
      if (pane.terminal.id == terminal_id) {
        this.on_pane_focused(pane);
        return true;
      }
    }
    return false;
  }

  public void on_before_close() {
    foreach (var pane in this.get_panes()) {
      pane.on_before_close();
    }
  }
}
