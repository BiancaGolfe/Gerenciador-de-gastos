# Controle de Gastos com Comprovantes

Aplicativo Flutter offline para controle de despesas com foto de comprovantes.

## Tecnologias
- **Flutter** 3.x
- **SQFlite** — banco de dados local
- **image_picker** — câmera e galeria
- **fl_chart** — gráfico de pizza
- **intl** — formatação pt_BR

## Como rodar

```bash
flutter pub get
flutter run
```

## Estrutura de pastas

```
lib/
├── main.dart
├── models/
│   └── gasto.dart          # Modelo de dados
├── database/
│   └── database_helper.dart # CRUD com SQFlite
├── screens/
│   ├── home_screen.dart     # Tela inicial + navegação
│   ├── cadastro_screen.dart # Cadastro e edição de gastos
│   ├── historico_screen.dart# Lista com filtro por categoria
│   ├── graficos_screen.dart # Barras + pizza por categoria
│   └── detalhe_screen.dart  # Detalhe, editar e excluir
├── widgets/
│   └── gasto_card.dart      # Card reutilizável de gasto
└── utils/
    ├── categorias.dart      # Ícones e cores por categoria
    └── formatters.dart      # Moeda e data em pt_BR
```

## Permissões necessárias

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>Necessário para fotografar comprovantes</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Necessário para selecionar comprovantes da galeria</string>
```
