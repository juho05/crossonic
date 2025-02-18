# Crossonic

A cross platform music client for [crossonic-server](https://github.com/juho05/crossonic-server).

## Status

This app is still in development. Some features are missing and bugs are to be expected.

See [Supported platforms](#supported-platforms) for a status per platform.

## Features

- [x] Desktop and mobile layout
- [x] Respects light/dark theme and accent color
- [x] System integration (*Android media API*, *MPRIS*, *SystemMediaTransportControls*, …)
- [x] Stream original or transcoded media
  - [x] configurable transcoding settings for WiFi and mobile
- [x] Browse/search songs, albums, artists
- [x] Favorite songs/albums/artists
- [x] Playlists
  - [x] download for offline listening (*except web*)
- [x] [ListenBrainz](https://listenbrainz.org) integration
  - [x] scrobble
  - [x] sync favorite songs
- [x] Two queue system
  - normal queue
    - automatically populated when listening to an album/artist/playlist
  - priority queue
    - for songs you want to listen now before continuing with the normal queue
  - both can be freely modified
- [x] Shuffle artists by song or by album
- [x] Gapless playback
- [x] Lyrics
  - [x] unsynced
  - [ ] synced
- [x] Replay gain
- [ ] Jukebox
- [ ] Save queues
- [ ] Remote control other devices running the app

## Supported platforms

While this app can be built for every platform [Flutter](https://flutter.dev) supports (although some additional configuration might be necessary), playback can be very buggy on some platforms and might not support all features.

**fully supported**
- Linux
- Android (*no AAC support*)
- macOS
- Windows

**some limitations**
- Web (*no playlist download*, *no gapless*)
  - Safari playback randomly stops when streaming transcoded media

**unsupported**
- iOS

## Build/run

Install [Flutter](https://docs.flutter.dev/get-started/install) with all dependencies for your desired target platform.

Clone the repository
```bash
git clone https://github.com/juho05/crossonic
cd crossonic
```

Generate json bindings:
```bash
dart run build_runner build
```

### Linux

#### Install dependencies

- Install [GStreamer](https://gstreamer.freedesktop.org/documentation/installing/on-linux.html?gi-language=c).
- Install libsecret-1-0 and libjsoncpp1

##### Debian

```bash
sudo apt-get install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good gstreamer1.0-plugins-bad libsecret-1-dev libjsoncpp-dev
```

##### ArchLinux

```bash
sudo pacman -S gstreamer gst-libav gst-plugins-base gst-plugins-goodgstreamer1.0-plugins-bad libsecret jsoncpp
```

#### Build

In the directory of the repository run:

```bash
flutter build linux --release
```

The built executable is at `./build/linux/x64/release/bundle/Crossonic`.

### Windows

#### Install dependencies

Install [GStreamer](https://gstreamer.freedesktop.org/documentation/installing/on-windows.html?gi-language=c) for example with [chocolatey](https://chocolatey.org/):

```bash
choco install gstreamer gstreamer-devel
```

#### Build

In the directory of the repository run:

```bash
flutter build windows --release
```

*NOTE:* The first time starting playback the program might hang for a few seconds and a command prompt window might pop up.
This is a one-time event. Just wait until the playback starts.

### macOS

- Install [GStreamer](https://gstreamer.freedesktop.org/download/#macos) (*runtime* **and** *development*)

In the directory of the repository run:
```bash
flutter build macos --release
```

### Android

- [Download](https://gstreamer.freedesktop.org/data/pkg/android/1.24.10/gstreamer-1.0-android-universal-1.24.10.tar.xz) GStreamer for Android
- Extract the file and rename the resulting directory to `gst-android`
- Move `gst-android` into `./native_bindings/gstreamer/gstreamer_ffi/third-party`

In the directory of the repository run:
```bash
flutter build apk --release
```

### Web

No additional dependencies should be required.

In the directory of the repository run:
```bash
flutter build web --release
```

Now you can serve `./build/web` with a web server like [Caddy](https://caddyserver.com/).

## Screenshots

![Home (mobile)](screenshots/mobile_home.png)
![Album (mobile)](screenshots/mobile_album.png)
![Now Playing (mobile)](screenshots/mobile_now_playing.png)
![Playlist (mobile)](screenshots/mobile_playlist.png)
![Album (desktop)](screenshots/desktop_album.png)

## License

Copyright (c) 2024-2025 Julian Hofmann

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.