# Guia — Rodar no Android Studio e gerar APKs

App: **Iluminação Pública Inteligente** (`smartcity_app`)
`applicationId`: `br.gov.itaguari.smartcity_app`
Flutter 3.47 · Dart 3.13 · `minSdk` 24 (Android 7.0) · `targetSdk`/`compileSdk` 35

---

## 1. Pré-requisitos

| Ferramenta | Observação |
|---|---|
| **Flutter SDK** | Já instalado em `~/flutter`. Confira com `flutter doctor`. |
| **Android Studio** | Use a versão mais recente. Ele traz o Android SDK, o `adb` e o emulador. |
| **Android SDK Platform 35 + Build-Tools** | Instalados automaticamente no primeiro build (você já aceitou as licenças ao gerar o APK). Se faltar: `flutter doctor --android-licenses`. |
| **JDK 17** | O projeto compila em Java 17. O Android Studio recente já embute um JDK 17 — não precisa instalar à parte. |
| **Plugins do Android Studio** | `Flutter` e `Dart` (Settings → Plugins → Marketplace). Instalar o Flutter puxa o Dart junto. |

Rode uma vez e resolva o que aparecer:

```bash
flutter doctor -v
```

---

## 2. Abrir o projeto

1. **Android Studio → Open** → selecione a pasta **`smartcity-app`** (a raiz, onde está o `pubspec.yaml`).
   - Não abra a subpasta `android/` — isso abre só o módulo Gradle, sem o suporte Flutter.
2. Aguarde o *Dart Analysis* e o *Gradle sync* terminarem (barra de status embaixo).
3. Se pedir, clique em **"Pub get"** (ou rode `flutter pub get` no terminal embutido).

### `android/local.properties`

Já existe e aponta para o SDK do Flutter e do Android. É um arquivo **local, não versionado**. Se algum dia sumir, recrie com:

```properties
flutter.sdk=/home/samuel/flutter
sdk.dir=/home/samuel/Android/Sdk
```

---

## 3. Rodar o app (debug)

### 3.1. Escolher o dispositivo

No canto superior direito do Android Studio há um seletor de dispositivos:

- **Emulador**: `Device Manager` → `Create Device` → escolha um Pixel, imagem de sistema API 34/35, finalize e dê play. Referência de tela do projeto: **412×892** (Pixel 6/7 servem bem).
- **Celular físico**: ative **Opções do desenvolvedor → Depuração USB**, conecte por cabo, autorize o computador no popup do celular. Ele aparece no seletor.

### 3.2. Backend precisa estar no ar

O app consome o servidor `http://localhost:3000`: REST em `/api/v1` (ex.: `/api/v1/postes`) e WebSocket (Socket.IO) em `/tempo-real`, na raiz. Suba o `smartcity-backend` antes.

O endereço do servidor é configurável por `--dart-define=API_BASE_URL=...`. Informe **só o servidor** (sem `/api/v1`); o app acrescenta a versão da API sozinho:

| Onde o app roda | `API_BASE_URL` |
|---|---|
| Emulador Android | `http://10.0.2.2:3000` (o `10.0.2.2` é o "localhost" da sua máquina visto de dentro do emulador) |
| Celular físico (mesma rede Wi-Fi) | `http://SEU_IP_LOCAL:3000` (ex.: `http://192.168.0.10:3000`) |
| Chrome / Linux desktop | `http://localhost:3000` (padrão, pode omitir) |

> Sem backend, o app abre normalmente: as telas mostram carregando/erro e o selo fica **OFFLINE**.
> O tráfego HTTP em claro (sem HTTPS) já está liberado no `AndroidManifest.xml` (`usesCleartextTraffic="true"`), então não precisa mexer nisso para o mock.

### 3.3. Passar o `--dart-define` no Android Studio

**Run → Edit Configurations… → (sua config `main.dart`) → "Additional run args":**

