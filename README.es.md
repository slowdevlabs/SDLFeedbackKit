# SDLFeedbackKit

[English](README.md) · [한국어](README.ko.md) · [Español](README.es.md)


**Un formulario de comentarios ligero e independiente del backend para SwiftUI en iOS y macOS.**

![Swift](https://img.shields.io/badge/Swift-5.9+-F05138)
![iOS](https://img.shields.io/badge/iOS-13.0+-000000)
![macOS](https://img.shields.io/badge/macOS-10.15+-000000)
![License](https://img.shields.io/badge/License-MIT-4C8BF5)

SDLFeedbackKit proporciona una interfaz reutilizable para comentarios, un modelo de payload, un pipeline para adjuntos de imagen, localización y un contrato de transporte. Tu app controla la presentación, mientras que tu backend se encarga del envío y del almacenamiento.

> [!NOTE]
> SDLFeedbackKit **no** incluye un backend alojado ni un transporte de red integrado.  
> Conéctalo a tu propio backend implementando `FeedbackTransport`.

| | |
|---|---|
| **Plataformas** | iOS 13+ · macOS 10.15+ |
| **Swift** | 5.9+ |
| **Localización** | Inglés · Coreano · Español |
| **Adjuntos** | 1 imagen · salida JPEG · máximo predeterminado de 1,000,000 bytes |
| **Dependencias** | Ninguna |
| **Backend** | Usa tu propia implementación de `FeedbackTransport` |

---

## Funciones principales

- Formulario de comentarios en SwiftUI
- Categorías de comentarios personalizables
- Campo de mensaje y correo electrónico opcional
- Un único adjunto de imagen
- Redimensionado automático, re-encoding JPEG y reducción de metadatos
- Límite predeterminado de `1,000,000` bytes para el adjunto final
- `FeedbackTransport` independiente del backend
- Selectores nativos de adjuntos en iOS y macOS
- Localización en inglés, coreano y español
- Presentación y cierre controlados por la app host
- Sin dependencias externas

---

## Requisitos

- Swift 5.9+
- iOS 13.0+
- macOS 10.15+
- Swift Package Manager

---

## Instalación

Añade SDLFeedbackKit en Xcode usando la siguiente URL del repositorio:

```text
https://github.com/slowdevlabs/SDLFeedbackKit
```

Selecciona la versión `0.1.0` o posterior dentro de la serie `0.1.x`.

Cuando trabajas dentro de este repositorio, las apps de ejemplo usan el checkout local del paquete.

---

## Inicio rápido

```swift
import SDLFeedbackKit
import SwiftUI

struct SettingsView: View {
    @State private var showingFeedback = false

    var body: some View {
        Button("Send Feedback") {
            showingFeedback = true
        }
        .sheet(isPresented: $showingFeedback) {
            FeedbackFormView(
                context: FeedbackContext(
                    appID: "my-app",
                    appName: "My App"
                ),
                transport: MyFeedbackTransport(),
                onSubmitted: { _ in
                    showingFeedback = false
                },
                onCancelled: {
                    showingFeedback = false
                }
            )
        }
    }
}
```

`FeedbackFormView` no se cierra por sí mismo. La app host controla la presentación y decide qué hacer en `onSubmitted` y `onCancelled`.

---

## Transporte personalizado

Implementa `FeedbackTransport` en tu app o módulo de red:

```swift
struct MyFeedbackTransport: FeedbackTransport {
    func submit(
        _ payload: FeedbackPayload
    ) async throws -> FeedbackSubmissionReceipt {
        // Envía el payload a tu propio backend.

        return FeedbackSubmissionReceipt(
            serverID: "feedback-123",
            acceptedAt: Date()
        )
    }
}
```

> [!IMPORTANT]
> Trata los payloads de comentarios como entrada no confiable. Tu backend debe validar las solicitudes, aplicar límites de uso y definir sus propias políticas de almacenamiento y retención.

Las apps de ejemplo incluidas usan un mock transport. Los comentarios enviados desde los ejemplos **no se guardan en un backend real**.

---

## Configuración

`FeedbackConfiguration` permite configurar:

- categorías
- ajustes del campo de correo electrónico
- ajustes de adjuntos
- ajustes del mensaje
- visibilidad del botón Cancelar

### Política predeterminada de adjuntos

| Ajuste | Valor predeterminado |
|---|---:|
| Tamaño final optimizado | `1,000,000` bytes |
| Lado largo | `1,800` px |
| Calidad JPEG inicial | `0.8` |

---

## Adjuntos

SDLFeedbackKit acepta un único adjunto de imagen y lo normaliza antes del envío.

Pipeline del adjunto:

```text
Imagen seleccionada
    ↓
Decodificación / reducción
    ↓
Corrección de orientación
    ↓
Re-encoding JPEG
    ↓
Reducción de metadatos
    ↓
FeedbackAttachment
    ↓
FeedbackTransport
```

El adjunto final:

- usa formato JPEG
- está limitado de forma predeterminada a `1,000,000` bytes
- incluye las dimensiones finales y el byteCount
- usa el nombre normalizado `feedback.jpg`
- no expone la ruta original del archivo mediante `FeedbackAttachment`

Los formatos de entrada compatibles dependen del soporte de decodificación de la plataforma Apple. JPEG y PNG son los casos más comunes; HEIC/HEIF depende del sistema operativo del host.

---

## Localización

SDLFeedbackKit incluye recursos `.strings` para:

- Inglés
- Coreano
- Español

El idioma base es inglés y la localización del paquete se carga mediante `Bundle.module`.

Los nombres de las categorías integradas son localizados por SDLFeedbackKit.

> [!TIP]
> Los nombres de categorías personalizadas los proporciona la app host, por lo que la app es responsable de localizarlos cuando sea necesario.

---

## Privacidad y seguridad

SDLFeedbackKit está diseñado para que la app host controle las decisiones relacionadas con el backend y la privacidad.

- No incluye un backend alojado
- El paquete no recopila identificadores persistentes del dispositivo
- El paquete no recopila ubicación precisa
- Solo procesa la imagen seleccionada por el usuario
- Las imágenes seleccionadas se vuelven a codificar para reducir metadatos y tamaño
- Los secretos del backend no deben incluirse en el binario de la app
- La validación del servidor y la prevención de abusos son responsabilidad del backend

---

## Ejemplos

El repositorio incluye apps host de ejemplo para ambas plataformas compatibles:

```text
Examples/
├── iOSExample/
└── macOSExample/
```

Los ejemplos muestran:

- cómo presentar `FeedbackFormView`
- cómo cerrar la presentación desde la app host
- cómo implementar `FeedbackTransport`
- flujos de éxito y error
- manejo de adjuntos de imagen

Los ejemplos usan intencionadamente un mock transport en lugar de un backend de producción.

---

## Lo que SDLFeedbackKit no incluye

SDLFeedbackKit mantiene deliberadamente un alcance reducido.

- Sin backend integrado
- Sin implementación integrada de transporte de red
- Sin múltiples adjuntos
- Sin captura de cámara
- Sin pipeline de adjuntos mediante arrastrar y soltar
- Sin soporte de adjuntos desde el portapapeles
- Sin sistema de temas personalizado

---

## Estado

**Early release — 0.1.x**

El paquete está listo para integrarse en apps reales, pero la API pública puede seguir evolucionando durante la serie `0.x`.

---

## Licencia

SDLFeedbackKit está disponible bajo la licencia MIT. Consulta [LICENSE](LICENSE) para más información.
