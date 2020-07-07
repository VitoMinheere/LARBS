# Vito's Auto-Rice Bootstraping Scripts (VARBS)


## Installation:

On an Arch based distribution as root, run the following:

```
curl -LO https://raw.githubusercontent.com/VitoMinheere/LARBS/master/larbs.sh
sh larbs.sh
```

That's it.

## What is LARBS?

LARBS is a script that autoinstalls and autoconfigures a fully-functioning
and minimal terminal-and-vim-based Arch Linux environment.

LARBS is created by [Luke Smith](https://github.com/LukeSmithxyz/LARBS)
I used his settings for a while before adding my own. During this time i skipped all upstream work so this branch is out of date with his.
No issue for me as i prefer i3 above dwm and i like to install different programs(more software development oriented).

This setup has been used for over a year for software development work purposes.
First using Arch but currently running Manjaro as i needed some GUI programs(damn you teamviewer)

Here are some of the things VARBS sets up:

- Installs i3-gaps, a tiling window manager, with my fully featured
  configuration along with dozens of lightweight and vim-centric terminal
  applications that replace the more over-encumbering
  programs on most machines.
- Massive documentation making use even for novices seamless. A help document
  with all bindings for the window manager accessible with `Super+F1` at all
  times, as well as commands such as `getkeys` which print the default bindings
  of terminal applications.
- Installs [my dotfiles](https://github.com/VitoMinheere/voidrice)
- Sets up system requirements such as users, permissions, networking, audio and
  an AUR manager.
- All done behind a `dialog` based user interface.

## Changes from LARBS

- Only 1 window manager will be installed, as i am running it in Manjaro with XFCE or KDE.
- More documentation in the `getkeys` program and `mod+shift-e`.
- i3status is tweaked to my preferences. I don't need the weather service(as it doesn't work out of the box in EU). It now has:
  	- CPU usage and temp.
	- RAM usage
	- Disk Space left
	- Possible pacman updates
	- Expected date, time, battery, internet and volume modules
- Chromium as default browser.

## Customization

By default, LARBS uses the programs [here in progs.csv](archi3/progs.csv) and installs
[my dotfiles repo (voidrice) here](https://github.com/VitoMinheere/voidrice),
but you can easily change this by either modifying the default variables at the
beginning of the script or giving the script one of these options:

- `-r`: custom dotfiles repository (URL)
- `-p`: custom programs list/dependencies (local file or URL)
- `-a`: a custom AUR helper (must be able to install with `-S` unless you
  change the relevant line in the script

### The `progs.csv` list

LARBS will parse the given programs list and install all given programs. Note
that the programs file must be a three column `.csv`.

The first column is a "tag" that determines how the program is installed, ""
(blank) for the main repository, `A` for via the AUR or `G` if the program is a
git repository that is meant to be `make && sudo make install`ed.

The second column is the name of the program in the repository, or the link to
the git repository, and the third comment is a description (should be a verb
phrase) that describes the program. During installation, LARBS will print out
this information in a grammatical sentence. It also doubles as documentation
for people who read the csv or who want to install my dotfiles manually.

Depending on your own build, you may want to tactically order the programs in
your programs file. LARBS will install from the top to the bottom.

If you include commas in your program descriptions, be sure to include double quotes around the whole description to ensure correct parsing.

### The script itself

The script is broken up extensively into functions for easier readability and
trouble-shooting. Most everything should be self-explanatory.

The main work is done by the `installationloop` function, which iterates
through the programs file and determines based on the tag of each program,
which commands to run to install it. You can easily add new methods of
installations and tags as well.

Note that programs from the AUR can only be built by a non-root user. What
LARBS does to bypass this by default is to temporarily allow the newly created
user to use `sudo` without a password (so the user won't be prompted for a
password multiple times in installation). This is done ad-hocly, but
effectively with the `newperms` function. At the end of installation,
`newperms` removes those settings, giving the user the ability to run only
several basic sudo commands without a password (`shutdown`, `reboot`,
`pacman -Syu`).
