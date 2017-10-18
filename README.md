# CTags for micro text editor

This plugin adds (rudimentary) support for reading/parsing a ctags file.

How to use:
- Generate the ctags file using exuberant-ctags. You can use a command like `ctags -R`.
- Emacs-style ctags are NOT supported (for now).
- Install the plugin
- Open your source code file and position the cursor on the name of a function
- Press F12

If you select part of a word, only that part will be used for the match.

BEWARE: This is still kind-of preliminary code and not optimized. If you have a big ctags file (more than 1Gb), it will take time to load and use a lot of memory.