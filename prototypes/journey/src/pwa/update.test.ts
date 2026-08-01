import { describe, expect, it, vi } from "vitest";
import { createServiceWorkerUpdateController } from "./update";

class WorkerDouble extends EventTarget {
  state: ServiceWorkerState = "installing";
  readonly postMessage = vi.fn();
}

class RegistrationDouble extends EventTarget {
  waiting: WorkerDouble | null = null;
  installing: WorkerDouble | null = null;
}

class ContainerDouble extends EventTarget {
  controller: WorkerDouble | null = null;
}

describe("service worker updates", () => {
  it("announces an existing waiting build and applies it only on request", () => {
    const reload = vi.fn();
    const controller = createServiceWorkerUpdateController(reload);
    const registration = new RegistrationDouble();
    const container = new ContainerDouble();
    const worker = new WorkerDouble();
    registration.waiting = worker;
    container.controller = new WorkerDouble();
    const listener = vi.fn();
    controller.subscribe(listener);

    controller.attach(
      registration as unknown as ServiceWorkerRegistration,
      container as unknown as ServiceWorkerContainer,
    );
    expect(listener).toHaveBeenCalledOnce();
    expect(reload).not.toHaveBeenCalled();

    controller.apply();
    expect(worker.postMessage).toHaveBeenCalledWith({ type: "SKIP_WAITING" });
    container.dispatchEvent(new Event("controllerchange"));
    expect(reload).toHaveBeenCalledOnce();
  });

  it("ignores first installation and announces a later installed worker", () => {
    const reload = vi.fn();
    const controller = createServiceWorkerUpdateController(reload);
    const registration = new RegistrationDouble();
    const container = new ContainerDouble();
    const firstInstall = new WorkerDouble();
    const listener = vi.fn();
    const externalActivation = vi.fn();
    const unsubscribe = controller.subscribe(listener);
    controller.subscribeExternalActivation(externalActivation);
    controller.apply();
    controller.attach(
      registration as unknown as ServiceWorkerRegistration,
      container as unknown as ServiceWorkerContainer,
    );
    container.controller = firstInstall;
    container.dispatchEvent(new Event("controllerchange"));
    expect(reload).not.toHaveBeenCalled();
    expect(externalActivation).not.toHaveBeenCalled();

    container.controller = new WorkerDouble();
    container.dispatchEvent(new Event("controllerchange"));
    expect(externalActivation).toHaveBeenCalledOnce();

    container.controller = null;
    container.dispatchEvent(new Event("controllerchange"));
    expect(externalActivation).toHaveBeenCalledOnce();

    registration.dispatchEvent(new Event("updatefound"));
    expect(listener).not.toHaveBeenCalled();

    registration.installing = firstInstall;
    registration.dispatchEvent(new Event("updatefound"));
    firstInstall.state = "installed";
    firstInstall.dispatchEvent(new Event("statechange"));
    expect(listener).not.toHaveBeenCalled();

    const update = new WorkerDouble();
    registration.installing = update;
    container.controller = firstInstall;
    registration.dispatchEvent(new Event("updatefound"));
    update.state = "activated";
    update.dispatchEvent(new Event("statechange"));
    expect(listener).not.toHaveBeenCalled();
    update.state = "installed";
    update.dispatchEvent(new Event("statechange"));
    expect(listener).toHaveBeenCalledOnce();

    unsubscribe();
    const lateListener = vi.fn();
    controller.subscribe(lateListener);
    expect(lateListener).toHaveBeenCalledOnce();
  });

  it("observes an installation already in progress without double-watching it", () => {
    const controller = createServiceWorkerUpdateController(vi.fn());
    const registration = new RegistrationDouble();
    const container = new ContainerDouble();
    const installing = new WorkerDouble();
    registration.installing = installing;
    container.controller = new WorkerDouble();
    const listener = vi.fn();
    controller.subscribe(listener);

    controller.attach(
      registration as unknown as ServiceWorkerRegistration,
      container as unknown as ServiceWorkerContainer,
    );
    registration.dispatchEvent(new Event("updatefound"));
    installing.state = "installed";
    installing.dispatchEvent(new Event("statechange"));

    expect(listener).toHaveBeenCalledOnce();
  });

  it("notifies an already-controlled tab when another tab activates an update", () => {
    const reload = vi.fn();
    const controller = createServiceWorkerUpdateController(reload);
    const registration = new RegistrationDouble();
    const container = new ContainerDouble();
    container.controller = new WorkerDouble();
    const externalActivation = vi.fn();
    const unsubscribe = controller.subscribeExternalActivation(externalActivation);

    controller.attach(
      registration as unknown as ServiceWorkerRegistration,
      container as unknown as ServiceWorkerContainer,
    );
    container.dispatchEvent(new Event("controllerchange"));
    expect(externalActivation).toHaveBeenCalledOnce();
    expect(reload).not.toHaveBeenCalled();

    unsubscribe();
    container.dispatchEvent(new Event("controllerchange"));
    expect(externalActivation).toHaveBeenCalledOnce();
  });
});
