# playing around with hot code relading for tui development

## Much of the code comes from the following sources:
  - https://zig.news/lhp/want-to-create-a-tui-application-the-basics-of-uncooked-terminal-io-17gm
  - https://zig.news/perky/hot-reloading-with-raylib-4bf9
  - https://github.com/samhattangady/hotreload/blob/master/src/main.zig
  - https://www.youtube.com/watch?v=PgulOEQXB9E
  - https://ziggit.dev/t/how-can-i-prevent-segfault-when-hot-reloading-zig-code/4710

Things to try for TUI:
 - Use query instead of terminfo, take inspiration from libvaxis 
 - Use the Kitty keyboard protocol instead to read keypresses. Well documented!
 - I want a server client architecture the terminal should handle all window splitting etc.
 - I want to use the terminal as editor could a use a projectional editor for treesitter, project the tresitter ast directry to the terminal?
 - Try this also in wezterm, might be better for my type of development where i want sessions?


Things to try for code reload:
 - Add an option to buil with static which will not be hotreloaded. See github link they do that.
 - Only reload when libgame.so changes not every x seconds.
 - Look in the how can i prevent segfault ziggit thread, one guy talks about allocating lots of memory for game state and then use arena allocator so one can grow, this sounds smart, try that if I am unable to change data structure.
 - From comment on post. 
    You could also create a new file every time you recompile the DLL (say, game_<timestamp>.dll), so that you can (in this order) recompile, unload the DLL, copy / rename / update a symlink (on linux) the new DLL, reload it. That way the pause would really be brief.

## As a next step I would like to expand this to but I am unable to find more info about the zig state for this:
  - http://www.jakubkonka.com/2022/03/16/hcs-zig.html
  - https://www.jakubkonka.com/2022/03/22/hcs-zig-part-two.html

## Roadmap
  Would like to make a Roc platform and investigate how roc hot reload can help with writing the GUI layer here with hot reaload.
