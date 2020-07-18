# Conway's Squasher Coroutine

According to Donald Knuth, Melvin E. Conway coined the term coroutine in 1958 when he applied it to the construction of an assembly program. He first published it 1963 in his paper [Design of separable transition-diagram compiler](http://www.melconway.com/Home/pdf/compiler.pdf) ([local copy](Melvin%20Conway%20-%20Design%20of%20separable%20transition-diagram%20compiler.pdf)). The paper introduces the coroutine together with its implementation in assembly for the Burroughs model 220, a late vacuum-tube computer.

This is a reimplementation of Conway's code example, the asterisk squasher subroutine, in modern assembly. Read [my analysis of the code](https://blog.code-cop.org/2020/06/conways-squasher-coroutine.html) for more explanations.

## General Setup

* GNU `make` to run build script
* [NASM](https://www.nasm.us/) to compile
* a linker
* [Smoke](https://github.com/SamirTalwar/smoke) to run tests

### Setup Windows

* `make` from [MinGW](http://www.mingw.org/) or [standalone](https://sourceforge.net/projects/gnuwin32/files/make/)
* [GoLink](http://www.godevtool.com/GolinkHelp/GoLink.htm)

### Setup Linux

* [GNU Linker `ld`](https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_mono/ld.html)

## License

[BSD License](https://opensource.org/licenses/BSD-3-Clause), see `LICENSE.txt` in repository.
