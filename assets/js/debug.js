/**
 * Debounce function to limit the rate at which a function can fire.
 */
function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

let cachedCell = null;

/**
 * Measures the dimensions of a single grid cell (1ch x --line-height).
 */
function gridCellDimensions() {
  if (cachedCell) return cachedCell;

  const element = document.createElement('div');
  element.style.position = 'fixed';
  element.style.visibility = 'hidden';
  element.style.height = 'var(--line-height)';
  element.style.width = '1ch';
  document.body.appendChild(element);
  const rect = element.getBoundingClientRect();
  document.body.removeChild(element);

  cachedCell = { width: rect.width, height: rect.height };
  return cachedCell;
}

/**
 * Adjusts media padding to maintain vertical rhythm.
 */
function adjustMediaPadding() {
  const medias = document.querySelectorAll('img, video');
  if (medias.length === 0) return;

  const cell = gridCellDimensions();

  function setHeightFromRatio(media, ratio) {
    const rect = media.getBoundingClientRect();
    const realHeight = rect.width / ratio;
    const diff = cell.height - (realHeight % cell.height);
    media.style.setProperty('padding-bottom', `${diff}px`);
  }

  function setFallbackHeight(media) {
    const rect = media.getBoundingClientRect();
    const height = Math.round(rect.width / 2 / cell.height) * cell.height;
    media.style.setProperty('height', `${height}px`);
  }

  function onMediaLoaded(media) {
    let width, height;

    switch (media.tagName) {
      case 'IMG':
        width = media.naturalWidth;
        height = media.naturalHeight;
        break;
      case 'VIDEO':
        width = media.videoWidth;
        height = media.videoHeight;
        break;
    }

    if (width > 0 && height > 0) {
      setHeightFromRatio(media, width / height);
    } else {
      setFallbackHeight(media);
    }
  }

  for (const media of medias) {
    switch (media.tagName) {
      case 'IMG':
        if (media.complete) {
          onMediaLoaded(media);
        } else {
          media.addEventListener('load', () => onMediaLoaded(media), {
            once: true,
          });
          media.addEventListener(
            'error',
            () => {
              setFallbackHeight(media);
            },
            { once: true },
          );
        }
        break;
      case 'VIDEO':
        if (media.readyState >= 2) {
          // HAVE_CURRENT_DATA
          onMediaLoaded(media);
        } else {
          media.addEventListener('loadeddata', () => onMediaLoaded(media), {
            once: true,
          });
          media.addEventListener(
            'error',
            () => {
              setFallbackHeight(media);
            },
            { once: true },
          );
        }
        break;
    }
  }
}

// Initial adjustment
adjustMediaPadding();

// Debounced resize adjustment
const debouncedAdjust = debounce(() => {
  cachedCell = null; // Recalculate cell on resize
  adjustMediaPadding();
}, 150);

window.addEventListener('load', adjustMediaPadding);
window.addEventListener('resize', debouncedAdjust);

// Debug Toggle Logic
const debugToggle = document.querySelector('.debug-toggle');

function onDebugToggle() {
  if (debugToggle) {
    document.body.classList.toggle('debug', debugToggle.checked);
  }
}

if (debugToggle) {
  debugToggle.addEventListener('change', onDebugToggle);

  onDebugToggle();
}
