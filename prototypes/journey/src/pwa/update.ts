export interface ServiceWorkerUpdateController {
  subscribe(listener: () => void): () => void;
  subscribeExternalActivation(listener: () => void): () => void;
  attach(
    registration: ServiceWorkerRegistration,
    container: ServiceWorkerContainer,
  ): void;
  apply(): void;
}

export const createServiceWorkerUpdateController = (
  reload: () => void,
): ServiceWorkerUpdateController => {
  const listeners = new Set<() => void>();
  const externalActivationListeners = new Set<() => void>();
  const watchedWorkers = new WeakSet<ServiceWorker>();
  let waiting: ServiceWorker | null = null;
  let applying = false;

  const announce = (worker: ServiceWorker): void => {
    waiting = worker;
    for (const listener of listeners) listener();
  };

  const watchInstalling = (
    worker: ServiceWorker,
    container: ServiceWorkerContainer,
  ): void => {
    if (watchedWorkers.has(worker)) return;
    watchedWorkers.add(worker);
    const announceIfInstalled = (): void => {
      if (worker.state === "installed" && container.controller) announce(worker);
    };
    worker.addEventListener("statechange", announceIfInstalled);
    announceIfInstalled();
  };

  return {
    subscribe: (listener) => {
      listeners.add(listener);
      if (waiting) listener();
      return () => listeners.delete(listener);
    },
    subscribeExternalActivation: (listener) => {
      externalActivationListeners.add(listener);
      return () => externalActivationListeners.delete(listener);
    },
    attach: (registration, container) => {
      let wasControlled = Boolean(container.controller);
      if (registration.waiting && container.controller) announce(registration.waiting);
      if (registration.installing) watchInstalling(registration.installing, container);
      registration.addEventListener("updatefound", () => {
        const installing = registration.installing;
        if (!installing) return;
        watchInstalling(installing, container);
      });
      container.addEventListener("controllerchange", () => {
        const isControlled = Boolean(container.controller);
        if (applying && isControlled) {
          reload();
        } else if (wasControlled && isControlled) {
          for (const listener of externalActivationListeners) listener();
        }
        wasControlled = isControlled;
      });
    },
    apply: () => {
      if (!waiting) return;
      applying = true;
      waiting.postMessage({ type: "SKIP_WAITING" });
    },
  };
};
