default:
    just -l
# Make sure to suppress output of main process else it will interfere with the TUI 
rerun: 
    zig build run -Dgame_only=false -- > dev.log 2>&1        

game-only:
    zig build -Dgame_only=true
