{{flutter_js}}
{{flutter_build_config}}

(() => {
  const route = new URL(location.href).searchParams.get('__route');
  if (route) {
    try {
      const target = new URL(route, location.origin);
      const base = new URL(document.querySelector('base').href);
      if (target.origin === location.origin && target.pathname.startsWith(base.pathname) &&
          !target.searchParams.has('__route')) {
        history.replaceState(null, '', target.pathname + target.search + target.hash);
      }
    } catch (_) { /* Ignore an invalid return address. */ }
  }
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
