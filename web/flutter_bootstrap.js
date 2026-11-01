{{flutter_js}}
{{flutter_build_config}}

(() => {
  let finished = false;
  const ready = () => {
    if (finished) return;
    finished = true;
    document.getElementById('app-loading')?.remove();
    performance.mark('library-ready');
  };
  const failed = (error) => {
    console.error(error);
    document.getElementById('loading-message').textContent =
      'Не удалось загрузить приложение. Проверьте соединение.';
    document.getElementById('loading-retry').hidden = false;
  };
  window.addEventListener('flutter-first-frame', ready, { once: true });
  _flutter.loader.load({
    onEntrypointLoaded: async (initializer) => {
      try {
        const runner = await initializer.initializeEngine();
        await runner.runApp();
        requestAnimationFrame(() => requestAnimationFrame(ready));
      } catch (error) { failed(error); }
    },
  }).catch(failed);
})();
