import { WaymoteSession } from "/waymote.js";

const display = document.querySelector("#display");
const empty = document.querySelector("#empty");
const toolbar = document.querySelector("#toolbar");
const status = document.querySelector("#status");
const fullscreenButton = document.querySelector("#fullscreen");
const audioButton = document.querySelector("#audio");
const textInputButton = document.querySelector("#text-input");
const sendClipboardButton = document.querySelector("#send-clipboard");
const copyClipboardButton = document.querySelector("#copy-clipboard");
const imeProxy = document.querySelector("#ime-proxy");

const session = new WaymoteSession({
  // Present each frame as soon as it is decoded. The Connect round trip
  // already adds more delay than any jitter buffer would hide.
  latency: 0,
  // Size the remote desktop to this window. Above the pixel limit, the SDK
  // lowers the resolution and raises the Wayland scale to keep the same layout.
  remoteDisplay: { mode: "observe", maxPixels: 2560 * 1600 },
});
const surface = session.attachSurface({
  canvas: display,
  inputElement: display,
  textInputElement: imeProxy,
  controlOnFocus: true,
  clipboardAutoSync: true,
});

session.on("state", (state) => {
  status.textContent = state.video.state === "connected" ? state.input.message : state.video.message;
  toolbar.classList.toggle("visible", state.video.state !== "connected");
  audioButton.disabled = !state.audio.available;
  audioButton.textContent = state.audio.muted ? "Unmute audio"
    : state.audio.state === "active" ? "Mute audio" : "Enable audio";
  if (state.video.state === "error") {
    empty.textContent = state.video.message;
    empty.classList.remove("hidden");
  }
});

session.on("stats", () => {
  empty.classList.add("hidden");
});

session.on("clipboard", (event) => {
  copyClipboardButton.disabled = event.text === null;
});

session.on("error", (error) => {
  console.warn("Waymote stream error", error);
});

fullscreenButton.addEventListener("click", async () => {
  if (document.fullscreenElement) {
    await document.exitFullscreen();
    return;
  }
  try {
    await document.documentElement.requestFullscreen();
    // Send Escape, Super and browser shortcuts to the remote desktop.
    await navigator.keyboard?.lock?.();
  } catch (error) {
    console.warn("full screen unavailable", error);
  }
});

document.addEventListener("fullscreenchange", () => {
  fullscreenButton.textContent = document.fullscreenElement ? "Exit full screen" : "Full screen";
  surface.focus();
});

audioButton.addEventListener("click", async () => {
  try {
    if (session.state.audio.state === "active" || session.state.audio.state === "muted") {
      session.audio.setMuted(!session.audio.muted);
    } else {
      await session.audio.enable();
    }
  } catch (error) {
    console.warn("audio start failed", error);
  }
});

textInputButton.addEventListener("click", () => {
  session.input.acquire();
  surface.focusTextInput();
});

sendClipboardButton.addEventListener("click", async () => {
  try {
    session.clipboard.sendText(await navigator.clipboard.readText());
  } catch (error) {
    console.warn("local clipboard read failed", error);
  }
  surface.focus();
});

copyClipboardButton.addEventListener("click", async () => {
  const text = session.clipboard.latestRemoteText;
  if (text !== null) await navigator.clipboard.writeText(text).catch(() => {});
  surface.focus();
});

for (const button of toolbar.querySelectorAll("button")) {
  button.addEventListener("pointerdown", (event) => event.preventDefault());
}

session.connect();
surface.focus();
