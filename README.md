
### What is this? ###

It's a program that extracts sprites from the 3rd generation Pokémon games—Ruby, Sapphire, Emerald, FireRed, and LeafGreen.

It is written in [Python 3][] and [Cython][].

[Python 3]: http://www.python.org/
[cython]: http://cython.org/

### Is it any good? ###

Yes.

### How do i use it? ###

To compile, just run

    % redo

You will need to have [redo][] and Cython installed. For that matter, you also need Python 3 and a C compiler. And [libpng][].

Run it like this:

    % mkdir sprites
    % ./rip.py /path/to/rom.gba sprites

which will extract the front pokémon sprites from `rom.gba` and dump a bunch of pngs into the `sprites` directory.

You can poke around `rip.py` to change which sprites are extracted; there are a bunch of offsets in `pokeroms.yml` that might be useful.

[redo]: https://github.com/apenwarr/redo
[libpng]: http://libpng.org/
[EliteMap]: http://www.romhacking.net/utilities/463/


### What about other games? ###

I have written sprite dumpers for some other Pokémon games:

* [pokemon-nds-sprites][] extracts sprites from the 4th and 5th gen games (Diamond, Pearl, Platinum, HeartGold, SoulSilver, Black, White). It is written in C and Scheme.

* [pokemon-sprites-rby][] extracts sprites from the 1st generation games (Red, Green, Blue, Yellow). It is written in pure Python.

[Zhorken][] has written a dumper for the 2nd generation games (Gold, Silver, Crystal). It is in [pokemon-flavour][].

[pokemon-nds-sprites]: https://github.com/magical/pokemon-nds-sprites
[pokemon-sprites-rby]: https://github.com/magical/pokemon-rby-sprites
[Zhorken]: https://github.com/Zhorken
[pokemon-flavour]: https://github.com/Zhorken/pokemon-flavour



### License ###

This project copyright © 2011 magical.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

.

`pokeroms.yml` was adapted from `PokeRoms.ini` from [EliteMap][].

