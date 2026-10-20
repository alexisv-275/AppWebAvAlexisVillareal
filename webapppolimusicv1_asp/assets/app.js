"use strict";
(() => {
  // Una vista recuperada desde el historial debe volver a validar la sesión.
  window.addEventListener("pageshow", (event) => {
    if (event.persisted) window.location.reload();
  });
  const audio = document.querySelector("#audio-player");
  if (!audio) return;
  const title = document.querySelector("#player-title");
  const message = document.querySelector("#player-message");
  const state = document.querySelector("#player-state");
  const buttons = [...document.querySelectorAll("[data-song-id]")];
  let current = null;
  let selection = 0;
  function render() {
    for (const button of buttons) {
      const active = button === current;
      const playing = active && !audio.paused && !audio.ended;
      button.closest(".song-card").classList.toggle("is-active", active);
      button.querySelector("span").textContent = playing ? "Ⅱ" : "▶";
      button.setAttribute("aria-label", `${playing ? "Pausar" : "Reproducir"} ${button.dataset.songName}`);
      if (!button.disabled) button.closest(".song-card").querySelector(".song-status").textContent = playing ? "Reproduciendo" : active ? "Seleccionada" : "Lista para escuchar";
    }
    state.textContent = audio.ended ? "CANCIÓN FINALIZADA" : audio.paused ? "EN PAUSA" : "AHORA SUENA";
  }
  for (const button of buttons) button.addEventListener("click", async () => {
    if (button.disabled) return;
    const request = ++selection;
    if (current === button && !audio.paused) { audio.pause(); return; }
    if (current !== button) {
      audio.pause();
      current = button;
      title.textContent = button.dataset.songName;
      audio.src = button.dataset.audioUrl;
    }
    message.textContent = "Cargando tu canción…";
    render();
    try { await audio.play(); if (selection === request) message.textContent = "Disfruta tu momento."; }
    catch (error) { if (selection === request && error.name !== "AbortError") message.textContent = "No se pudo reproducir. Comprueba tu sesión y vuelve a intentarlo."; }
    render();
  });
  for (const event of ["play", "pause", "ended"]) audio.addEventListener(event, render);
  audio.addEventListener("ended", () => { message.textContent = "¿Una canción más?"; });
  audio.addEventListener("error", () => { message.textContent = "Audio no disponible o sesión vencida. Vuelve a iniciar sesión si es necesario."; render(); });
})();
