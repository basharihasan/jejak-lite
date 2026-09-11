// Menangani Web Push masuk. Payload dikirim NotificationDeliveryJob sebagai
// JSON polos { title, body } (bukan { title, options } gaya contoh Rails),
// jadi di-mapping manual ke shape yang dipakai showNotification.
self.addEventListener("push", (event) => {
  const data = event.data ? event.data.json() : {};

  event.waitUntil(
    self.registration.showNotification(data.title || "Jejak Lite", {
      body: data.body || "",
      icon: "/icon.png",
      badge: "/icon.png"
    })
  );
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: "window" }).then((clientList) => {
      for (const client of clientList) {
        if ("focus" in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow("/notifications");
    })
  );
});
