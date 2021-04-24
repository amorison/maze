# Amazing Maze

This is a simple maze game written in [Lua](https://www.lua.org/about.html) for
[LÖVE (11.3)](http://love2d.org/).  The maze appears and fades as you visit it.
The starting position is always on the top left and the exit is always on the
bottom right of the window.  The mazes are randomly generated, using a modified
version of [Prim's algorithm](https://en.wikipedia.org/wiki/Prim%27s_algorithm)
that allows bridges.  This means in particular that the mazes are always
"perfect" (i.e. every cell is accessible, and there is only one path between
two cells).

You can run this game by installing LÖVE and running `love .` in the root of
the repository.  Completing a maze (i.e. reaching the bottom right cell) leads
you directly to the next one.  You can resize the window to change the size of
the maze.

You can move in the maze using the arrow keys.  Two other keys have an effect:

- `v`: toggles the fading effect on cells previously visited;
- `s`: highlights the path to the exit from the current position, press it
  again to remove the highlighted path.
