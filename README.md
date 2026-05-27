# Farm Counting Fiesta

> A retro DOS educational counting game written in 16-bit x86 assembly (NASM `.COM` format), featuring VGA Mode 13h graphics, Sound Blaster audio, and a full farm-themed UI.

---

## Video Demo

▶️ [Watch the gameplay presentation on Google Drive](https://drive.google.com/file/d/1jbEilJAb6fsJyAIocwscLyDdQGhmyS8f/view?usp=sharing)

---

## About

**Farm Counting Fiesta** is a colorful farm-themed counting game for DOS. Players count animals displayed on screen and type in their answer before the opponent does. It supports both single-player and two-player duel modes, a high score leaderboard, and a user account system — all rendered in VGA 320×200 at 256 colors.

This project is written entirely in **NASM x86 16-bit assembly** and compiles to a `.COM` executable that runs natively on DOS or a DOS emulator (e.g. DOSBox).

---

## Features

- 🐄 **Three animal types** — Chickens, Cows, and Pigs, drawn with custom pixel-art sprites
- 🕹️ **Two game modes**
  - **Single Player** — race against 3 strikes before game over
  - **Farm Duel** — two players answer the same prompt; fastest correct answer wins the round
- 🎯 **Three difficulty levels** — Easy, Medium, Hard
- 🏆 **Persistent high score tables** — separate leaderboards for single-player and duel modes, saved to `SINGLE_SCORES.DAT` and `DUEL_SCORES.DAT`
- 👤 **Account system** — register and log in with a username and password, stored in `ACCOUNTS.DAT` (up to 16 accounts)
- 🎵 **Background music** — a looping C-major farm melody driven by a custom INT 8h timer hook
- 🔊 **Sound effects** — correct answer, wrong answer, victory, game over, clicks, and more via PC speaker / Sound Blaster (auto-detected at port `220h`)
- 🎨 **Smooth screen transitions** — fade in/out, wipe-down, and flash effects
- 📺 **VGA Mode 13h** — double-buffered rendering at 320×200, 256-color custom palette

---

## How to Play

1. From the title screen, press **Enter** to start or **H** to view the tutorial.
2. Select **Single Player** or **Farm Duel**.
3. Choose a difficulty: **Easy**, **Medium**, or **Hard**.
4. Enter your player name (and password if using accounts).
5. Count the animals shown on screen and **type your answer**, then press **Enter** to confirm.
6. First player to collect **5 Barn Tokens** wins!
   - In Single Player, 3 wrong answers = **Game Over**.
   - In Duel mode, the faster correct answer wins each round.

### Controls

| Key | Action |
|-----|--------|
| `0`–`9` | Type your answer |
| `Enter` | Confirm answer / advance |
| `Backspace` | Delete last digit |
| `Esc` | Back / cancel |

---

## Building

### Requirements

- [NASM](https://www.nasm.us/) assembler (any version supporting 16-bit `.COM`)
- DOS or a DOS emulator such as [DOSBox](https://www.dosbox.com/)

### Assemble

```bash
nasm -f bin FARM-14.asm -o FARM.COM
```

### Run

```bash
# In DOSBox:
FARM.COM
```

Or place `FARM.COM` in a DOSBox-mounted directory and run it from the DOS prompt.

---

## Project Structure

```
FARM-14.asm          ← Full source (single-file, ~6300 lines)
FARM.COM             ← Compiled executable (generated)
SINGLE_SCORES.DAT    ← Single-player leaderboard (auto-created)
DUEL_SCORES.DAT      ← Duel mode leaderboard (auto-created)
ACCOUNTS.DAT         ← User account database (auto-created)
```

All data files are created automatically on first run.

---

## Technical Details

| Property | Value |
|----------|-------|
| Architecture | x86 16-bit (286) |
| Format | DOS `.COM` (ORG 100h) |
| Assembler | NASM |
| Video | VGA Mode 13h — 320×200, 256 colors |
| Audio | PC Speaker + Sound Blaster (port 220h, auto-detected) |
| Memory | Double-buffered backbuffer (64 KB segment, allocated via INT 21h) |
| Timer | INT 8h hook for background music tick |
| Palette | Custom 36-color palette (sky, grass, barn, animals, UI) |
| Save files | Raw binary via INT 21h file I/O |

### Key Subsystems

- **Rendering** — All drawing targets an off-screen backbuffer segment; `Flip` blits it to VGA on vertical retrace (`WaitVR`)
- **State machine** — A central `main_loop` dispatches to one of 19 named game states (start, tutorial, mode select, name entry, gameplay, round end, victory, etc.)
- **Music engine** — A melody table of `(frequency, ticks)` pairs is stepped through inside a hooked INT 8h handler (~18 Hz)
- **RNG** — Simple 16-bit LCG seeded from the BIOS timer
- **Font renderer** — Custom 5×7 bitmap font with configurable scale and color

---

## Game States

| State | Description |
|-------|-------------|
| `ST_START` | Title screen |
| `ST_TUTORIAL` | How-to-play screen |
| `ST_MODE` | Single Player / Duel selection |
| `ST_DIFFICULTY` | Easy / Medium / Hard |
| `ST_P1NAME` / `ST_P2NAME` | Name entry |
| `ST_P1BANNER` / `ST_P2BANNER` | Player intro banner |
| `ST_GAME` | Main gameplay |
| `ST_CORRECT` / `ST_WRONG` | Answer feedback |
| `ST_ROUNDEND` | Round summary (Duel mode) |
| `ST_VICTORY` | Winner screen |
| `ST_GAMEOVER` | Game over screen |
| `ST_HISCORES` | Leaderboard display |
| `ST_LOGIN` / `ST_REGISTER` | Account authentication |

## 📄 License

This project is provided as-is for educational and archival purposes.
