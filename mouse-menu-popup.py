#!/usr/bin/env python3
# mouse-menu-popup
import gi, sys, os, signal

gi.require_version('Gtk', '4.0')
from gi.repository import Gtk, Gdk, GLib

signal.alarm(10)
signal.signal(signal.SIGALRM, lambda *a: os._exit(1))

items = [
    "Claude Code",
    "Claude Selection",
    "DPI Cycle",
    "Screenshot OCR",
    "Git Status",
    "Network Info",
    "Clipboard Run",
    "Lock Screen",
    "Kill Window",
    "Color Picker",
    "Quick Note",
    "System Monitor",
]

class MenuPopup(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="dev.mouse.menu")
        self.result = ""

    def do_activate(self):
        win = Gtk.ApplicationWindow(application=self)
        win.set_decorated(False)
        win.set_default_size(250, -1)
        win.set_resizable(False)
        win.set_titlebar(Gtk.Box())  # empty titlebar forces CSD with no decorations

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        win.set_child(box)

        for label in items:
            btn = Gtk.Button(label=label)
            btn.set_has_frame(False)
            btn.connect("clicked", self.on_click, label, win)
            box.append(btn)

        css = Gtk.CssProvider()
        css.load_from_string("""
            window {
                background: #1a1a2e;
                border-radius: 8px;
            }
            button {
                color: #e0e0e0;
                padding: 8px 20px;
                font-family: monospace;
                font-size: 13px;
                background: transparent;
                border: none;
                border-radius: 4px;
                min-width: 200px;
            }
            button:hover {
                background: #16213e;
                color: #00ff41;
            }
        """)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        key_ctrl = Gtk.EventControllerKey()
        key_ctrl.connect("key-pressed", self.on_key, win)
        win.add_controller(key_ctrl)

        win.present()

    def on_click(self, btn, label, win):
        self.result = label
        win.close()

    def on_key(self, ctrl, keyval, keycode, state, win):
        if keyval == Gdk.KEY_Escape:
            win.close()
            return True
        return False

app = MenuPopup()
app.run([])
if app.result:
    print(app.result)
