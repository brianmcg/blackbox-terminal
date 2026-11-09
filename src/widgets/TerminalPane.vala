/* TerminalPane.vala
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
 * A single terminal, with its scrollbar, search toolbar, error banner and
 * context menu. A {@link TerminalTab} contains panes.
 */
[GtkTemplate(ui = "/com/raggesilver/BlackBox/gtk/terminal-pane.ui")]
public class Terminal.TerminalPane : Gtk.Box {
  // This signal is emitted when the TerminalPane is asking to be closed.
  public signal void close_request();

  // This signal is emitted when this pane's terminal receives keyboard focus.
  public signal void focused();

  [GtkChild] unowned Adw.Banner banner;
  [GtkChild] unowned Gtk.ScrolledWindow scrolled;
  [GtkChild] unowned SearchToolbar search_toolbar;

  private string default_title;
  private Gtk.PopoverMenu popover;

  public Terminal terminal       { get; protected set; }

  public string title {
    get {
      if (this.terminal.window_title != null &&
          this.terminal.window_title.strip() != "") {
        return this.terminal.window_title;
      }

      return this.default_title;
    }
  }

  static construct {
    typeof (SearchToolbar).class_ref();
  }

  public TerminalPane (
    Window window,
    string default_title,
    string? command,
    string? cwd
  ) {
    Object(
      orientation: Gtk.Orientation.VERTICAL,
      spacing: 0
    );

    this.default_title = default_title;

    this.terminal = new Terminal(window, command, cwd);
    // TODO: Can't we use a property for this? Has default or something?
    this.terminal.grab_focus();
    this.popover = build_popover();

    var click = new Gtk.GestureClick() {
      button = Gdk.BUTTON_SECONDARY,
    };

    click.pressed.connect(this.show_menu);

    this.terminal.add_controller(click);

    this.connect_signals();
  }

#if BLACKBOX_DEBUG_MEMORY
  ~TerminalPane () {
    message("TerminalPane destroyed");
  }

  public override void dispose() {
    message("TerminalPane dispose");
    base.dispose();
  }

#endif

  private void connect_signals() {
    var settings = Settings.get_default();

    //  this.terminal.bind_property ("window-title",
    //                               this,
    //                               "title",
    //                               GLib.BindingFlags.DEFAULT,
    //                               null, null);

    this.terminal.notify["window-title"].connect(() => {
      this.notify_property("title");
    });

    this.terminal.notify["has-focus"].connect(() => {
      if (this.terminal.has_focus) {
        this.focused();
      }
    });

    this.terminal.exit.connect(() => {
      this.close_request();
    });

    this.terminal.spawn_failed.connect((message) => {
      this.banner.title = message;
      this.banner.revealed = true;
    });

    settings.notify["show-scrollbars"]
    .connect(this.on_show_scrollbars_updated);

    settings.notify_property("show-scrollbars");

    settings.schema.bind(
      "use-overlay-scrolling",
      this.scrolled,
      "overlay-scrolling",
      SettingsBindFlags.GET
    );

    settings.bind_property(
      "use-sixel",
      this.terminal,
      "enable-sixel",
      BindingFlags.SYNC_CREATE
    );

    // refocus terminal after closing context menu, otherwise the focus will go on the header buttons
    this.popover.closed.connect_after(pop_close);
  }

  private void on_show_scrollbars_updated() {
    var settings = Settings.get_default();
    var show_scrollbars = settings.show_scrollbars;
    var is_scrollbar_being_used = this.terminal.parent == this.scrolled;

    this.scrolled.visible = show_scrollbars;

    if (show_scrollbars != is_scrollbar_being_used) {
      if (this == this.terminal.parent) {
        this.remove(this.terminal);
      } else if (this.scrolled == this.terminal.parent) {
        this.scrolled.child = null;
      }
    }

    if (
      show_scrollbars != is_scrollbar_being_used ||
      this.terminal.parent == null
    ) {
      if (show_scrollbars) {
        this.scrolled.child = this.terminal;
      } else {
        this.insert_child_after(this.terminal, null);
      }
    }
  }

  public Gtk.PopoverMenu build_popover() {
    var builder =
      new Gtk.Builder.from_resource(
        "/com/raggesilver/BlackBox/gtk/terminal-menu.ui");
    var pop = builder.get_object("popover") as Gtk.PopoverMenu;

    pop.set_parent(this);
    pop.set_has_arrow(false);
    pop.set_halign(Gtk.Align.START);

    return pop;
  }

  public void pop_close() {
    this.terminal.grab_focus();
  }

  public void show_menu(int n_pressed, double x, double y) {
    if (this.terminal.hyperlink_hover_uri != null) {
      this.terminal.window.link = this.terminal.hyperlink_hover_uri;
    } else {
      this.terminal.window.link = this.terminal.check_match_at(x, y, null);
    }

    double x_in_view, y_in_view;
    this.terminal.translate_coordinates(this, x, y, out x_in_view,
                                        out y_in_view);

    var r = Gdk.Rectangle() {
      x = (int) x_in_view,
      y = (int) y_in_view
    };

    this.popover.set_pointing_to(r);
    this.popover.popup();
  }

  public void search() {
    this.search_toolbar.open();
  }

  public void on_before_close() {
    terminal.on_before_close();
  }
}
