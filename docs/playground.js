import { DefaultRubyVM } from './vendor/ruby-wasm-browser.mjs';
import { rubySource } from './playground_bundle.js';

const source = document.getElementById('source');
const run = document.getElementById('run');
const status = document.getElementById('status');
const preview = document.getElementById('preview');
const text = document.getElementById('text');
let imageUrl;
let vm;
let autoRender = !location.hash;
let renderTimer;

function fromFragment() {
  if (!location.hash) return;
  const binary = atob(decodeURIComponent(location.hash.slice(1)));
  source.value = new TextDecoder().decode(Uint8Array.from(binary, ch => ch.charCodeAt(0)));
}

function toFragment(value) {
  const bytes = new TextEncoder().encode(value);
  location.hash = encodeURIComponent(btoa(Array.from(bytes, byte => String.fromCharCode(byte)).join('')));
}

function render() {
  status.textContent = 'Rendering…';
  try {
    const result = JSON.parse(vm.eval(`RailroadDiagrams.playground_render(${JSON.stringify(source.value)})`).toString());
    if (imageUrl) URL.revokeObjectURL(imageUrl);
    imageUrl = URL.createObjectURL(new Blob([result.svg], { type: 'image/svg+xml' }));
    const image = document.createElement('img');
    image.src = imageUrl;
    image.alt = 'Rendered railroad diagram';
    preview.replaceChildren(image);
    text.textContent = result.text;
    status.textContent = 'Rendered. The URL now contains this source.';
    toFragment(source.value);
  } catch (error) {
    status.textContent = error.message;
  }
}

try {
  fromFragment();
  const response = await fetch('./vendor/ruby+stdlib.wasm');
  if (!response.ok) throw new Error(`Could not load Ruby (${response.status})`);
  const module = await WebAssembly.compile(await response.arrayBuffer());
  ({ vm } = await DefaultRubyVM(module));
  vm.eval(rubySource);
  run.textContent = 'Render diagram';
  run.disabled = false;
  status.textContent = 'Ready. Review shared source before running it.';
  run.addEventListener('click', () => {
    autoRender = true;
    render();
  });
  source.addEventListener('input', () => {
    if (!autoRender) return;
    clearTimeout(renderTimer);
    renderTimer = setTimeout(render, 350);
  });
  if (autoRender) render();
} catch (error) {
  status.textContent = error.message;
}