```
--dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Salve e clique em **Run ▶** (ou `Shift+F10`). `Debug 🐞` para depurar com breakpoints.

Equivalente no terminal:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

### 3.4. Durante o desenvolvimento

- **Hot reload**: `Ctrl+\` (ou o ícone do raio) — aplica mudanças de UI sem reiniciar.
- **Hot restart**: `Ctrl+Shift+\` — reinicia o app mantendo a sessão de debug.
- **Flutter DevTools**: abre pelo botão na aba *Run* — inspetor de widgets, performance, network.

---

## 4. Conceitos antes de gerar o build

### 4.1. Build types

| Tipo | Para quê | Como |
|---|---|---|
| **debug** | desenvolvimento, hot reload | `flutter run` |
| **profile** | medir performance (sem overhead de debug) | `flutter run --profile` |
| **release** | entrega / apresentação — otimizado, minificado | `flutter build ...` |

### 4.2. APK × AAB

- **APK** (`.apk`) — instala direto no celular (`adb install`, ou copiar o arquivo). **É o que você quer para a apresentação.**
- **AAB** (`.aab`, *Android App Bundle*) — formato que a Google Play exige. **Não** instala direto no celular. Só use se for publicar na Play Store.

### 4.3. Assinatura (importante)

Todo APK Android é assinado. Hoje o projeto está no padrão do Flutter:

```kotlin
// android/app/build.gradle.kts
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")   // <-- assina com a chave de debug
    }
}
```

Ou seja, `flutter build apk --release` **funciona e gera um APK instalável**, assinado com a *chave de debug*. Para a atividade acadêmica isso basta.

O que a chave de debug **não** permite:
- publicar na Play Store;
- atualizar por cima de uma versão instalada que foi assinada com outra chave ("App not installed / signatures do not match" → desinstale a anterior antes).

Se quiser uma chave própria (recomendado se for distribuir o APK), veja a **seção 7**.

### 4.4. Versão

Sai do `pubspec.yaml`:

```yaml
version: 1.0.0+1
#        ^^^^^ ^
#        |     +-- versionCode (inteiro, precisa subir a cada release publicado)
#        +-------- versionName (o que o usuário vê: "1.0.0")
```

---

## 5. Gerar o APK — pelo terminal (jeito mais direto)

Na raiz do projeto:

```bash
# APK único (universal, roda em qualquer celular) — mais simples p/ compartilhar
flutter build apk --release

# opcional: passar a URL da API embutida no build
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.0.10:3000
```

**Onde o arquivo vai:**

```
build/app/outputs/flutter-apk/app-release.apk
```

(caminho relativo à raiz `smartcity-app/`). Esse é o arquivo que você envia / instala.

### APK menor, separado por arquitetura

O APK universal fica grande (~55 MB) porque empacota o código nativo de todas as CPUs. Para reduzir:

```bash
flutter build apk --release --split-per-abi
```

Gera 3 arquivos em `build/app/outputs/flutter-apk/`:

| Arquivo | CPU | Cobre |
|---|---|---|
| `app-arm64-v8a-release.apk` | ARM 64-bit | **quase todo celular moderno** — mande esse |
| `app-armeabi-v7a-release.apk` | ARM 32-bit | aparelhos antigos |
| `app-x86_64-release.apk` | x86 64-bit | emuladores |

Cada um fica em torno de 20–25 MB.

### Outras opções úteis

```bash
flutter build apk --debug        # APK de debug (grande, sem otimização)
flutter build apk --profile      # APK de profile
flutter build apk --release --no-tree-shake-icons   # se algum ícone sumir no release
flutter build apk --analyze-size # relatório do que está ocupando espaço
```

---

## 6. Gerar o APK — pelo Android Studio

### 6.1. Build rápido (assinatura atual = debug key)

**Menu Build → Flutter → Build APK**

- Roda `flutter build apk --release`.
- Ao terminar aparece um balão "APK(s) generated successfully" com link **`locate`** que abre a pasta `build/app/outputs/flutter-apk/`.
- Para passar `--dart-define` aqui, deixe configurado em *Edit Configurations* (seção 3.3) — o Android Studio reaproveita.

### 6.2. Build assinado com chave própria

**Menu Build → Generate Signed Bundle / APK…**

1. Escolha **APK** → *Next*.
2. **Key store path**: *Create new…* (ou selecione um `.jks` existente).
   - Preencha caminho, senha do keystore, *alias*, senha da chave, validade (25+ anos), seu nome/organização.
3. *Next* → marque **release** → *Create*.
4. Saída (com a caixa "Generate Signed APK" do AS): normalmente
   `android/app/release/app-release.apk` (o próprio diálogo mostra o caminho e um link).

> Esse fluxo do Android Studio usa o Gradle direto. Para que **`flutter build apk`** também passe a assinar com essa chave, você precisa fazer a configuração da seção 7 (o `key.properties` + edição do `build.gradle.kts`).

---

## 7. Configurar uma chave de assinatura própria (opcional)

Faça isso se for distribuir o APK para outras pessoas ou publicar.

### 7.1. Criar o keystore

```bash
keytool -genkey -v -keystore ~/chaves/smartcity-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Guarde a senha e o arquivo `.jks` **em local seguro** — perdeu, não atualiza mais o app publicado.

### 7.2. `android/key.properties`

Crie o arquivo (fora do controle de versão):

```properties
storePassword=SUA_SENHA_DO_KEYSTORE
keyPassword=SUA_SENHA_DA_CHAVE
keyAlias=upload
storeFile=/home/samuel/chaves/smartcity-upload.jks
```

Adicione ao `.gitignore` (o do Flutter já ignora, confirme):

```
android/key.properties
**/*.jks
```

### 7.3. Editar `android/app/build.gradle.kts`

```kotlin
import java.util.Properties
import java.io.FileInputStream

// ... plugins { } ...

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ...
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")   // troca a debug pela release
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}
```

Depois, `flutter build apk --release` já sai assinado com a sua chave.

---

## 8. Instalar o APK no celular

**Por cabo (adb):**

```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# -r = reinstala por cima; se der erro de assinatura, use -r -d ou desinstale antes:
adb uninstall br.gov.itaguari.smartcity_app
```

**Sem cabo:** copie o `.apk` para o celular (WhatsApp, Drive, cabo, `adb push`), abra o arquivo pelo gerenciador de arquivos e autorize **"instalar apps de fontes desconhecidas"** para aquele app.

---

## 9. AAB para Google Play (só se for publicar)

```bash
flutter build appbundle --release
# saída: build/app/outputs/bundle/release/app-release.aab
```

Sobe esse `.aab` no Play Console. A Play gera e assina os APKs finais por dispositivo (Play App Signing).

---

## 10. Problemas comuns

| Sintoma | Causa / solução |
|---|---|
| `flutter.sdk not set in local.properties` | Recrie `android/local.properties` (seção 2). |
| `Android SDK Platform 35 ... licenses not accepted` | `flutter doctor --android-licenses` e aceite tudo. |
| Build trava baixando Gradle na primeira vez | Normal — o wrapper baixa o Gradle 9.3.1. Deixe terminar (tem internet). |
| `NDK not configured` / versão do NDK | Android Studio → SDK Manager → SDK Tools → instale o **NDK (Side by side)** na versão que o erro pedir. |
| App abre mas fica tudo "OFFLINE" / erro | Backend não está no ar **ou** `API_BASE_URL` errada (no emulador tem que ser `10.0.2.2`, não `localhost`). |
| `Cleartext HTTP traffic not permitted` | Já está liberado no manifesto; se editou o manifesto, restaure `android:usesCleartextTraffic="true"`. |
| `App not installed` ao instalar por cima | Assinatura diferente da versão já instalada. `adb uninstall br.gov.itaguari.smartcity_app` e instale de novo. |
| Ícones somem no release | `flutter build apk --release --no-tree-shake-icons`. |
| APK muito grande | Use `--split-per-abi` e mande o `arm64-v8a`. |
| Erro de Java/`jvmTarget` | O projeto exige JDK 17. Android Studio → Settings → Build Tools → Gradle → *Gradle JDK* = 17 (ou o "Embedded JDK"). |

---

## 11. Checklist para a apresentação

```bash
# 1. verificação
flutter analyze
flutter test

# 2. backend no ar (porta 3000)

# 3. build do APK para o celular da apresentação
flutter build apk --release --split-per-abi \
  --dart-define=API_BASE_URL=http://SEU_IP:3000

# 4. arquivo em:
#    build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# 5. instalar
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```
